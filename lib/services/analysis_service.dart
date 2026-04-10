import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:metadata_audio/metadata_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'config_service.dart';

class AnalysisService {
  static final Map<String, String> _resolvedTrackPathCache = {};
  static final Set<String> _missingTrackPathCache = {};
  static Future<void>? _pathCacheLoadFuture;
  static File? _pathCacheFile;
  static bool? _ffmpegAvailable;
  final Map<String, Map<String, dynamic>> _backupTrackMetadataByPath = {};
  final Map<String, Map<String, dynamic>> _backupTrackMetadataByBase = {};
  final Map<String, Map<String, dynamic>> _backupTrackStatsByPath = {};
  final Map<String, Map<String, dynamic>> _backupTrackStatsByBase = {};
  final Map<String, String> _albumCovers = {};
  final Map<String, String> _trackCovers = {};
  late final String? _musicDirectory;
  late final String _coversDir;

  AnalysisService() {
    _musicDirectory = ConfigService().get('music_directory');
    _coversDir = p.join(Directory.systemTemp.path, 'namida_covers');
    Directory(_coversDir).createSync(recursive: true);
  }

  /// Internal constructor for isolate workers (no dir creation needed).
  AnalysisService._worker(
    String coversDir,
    Map<String, Map<String, dynamic>> backupTrackMetaByPath,
    Map<String, Map<String, dynamic>> backupTrackStatsByPath,
    Map<String, String> albumCovers,
    Map<String, String> trackCovers,
    String? musicDirectory,
  ) {
    _musicDirectory = musicDirectory;
    _coversDir = coversDir;
    _backupTrackMetadataByPath.addAll(backupTrackMetaByPath);
    _backupTrackStatsByPath.addAll(backupTrackStatsByPath);
    for (final entry in _backupTrackMetadataByPath.entries) {
      final base = p.basenameWithoutExtension(entry.key).toLowerCase();
      _backupTrackMetadataByBase.putIfAbsent(base, () => entry.value);
    }
    for (final entry in _backupTrackStatsByPath.entries) {
      final base = p.basenameWithoutExtension(entry.key).toLowerCase();
      _backupTrackStatsByBase.putIfAbsent(base, () => entry.value);
    }
    _albumCovers.addAll(albumCovers);
    _trackCovers.addAll(trackCovers);
  }

  /// Main entry point — replaces run_analysis.py
  Future<Map<String, dynamic>> analyze(
    List<String> zipPaths,
    String? musicDir, {
    void Function(String)? onProgress,
  }) async {
    final tempDir = p.join(Directory.systemTemp.path, 'namida_history_temp');
    final mergedDir = p.join(tempDir, 'TEMPDIR_History_merged');

    // Clean previous run
    final tempDirObj = Directory(tempDir);
    if (tempDirObj.existsSync()) {
      tempDirObj.deleteSync(recursive: true);
    }
    Directory(mergedDir).createSync(recursive: true);

    // Phase 1: Extract ZIPs + read backup DB metadata
    onProgress?.call('extracting:${zipPaths.length}');
    final extractResult = await Isolate.run(() {
      return _extractAndMerge(zipPaths, tempDir, mergedDir);
    });
    final extractCount = extractResult['extractCount'] as int? ?? 0;
    if (extractCount == 0) {
      return {'success': false, 'error': '提取历史文件夹失败，请检查ZIP格式或路径'};
    }
    final backupTrackMetaByPath = Map<String, Map<String, dynamic>>.from(
      (extractResult['backupTrackMetaByPath'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
      ),
    );
    final backupTrackStatsByPath = Map<String, Map<String, dynamic>>.from(
      (extractResult['backupTrackStatsByPath'] as Map? ?? {}).map(
        (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
      ),
    );

    final coversDir = _coversDir;
    // Phase 2: Load, enrich, and analyze
    onProgress?.call('analyzing');
    final result = await Isolate.run(() {
      final worker = AnalysisService._worker(
        coversDir,
        backupTrackMetaByPath,
        backupTrackStatsByPath,
        {},
        {},
        musicDir,
      );
      final records = worker._loadRecords(mergedDir);
      worker._enrichRecords(records);
      final summaries = worker._getAllSummaries(records);
      return {'success': true, 'summaries': summaries};
    });

    // Phase 3: Cleanup
    onProgress?.call('cleanup');
    try {
      Directory(tempDir).deleteSync(recursive: true);
    } catch (_) {}

    return result;
  }

  /// Runs in background isolate: extract ZIPs and merge JSON files.
  static Map<String, dynamic> _extractAndMerge(
      List<String> zipPaths, String tempDir, String mergedDir) {
    int successCount = 0;
    final backupTrackMetaByPath = <String, Map<String, dynamic>>{};
    final backupTrackStatsByPath = <String, Map<String, dynamic>>{};
    for (int i = 0; i < zipPaths.length; i++) {
      final extractToPath = p.join(tempDir, 'zip_$i');
      final extracted =
          _extractHistoryFolderSync(zipPaths[i], p.join(tempDir, 'zip_$i'));
      final historyDir = extracted?['historyDir'];
      final localFilesDir = extracted?['localFilesDir'];

      if (historyDir != null && Directory(historyDir).existsSync()) {
        final dbSearchDirs = <String>[];
        if (localFilesDir != null && Directory(localFilesDir).existsSync()) {
          dbSearchDirs.add(localFilesDir);
        }
        // Fallback: some backups may place DBs elsewhere.
        dbSearchDirs.add(historyDir);

        final dbData = _readBackupDatabases(dbSearchDirs);
        backupTrackMetaByPath.addAll(dbData['trackMetaByPath'] as Map<String, Map<String, dynamic>>);
        backupTrackStatsByPath.addAll(dbData['trackStatsByPath'] as Map<String, Map<String, dynamic>>);
        _mergeJsonFiles(historyDir, mergedDir);
        successCount++;
        try {
          Directory(extractToPath).deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    return {
      'extractCount': successCount,
      'backupTrackMetaByPath': backupTrackMetaByPath,
      'backupTrackStatsByPath': backupTrackStatsByPath,
    };
  }

  static Map<String, Map<String, dynamic>> _readBackupDatabases(List<String> searchDirs) {
    final trackMetaByPath = <String, Map<String, dynamic>>{};
    final trackStatsByPath = <String, Map<String, dynamic>>{};

    for (final dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        final fileName = p.basename(entity.path).toLowerCase();
        if (fileName != 'tracks.db' && fileName != 'tracks_stats.db') continue;

        final kvRows = _readJsonKeyValueRowsFromSqlite(entity.path);
        if (kvRows.isEmpty) continue;

        if (fileName == 'tracks.db') {
          for (final entry in kvRows.entries) {
            final normPath = _normalizeTrackPath(entry.key);
            final val = entry.value;
            if (normPath.isEmpty || val is! Map<String, dynamic>) continue;
            trackMetaByPath[normPath] = val;
          }
        } else {
          for (final entry in kvRows.entries) {
            final normPath = _normalizeTrackPath(entry.key);
            final val = entry.value;
            if (normPath.isEmpty || val is! Map<String, dynamic>) continue;
            trackStatsByPath[normPath] = val;
          }
        }
      }
    }

    return {
      'trackMetaByPath': trackMetaByPath,
      'trackStatsByPath': trackStatsByPath,
    };
  }

  static Map<String, dynamic> _readJsonKeyValueRowsFromSqlite(String dbPath) {
    final result = <String, dynamic>{};
    sqlite.Database? db;
    try {
      db = sqlite.sqlite3.open(dbPath, mode: sqlite.OpenMode.readOnly);
      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      for (final tableRow in tables) {
        final tableName = tableRow['name']?.toString();
        if (tableName == null || tableName.isEmpty) continue;

        final escapedTable = _escapeSqlIdentifier(tableName);
        final cols = db.select('PRAGMA table_info("$escapedTable")');
        if (cols.isEmpty) continue;

        final colNames = cols
            .map((c) => c['name']?.toString())
            .whereType<String>()
            .toList();
        if (colNames.length < 2) continue;

        final keyCol = _pickLikelyColumn(colNames, const ['key', 'path']) ?? colNames.first;
        final valCol = _pickLikelyColumn(colNames, const ['value', 'json', 'data']) ?? colNames[1];

        final escapedKeyCol = _escapeSqlIdentifier(keyCol);
        final escapedValCol = _escapeSqlIdentifier(valCol);
        final rows = db.select(
          'SELECT "$escapedKeyCol" AS k, "$escapedValCol" AS v FROM "$escapedTable"',
        );

        for (final row in rows) {
          final key = row['k']?.toString();
          if (key == null || key.isEmpty) continue;
          final decoded = _decodeJsonPayload(row['v']);
          if (decoded != null) {
            result[key] = decoded;
          }
        }
      }
    } catch (_) {
      return {};
    } finally {
      try {
        db?.dispose();
      } catch (_) {}
    }
    return result;
  }

  static dynamic _decodeJsonPayload(Object? raw) {
    if (raw == null) return null;
    if (raw is Map || raw is List) return raw;

    String? text;
    if (raw is String) {
      text = raw;
    } else if (raw is Uint8List) {
      text = utf8.decode(raw, allowMalformed: true);
    } else if (raw is List<int>) {
      text = utf8.decode(raw, allowMalformed: true);
    }
    if (text == null || text.trim().isEmpty) return null;

    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static String? _pickLikelyColumn(List<String> cols, List<String> hints) {
    for (final c in cols) {
      final lower = c.toLowerCase();
      if (hints.any(lower.contains)) return c;
    }
    return null;
  }

  static String _escapeSqlIdentifier(String ident) => ident.replaceAll('"', '""');

  static String _normalizeTrackPath(String path) =>
      path.replaceAll('\\', '/').trim().toLowerCase();

  // ---------------------------------------------------------------------------
  // ZIP extraction (replaces extractor.py)
  // ---------------------------------------------------------------------------

  static Map<String, String>? _extractHistoryFolderSync(
      String backupZipPath, String extractToPath) {
    final zipFile = File(backupZipPath);
    if (!zipFile.existsSync()) return null;

    try {
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find nested archives in backup root
      ArchiveFile? historyZipEntry;
      ArchiveFile? localFilesZipEntry;
      for (final file in archive) {
        if (!file.isFile) continue;
        final baseName = p.basename(file.name).toLowerCase();
        if (baseName == 'tempdir_history.zip') {
          historyZipEntry = file;
          continue;
        }
        if (baseName == 'local_files.zip') {
          localFilesZipEntry = file;
        }
      }
      if (historyZipEntry == null) return null;

      // Decode the inner ZIP
      final historyArchive =
          ZipDecoder().decodeBytes(historyZipEntry.content as List<int>);
      final historyDir = p.join(extractToPath, 'TEMPDIR_History');
      Directory(historyDir).createSync(recursive: true);

      for (final file in historyArchive) {
        if (file.isFile) {
          final outFile = File(p.join(historyDir, file.name));
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        }
      }

      String? localFilesDir;
      if (localFilesZipEntry != null) {
        final localArchive =
            ZipDecoder().decodeBytes(localFilesZipEntry.content as List<int>);
        localFilesDir = p.join(extractToPath, 'LOCAL_FILES');
        Directory(localFilesDir).createSync(recursive: true);

        for (final file in localArchive) {
          if (file.isFile) {
            final outFile = File(p.join(localFilesDir, file.name));
            outFile.parent.createSync(recursive: true);
            outFile.writeAsBytesSync(file.content as List<int>);
          }
        }
      }

      return {
        'historyDir': historyDir,
        if (localFilesDir != null) 'localFilesDir': localFilesDir,
      };
    } catch (_) {
      return null;
    }
  }

  static void _mergeJsonFiles(String sourceDir, String mergedDir) {
    for (final entity in Directory(sourceDir).listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final fname = p.basename(entity.path);
      final dstFile = File(p.join(mergedDir, fname));
      try {
        var content = entity.readAsStringSync();
        if (content.startsWith('\uFEFF')) content = content.substring(1);
        final newRecords = jsonDecode(content);
        if (newRecords is! List) continue;

        if (dstFile.existsSync()) {
          var existing = jsonDecode(dstFile.readAsStringSync());
          if (existing is List) {
            existing.addAll(newRecords);
            dstFile.writeAsStringSync(jsonEncode(existing));
          }
        } else {
          dstFile.writeAsStringSync(jsonEncode(newRecords));
        }
      } catch (_) {}
    }
  }

  void _saveCover(List<int> imageData, String baseName, String? album) {
    final ext = (imageData.length >= 8 &&
            imageData[0] == 0x89 &&
            imageData[1] == 0x50 &&
            imageData[2] == 0x4E &&
            imageData[3] == 0x47)
        ? '.png'
        : '.jpg';

    // Per-album cover
    if (album != null &&
        album.isNotEmpty &&
        album != 'Unknown Album' &&
        !_albumCovers.containsKey(album)) {
      final safeName = _sanitizeFilename(album);
      final coverPath = p.join(_coversDir, 'album_$safeName$ext');
      try {
        File(coverPath).writeAsBytesSync(imageData);
        _albumCovers[album] = coverPath;
      } catch (_) {}
    }

    // Per-track cover
    if (album != null && _albumCovers.containsKey(album)) {
      _trackCovers[baseName] = _albumCovers[album]!;
    } else {
      final safeName = _sanitizeFilename(baseName);
      final coverPath = p.join(_coversDir, 'track_$safeName$ext');
      try {
        File(coverPath).writeAsBytesSync(imageData);
        _trackCovers[baseName] = coverPath;
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // JSON loading & enrichment (replaces parser.py load_all_history)
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _loadRecords(String historyDir) {
    final records = <Map<String, dynamic>>[];
    final dir = Directory(historyDir);
    if (!dir.existsSync()) return records;

    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        var content = entity.readAsStringSync();
        if (content.startsWith('\uFEFF')) content = content.substring(1);
        final data = jsonDecode(content);
        if (data is List) {
          for (final item in data) {
            if (item is Map<String, dynamic>) {
              records.add(item);
            }
          }
        }
      } catch (_) {}
    }
    return records;
  }

  void _enrichRecords(List<Map<String, dynamic>> records) {
    // Deduplicate by (track_basename, dateAdded)
    final seen = <String>{};
    records.retainWhere((r) {
      final trackBasename = p.basename(r['track']?.toString() ?? '');
      final dateAdded = r['dateAdded']?.toString() ?? '';
      return seen.add('$trackBasename|$dateAdded');
    });

    if (records.isEmpty) return;

    // Determine timestamp unit (ms vs s)
    final sampleVal =
        records.where((r) => r['dateAdded'] != null).firstOrNull?['dateAdded'];
    final bool isMs = sampleVal is num && sampleVal > 1e11;

    for (final r in records) {
      final track = r['track']?.toString() ?? '';
      final trackName = p.basename(track);
      final trackBase = p.basenameWithoutExtension(trackName).toLowerCase();
      final trackPathNorm = _normalizeTrackPath(track);
      r['track_name'] = trackName;
      r['track_base'] = trackBase;

        // Prefer metadata from backup DB and only do lightweight path remapping
        // during analysis. Actual file lookup stays on-demand in UI flows.
      final backupMeta = _backupTrackMetadataByPath[trackPathNorm] ??
          _backupTrackMetadataByBase[trackBase];
        final sourcePath = _firstNonEmpty([
          backupMeta?['path'],
          track,
          ]) ??
          track;
        final meta = _buildMergedTrackMeta(sourcePath, backupMeta);

      r['artist'] = _metaStr(meta, 'artist', 'Unknown Artist');
      r['album'] = _metaStr(meta, 'album', 'Unknown Album');
      r['title'] = _metaStr(meta, 'title', '') .isEmpty
          ? trackName
          : _metaStr(meta, 'title', trackName);
      r['duration'] = (meta['duration'] is num)
          ? (meta['duration'] as num).toDouble()
          : 0.0;
      r['genre'] = _metaStr(meta, 'genre', 'Unknown Genre');
        r['sourcePath'] = sourcePath;
        r['localPath'] = meta['localPath']?.toString() ?? '';

      // Attach track stats (rating/moods/tags) from backup DB if available.
      final stats = _backupTrackStatsByPath[trackPathNorm] ??
          _backupTrackStatsByBase[trackBase];
      r['rating'] = _asInt(stats?['rating']) ?? 0;
      r['tags'] = _asStringList(stats?['tags']);
      r['moods'] = _asStringList(stats?['moods']);

      // Parse datetime → CST (UTC+8)
      final dateAdded = r['dateAdded'];
      if (dateAdded is num) {
        final ms = isMs ? dateAdded.toInt() : (dateAdded * 1000).toInt();
        final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
            .add(const Duration(hours: 8));
        r['datetime'] = dt;
        r['date_only'] =
            '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)}';
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Summary generation (replaces parser.py get_summary / get_all_summaries)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _getAllSummaries(List<Map<String, dynamic>> records) {
    final summaries = <String, dynamic>{};
    summaries['所有时间'] = _getSummary(records);

    // Per-year
    final byYear = <String, List<Map<String, dynamic>>>{};
    for (final r in records) {
      final dt = r['datetime'];
      if (dt is DateTime) {
        final key = '${dt.year}年';
        byYear.putIfAbsent(key, () => []).add(r);
      }
    }
    for (final entry in byYear.entries) {
      summaries[entry.key] = _getSummary(entry.value);
    }
    return summaries;
  }

  Map<String, dynamic> _getSummary(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return {'error': 'No data'};

    // ---- 1. Core numbers ----
    final trackCounts = _countValues(records, 'title');
    final mostPlayed = _topN(trackCounts, 500);

    double totalSeconds = 0;
    for (final r in records) {
      final d = r['duration'];
      if (d is num) totalSeconds += d.toDouble();
    }
    final totalHours = totalSeconds / 3600.0;

    final uniqueTracks =
        records.map((r) => r['track_base']).toSet().length;
    final uniqueArtists =
        records.map((r) => r['artist']).toSet().length;
    final uniqueAlbums =
        records.map((r) => r['album']).toSet().length;

    final genreCounts = _countValues(
        records.where((r) => r['genre'] != 'Unknown Genre').toList(),
        'genre');
    final favoriteGenre = genreCounts.isNotEmpty
        ? genreCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : 'Unknown Genre';

    // ---- 2. Top rankings ----
    final artistCounts = _countValues(
        records.where((r) => r['artist'] != 'Unknown Artist').toList(),
        'artist');
    final topArtists = _topN(artistCounts, 200);

    final albumCounts = _countValues(
        records
            .where((r) =>
                r['album'] != 'Unknown Album' &&
                (r['album']?.toString() ?? '').isNotEmpty)
            .toList(),
        'album');
    final topAlbums = _topN(albumCounts, 200);

    // Monthly top song
    final monthlyGroups = <String, List<Map<String, dynamic>>>{};
    for (final r in records) {
      final dt = r['datetime'];
      if (dt is DateTime) {
        final key = '${dt.year}-${_pad2(dt.month)}';
        monthlyGroups.putIfAbsent(key, () => []).add(r);
      }
    }
    final monthlyTopSong = <String, String>{};
    for (final e in monthlyGroups.entries) {
      final c = _countValues(e.value, 'title');
      if (c.isNotEmpty) {
        monthlyTopSong[e.key] =
            c.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
    }

    // ---- 3. Time dimension ----
    final playHistoryByDate = <String, int>{};
    final listeningPeriods = <String, int>{
      for (int h = 0; h < 24; h++) '${_pad2(h)}:00': 0
    };
    final weeklyPattern = <String, int>{
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0,
      'Fri': 0, 'Sat': 0, 'Sun': 0,
    };
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (final r in records) {
      final dt = r['datetime'];
      if (dt is DateTime) {
        final dateStr = r['date_only'] as String;
        playHistoryByDate[dateStr] =
            (playHistoryByDate[dateStr] ?? 0) + 1;
        final hourKey = '${_pad2(dt.hour)}:00';
        listeningPeriods[hourKey] =
            (listeningPeriods[hourKey] ?? 0) + 1;
        final dayKey = dayNames[dt.weekday - 1];
        weeklyPattern[dayKey] = (weeklyPattern[dayKey] ?? 0) + 1;
      }
    }

    final sortedPlayHistory = Map.fromEntries(
        playHistoryByDate.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)));

    // ---- 4. Special highlights ----
    // Single-day repeat max
    var singleDayRepeatMax = <String, dynamic>{
      'date': '', 'track': '', 'count': 0
    };
    {
      final dailyCounts = <String, Map<String, int>>{};
      for (final r in records) {
        final dateStr = r['date_only'] as String?;
        final title = r['title'] as String?;
        if (dateStr != null && title != null) {
          dailyCounts.putIfAbsent(dateStr, () => {});
          dailyCounts[dateStr]![title] =
              (dailyCounts[dateStr]![title] ?? 0) + 1;
        }
      }
      int maxCount = 0;
      for (final de in dailyCounts.entries) {
        for (final te in de.value.entries) {
          if (te.value > maxCount) {
            maxCount = te.value;
            singleDayRepeatMax = {
              'date': de.key,
              'track': te.key,
              'count': te.value,
            };
          }
        }
      }
    }

    // Latest night song (00:00 – 05:59)
    var latestNightSong = <String, String>{'time': '', 'track': ''};
    {
      int latestTimeVal = -1;
      for (final r in records) {
        final dt = r['datetime'];
        if (dt is DateTime && dt.hour >= 0 && dt.hour < 6) {
          final tv = dt.hour * 10000 + dt.minute * 100 + dt.second;
          if (tv > latestTimeVal) {
            latestTimeVal = tv;
            latestNightSong = {
              'time': _fmtDt(dt),
              'track': r['title'].toString(),
            };
          }
        }
      }
    }

    // Most immersive day
    var mostImmersiveDay = <String, dynamic>{'date': '', 'count': 0};
    final totalDays = playHistoryByDate.length;
    if (playHistoryByDate.isNotEmpty) {
      final maxEntry = playHistoryByDate.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      mostImmersiveDay = {'date': maxEntry.key, 'count': maxEntry.value};
    }
    final avgDailyMinutes =
        totalDays > 0 ? (totalHours * 60 / totalDays).round() : 0;

    // ---- 5. Track details (top 300) ----
    final trackDetails = <String, dynamic>{};
    for (final tName in mostPlayed.keys.take(300)) {
      final tRecords = records.where((r) => r['title'] == tName).toList();
      if (tRecords.isEmpty) continue;
      final representative = _pickRepresentativeRecord(tRecords);
      final dates = tRecords
          .map((r) => r['datetime'])
          .whereType<DateTime>()
          .toList();
      final history = _dateHistogram(tRecords);
      trackDetails[tName] = {
        'first_play': dates.isNotEmpty
            ? _fmtDt(dates.reduce((a, b) => a.isBefore(b) ? a : b))
            : 'Unknown',
        'last_play': dates.isNotEmpty
            ? _fmtDt(dates.reduce((a, b) => a.isAfter(b) ? a : b))
            : 'Unknown',
        'history': history,
        'total_plays': tRecords.length,
        'cover': _getTrackCover(tName, records),
        'sourcePath': representative['sourcePath']?.toString() ?? '',
        'localPath': representative['localPath']?.toString() ?? '',
        'track_base': representative['track_base']?.toString() ?? '',
        'album': representative['album']?.toString() ?? '',
      };
    }

    // ---- 6. Artist details (top 200) ----
    final artistDetails = <String, dynamic>{};
    for (final aName in topArtists.keys.take(200)) {
      final aRecords =
          records.where((r) => r['artist'] == aName).toList();
      if (aRecords.isEmpty) continue;
      final representative = _pickRepresentativeRecord(aRecords);
      final dates = aRecords
          .map((r) => r['datetime'])
          .whereType<DateTime>()
          .toList();
      final history = _dateHistogram(aRecords);
      final topSongs = _topN(_countValues(aRecords, 'title'), 10);
      artistDetails[aName] = {
        'first_play': dates.isNotEmpty
            ? _fmtDt(dates.reduce((a, b) => a.isBefore(b) ? a : b))
            : 'Unknown',
        'last_play': dates.isNotEmpty
            ? _fmtDt(dates.reduce((a, b) => a.isAfter(b) ? a : b))
            : 'Unknown',
        'history': history,
        'total_plays': aRecords.length,
        'top_songs': topSongs,
        'cover': _getArtistCover(aName, records),
        'sourcePath': representative['sourcePath']?.toString() ?? '',
        'localPath': representative['localPath']?.toString() ?? '',
        'track_base': representative['track_base']?.toString() ?? '',
        'album': representative['album']?.toString() ?? '',
        'cover_candidates': _collectCoverCandidates(aRecords),
      };
    }

    // ---- 7. Album details (top 200) ----
    final albumDetails = <String, dynamic>{};
    for (final alName in topAlbums.keys.take(200)) {
      final alRecords =
          records.where((r) => r['album'] == alName).toList();
      if (alRecords.isEmpty) continue;
      final representative = _pickRepresentativeRecord(alRecords);
      final dates = alRecords
          .map((r) => r['datetime'])
          .whereType<DateTime>()
          .toList();
      final history = _dateHistogram(alRecords);
      final topSongs = _topN(_countValues(alRecords, 'title'), 10);
      albumDetails[alName] = {
        'first_play': dates.isNotEmpty
            ? _fmtDt(dates.reduce((a, b) => a.isBefore(b) ? a : b))
            : 'Unknown',
        'last_play': dates.isNotEmpty
            ? _fmtDt(dates.reduce((a, b) => a.isAfter(b) ? a : b))
            : 'Unknown',
        'history': history,
        'total_plays': alRecords.length,
        'top_songs': topSongs,
        'cover': _albumCovers[alName] ?? '',
        'sourcePath': representative['sourcePath']?.toString() ?? '',
        'localPath': representative['localPath']?.toString() ?? '',
        'track_base': representative['track_base']?.toString() ?? '',
        'album': alName,
        'cover_candidates': _collectCoverCandidates(alRecords),
      };
    }

    // ---- 8. Compact data for remaining tracks (lazy loading in UI) ----
    // Pre-group records by title once (O(n)) to avoid O(n×m) repeated scans.
    final recordsByTitle = <String, List<Map<String, dynamic>>>{};
    for (final r in records) {
      final title = r['title'] as String?;
      if (title != null && title.isNotEmpty) {
        recordsByTitle.putIfAbsent(title, () => []).add(r);
      }
    }
    final allTrackCompact = <String, dynamic>{};
    for (final entry in recordsByTitle.entries) {
      final tName = entry.key;
      if (trackDetails.containsKey(tName)) continue; // already pre-computed
      final tRecords = entry.value;
      final representative = _pickRepresentativeRecord(tRecords);
      final datetimes = tRecords
          .map((r) => r['datetime'])
          .whereType<DateTime>()
          .toList();
      final history = _dateHistogram(tRecords);
      allTrackCompact[tName] = {
        'first_play': datetimes.isNotEmpty
            ? _fmtDt(datetimes.reduce((a, b) => a.isBefore(b) ? a : b))
            : 'Unknown',
        'last_play': datetimes.isNotEmpty
            ? _fmtDt(datetimes.reduce((a, b) => a.isAfter(b) ? a : b))
            : 'Unknown',
        'history': history,
        'total_plays': tRecords.length,
        'cover': _getTrackCover(tName, tRecords),
        'sourcePath': representative['sourcePath']?.toString() ?? '',
        'localPath': representative['localPath']?.toString() ?? '',
        'track_base': representative['track_base']?.toString() ?? '',
        'album': representative['album']?.toString() ?? '',
      };
    }

    return {
      'total_plays': records.length,
      'total_days': totalDays,
      'avg_daily_minutes': avgDailyMinutes,
      'unique_tracks': uniqueTracks,
      'most_played': mostPlayed,
      'play_history_by_date': sortedPlayHistory,
      'total_hours': double.parse(totalHours.toStringAsFixed(1)),
      'unique_artists': uniqueArtists,
      'unique_albums': uniqueAlbums,
      'favorite_genre': favoriteGenre,
      'top_artists': topArtists,
      'top_albums': topAlbums,
      'monthly_top_song': monthlyTopSong,
      'listening_periods': listeningPeriods,
      'weekly_pattern': weeklyPattern,
      'single_day_repeat_max': singleDayRepeatMax,
      'latest_night_song': latestNightSong,
      'most_immersive_day': mostImmersiveDay,
      'track_details': trackDetails,
      'artist_details': artistDetails,
      'album_details': albumDetails,
      'all_track_compact': allTrackCompact,
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _metaStr(Map<String, dynamic>? meta, String key, String fallback) {
    if (meta == null) return fallback;
    final val = meta[key];
    if (val == null || val.toString().isEmpty) return fallback;
    return val.toString();
  }

  Map<String, dynamic> _buildMergedTrackMeta(
    String sourcePath,
    Map<String, dynamic>? backupMeta,
  ) {
    final durationMs = _asNum(backupMeta?['durationMS']);
    final durationSec = _asNum(backupMeta?['duration']);
    final resolvedDuration = durationMs != null
        ? durationMs / 1000.0
        : (durationSec?.toDouble() ?? 0.0);

    return {
      'artist': _firstNonEmpty([
        backupMeta?['originalArtist'],
        backupMeta?['artist'],
      ]),
      'album': _firstNonEmpty([
        backupMeta?['originalAlbum'],
        backupMeta?['album'],
      ]),
      'title': _firstNonEmpty([
        backupMeta?['title'],
      ]),
      'genre': _firstNonEmpty([
        backupMeta?['originalGenre'],
        backupMeta?['genre'],
      ]),
      'duration': resolvedDuration,
      'localPath': _remapTrackPathSync(
        sourcePath,
        musicDir: _musicDirectory,
      ),
    };
  }

  Map<String, dynamic> _pickRepresentativeRecord(
    List<Map<String, dynamic>> records,
  ) {
    for (final record in records) {
      final localPath = record['localPath']?.toString() ?? '';
      if (localPath.isNotEmpty && File(localPath).existsSync()) {
        return record;
      }
    }
    for (final record in records) {
      final sourcePath = record['sourcePath']?.toString() ?? '';
      if (sourcePath.isNotEmpty) {
        return record;
      }
    }
    for (final record in records) {
      final localPath = record['localPath']?.toString() ?? '';
      if (localPath.isNotEmpty) {
        return record;
      }
    }
    return records.first;
  }

  Future<String> resolveLocalPathForDetailsAsync(
    Map<dynamic, dynamic> details,
  ) async {
    final resolved = await resolveTrackFilePathAsync(
      sourcePath: details['sourcePath']?.toString() ?? '',
      localPath: details['localPath']?.toString() ?? '',
    );
    if (resolved.isNotEmpty) {
      details['localPath'] = resolved;
    }
    return resolved;
  }

  Future<String> resolveTrackFilePathAsync({
    required String sourcePath,
    String? localPath,
  }) async {
    await _ensurePathCacheLoadedAsync();

    final directPath = localPath?.trim() ?? '';
    if (directPath.isNotEmpty && File(directPath).existsSync()) {
      return directPath;
    }

    final originalPath = sourcePath.trim();
    if (originalPath.isEmpty) {
      return '';
    }
    if (File(originalPath).existsSync()) {
      return originalPath;
    }

    final cacheKey = _buildPathCacheKey(originalPath, _musicDirectory);
    final cached = _resolvedTrackPathCache[cacheKey];
    if (cached != null && cached.isNotEmpty && File(cached).existsSync()) {
      return cached;
    }
    if (cached != null && cached.isNotEmpty) {
      _resolvedTrackPathCache.remove(cacheKey);
      await _savePathCacheAsync();
    }

    final remapped = _remapTrackPathSync(
      originalPath,
      preferredPath: localPath,
      musicDir: _musicDirectory,
    );
    if (remapped.isNotEmpty) {
      await _cacheResolvedTrackPathAsync(cacheKey, remapped);
      return remapped;
    }

    if (_missingTrackPathCache.contains(cacheKey)) {
      return '';
    }

    final searched = await _searchTrackPathAsync(originalPath, _musicDirectory);
    if (searched.isNotEmpty) {
      await _cacheResolvedTrackPathAsync(cacheKey, searched);
      return searched;
    }

    _missingTrackPathCache.add(cacheKey);
    await _savePathCacheAsync();
    return '';
  }

  Future<String> extractCoverForDetailsAsync(
    Map<dynamic, dynamic> details,
  ) async {
    final existingCover = details['cover']?.toString() ?? '';
    if (existingCover.isNotEmpty && File(existingCover).existsSync()) {
      return existingCover;
    }

    final coverPath = await _extractCoverFromCandidateAsync(details);
    if (coverPath.isNotEmpty) {
      details['cover'] = coverPath;
      return coverPath;
    }

    final rawCandidates = details['cover_candidates'];
    if (rawCandidates is List) {
      for (final candidate in rawCandidates) {
        if (candidate is! Map) continue;
        final coverPath = await _extractCoverFromCandidateAsync(
          Map<dynamic, dynamic>.from(candidate),
        );
        if (coverPath.isEmpty) {
          continue;
        }
        details['cover'] = coverPath;
        final resolvedLocalPath = candidate['localPath']?.toString() ?? '';
        if (resolvedLocalPath.isNotEmpty) {
          details['localPath'] = resolvedLocalPath;
        }
        return coverPath;
      }
    }

    return '';
  }

  Future<String> _extractCoverFromCandidateAsync(
    Map<dynamic, dynamic> candidate,
  ) async {
    final localPath = await resolveTrackFilePathAsync(
      sourcePath: candidate['sourcePath']?.toString() ?? '',
      localPath: candidate['localPath']?.toString() ?? '',
    );
    if (localPath.isEmpty) {
      return '';
    }

    candidate['localPath'] = localPath;
    final trackBase = candidate['track_base']?.toString();
    final album = candidate['album']?.toString();
    return extractCoverFromAudioFileAsync(
      localPath,
      trackBase?.isNotEmpty == true ? trackBase : null,
      album?.isNotEmpty == true ? album : null,
    );
  }

  List<Map<String, String>> _collectCoverCandidates(
    List<Map<String, dynamic>> records, {
    int maxCount = 12,
  }) {
    final candidates = <Map<String, String>>[];
    final seen = <String>{};

    void addFromRecord(Map<String, dynamic> record) {
      final sourcePath = record['sourcePath']?.toString() ?? '';
      final localPath = record['localPath']?.toString() ?? '';
      final trackBase = record['track_base']?.toString() ?? '';
      if (sourcePath.isEmpty && localPath.isEmpty && trackBase.isEmpty) {
        return;
      }
      final identity = trackBase.isNotEmpty
          ? trackBase.toLowerCase()
          : _normalizeTrackPath(sourcePath.isNotEmpty ? sourcePath : localPath);
      if (identity.isEmpty || !seen.add(identity)) {
        return;
      }
      candidates.add({
        'sourcePath': sourcePath,
        'localPath': localPath,
        'track_base': trackBase,
        'album': record['album']?.toString() ?? '',
      });
    }

    for (final record in records) {
      final localPath = record['localPath']?.toString() ?? '';
      if (localPath.isNotEmpty && File(localPath).existsSync()) {
        addFromRecord(record);
        if (candidates.length >= maxCount) {
          return candidates;
        }
      }
    }

    for (final record in records) {
      addFromRecord(record);
      if (candidates.length >= maxCount) {
        break;
      }
    }
    return candidates;
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  num? _asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  List<String> _asStringList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, int> _countValues(
      List<Map<String, dynamic>> records, String key) {
    final counts = <String, int>{};
    for (final r in records) {
      final val = r[key]?.toString() ?? '';
      if (val.isNotEmpty) counts[val] = (counts[val] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _topN(Map<String, int> counts, int n) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(n));
  }

  Map<String, int> _dateHistogram(List<Map<String, dynamic>> records) {
    final hist = <String, int>{};
    for (final r in records) {
      final d = r['date_only'] as String?;
      if (d != null) hist[d] = (hist[d] ?? 0) + 1;
    }
    return Map.fromEntries(
        hist.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  String _getTrackCover(
      String trackTitle, List<Map<String, dynamic>> records) {
    final match = records.where((r) => r['title'] == trackTitle).firstOrNull;
    if (match != null) {
      final base = match['track_base'] as String?;
      if (base != null && _trackCovers.containsKey(base)) {
        return _trackCovers[base]!;
      }
      final album = match['album'] as String?;
      if (album != null && _albumCovers.containsKey(album)) {
        return _albumCovers[album]!;
      }
    }
    return '';
  }

  String _getArtistCover(
      String artistName, List<Map<String, dynamic>> records) {
    final artistRecords =
        records.where((r) => r['artist'] == artistName).toList();
    if (artistRecords.isEmpty) return '';
    final counts = _countValues(artistRecords, 'title');
    if (counts.isEmpty) return '';
    final topTrack =
        counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _getTrackCover(topTrack, artistRecords);
  }

  /// Async method to extract cover from audio file on-demand.
  /// UI can call this when hovering/clicking on a track that needs cover art.
  Future<String> extractCoverFromAudioFileAsync(
    String filePath,
    String? baseName,
    String? album,
  ) async {
    if (!File(filePath).existsSync()) return '';
    try {
      final metadata = await parseFile(filePath);
      final common = metadata.common;
      final cover = selectCover(common.picture);
      if (cover != null && cover.data.length >= 100) {
        _saveCover(cover.data, baseName ?? '', album);
        if (baseName != null &&
            baseName.isNotEmpty &&
            _trackCovers.containsKey(baseName)) {
          return _trackCovers[baseName]!;
        }
        if (album != null &&
            album.isNotEmpty &&
            _albumCovers.containsKey(album)) {
          return _albumCovers[album]!;
        }
      }
    } catch (_) {}

    final ffmpegCover = await _extractCoverUsingFfmpegAsync(
      filePath,
      baseName,
      album,
    );
    if (ffmpegCover.isNotEmpty) {
      return ffmpegCover;
    }

    return '';
  }

  Future<String> _extractCoverUsingFfmpegAsync(
    String filePath,
    String? baseName,
    String? album,
  ) async {
    if (!await _isFfmpegAvailableAsync()) {
      return '';
    }

    final tempBase = baseName?.isNotEmpty == true
        ? _sanitizeFilename(baseName!)
        : _sanitizeFilename(p.basenameWithoutExtension(filePath));
    final outPath = p.join(_coversDir, 'ffmpeg_$tempBase.jpg');

    try {
      final result = await Process.run(
        'ffmpeg',
        [
          '-y',
          '-loglevel',
          'error',
          '-i',
          filePath,
          '-map',
          '0:v:0',
          '-frames:v',
          '1',
          outPath,
        ],
      );
      if (result.exitCode != 0) {
        return '';
      }

      final outFile = File(outPath);
      if (!outFile.existsSync()) {
        return '';
      }

      final bytes = await outFile.readAsBytes();
      if (bytes.length < 100) {
        return '';
      }

      _saveCover(bytes, baseName ?? tempBase, album);
      if (baseName != null &&
          baseName.isNotEmpty &&
          _trackCovers.containsKey(baseName)) {
        return _trackCovers[baseName]!;
      }
      if (album != null &&
          album.isNotEmpty &&
          _albumCovers.containsKey(album)) {
        return _albumCovers[album]!;
      }
      if (_trackCovers.containsKey(tempBase)) {
        return _trackCovers[tempBase]!;
      }
    } catch (_) {
      return '';
    }

    return '';
  }

  static Future<bool> _isFfmpegAvailableAsync() async {
    if (_ffmpegAvailable != null) {
      return _ffmpegAvailable!;
    }
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      _ffmpegAvailable = result.exitCode == 0;
    } catch (_) {
      _ffmpegAvailable = false;
    }
    return _ffmpegAvailable!;
  }

  String _sanitizeFilename(String name) {
    var s = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (s.length > 100) s = s.substring(0, 100);
    return s;
  }

  static Future<void> _cacheResolvedTrackPathAsync(String cacheKey, String resolvedPath) async {
    _missingTrackPathCache.remove(cacheKey);
    _resolvedTrackPathCache[cacheKey] = resolvedPath;
    await _savePathCacheAsync();
  }

  static Future<void> _ensurePathCacheLoadedAsync() async {
    _pathCacheLoadFuture ??= _loadPathCacheAsync();
    await _pathCacheLoadFuture;
  }

  static Future<void> _loadPathCacheAsync() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _pathCacheFile = File(p.join(dir.path, 'track_path_cache.json'));
      if (!await _pathCacheFile!.exists()) {
        return;
      }

      final content = await _pathCacheFile!.readAsString();
      if (content.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final resolved = decoded['resolved'];
      if (resolved is Map) {
        for (final entry in resolved.entries) {
          final cacheKey = entry.key.toString();
          final path = entry.value?.toString() ?? '';
          if (path.isNotEmpty) {
            _resolvedTrackPathCache[cacheKey] = path;
          }
        }
      }

      final missing = decoded['missing'];
      if (missing is List) {
        for (final entry in missing) {
          final cacheKey = entry?.toString() ?? '';
          if (cacheKey.isNotEmpty) {
            _missingTrackPathCache.add(cacheKey);
          }
        }
      }
    } catch (_) {
      _resolvedTrackPathCache.clear();
      _missingTrackPathCache.clear();
    }
  }

  static Future<void> _savePathCacheAsync() async {
    try {
      final file = _pathCacheFile ??= File(
        p.join((await getApplicationSupportDirectory()).path, 'track_path_cache.json'),
      );
      final payload = {
        'version': 1,
        'resolved': _resolvedTrackPathCache,
        'missing': _missingTrackPathCache.toList(growable: false),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // Ignore cache persistence failures.
    }
  }

  static String _buildPathCacheKey(String sourcePath, String? musicDir) {
    return '${_normalizeTrackPath(sourcePath)}|${_normalizeTrackPath(musicDir ?? '')}';
  }

  static String _remapTrackPathSync(
    String sourcePath, {
    String? preferredPath,
    String? musicDir,
  }) {
    final preferred = preferredPath?.trim() ?? '';
    if (preferred.isNotEmpty && File(preferred).existsSync()) {
      return preferred;
    }

    final original = sourcePath.trim();
    if (original.isEmpty) {
      return '';
    }
    if (File(original).existsSync()) {
      return original;
    }

    final baseDir = musicDir?.trim() ?? '';
    if (baseDir.isEmpty || !Directory(baseDir).existsSync()) {
      return '';
    }

    final candidates = _buildRemapCandidates(original, baseDir);
    for (final candidate in candidates) {
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }
    return '';
  }

  static List<String> _buildRemapCandidates(String sourcePath, String musicDir) {
    final sourceSegments = _pathSegments(sourcePath);
    final candidates = <String>{};
    for (int start = 0; start < sourceSegments.length; start++) {
      final suffix = sourceSegments.sublist(start);
      if (suffix.isEmpty) {
        continue;
      }
      candidates.add(p.normalize(p.joinAll([musicDir, ...suffix])));
    }

    final basename = p.basename(sourcePath);
    if (basename.isNotEmpty) {
      candidates.add(p.normalize(p.join(musicDir, basename)));
    }
    return candidates.toList(growable: false);
  }

  Future<String> _searchTrackPathAsync(String sourcePath, String? musicDir) async {
    final baseDir = musicDir?.trim() ?? '';
    if (baseDir.isEmpty) {
      return '';
    }

    final dir = Directory(baseDir);
    if (!dir.existsSync()) {
      return '';
    }

    final targetName = p.basename(sourcePath).toLowerCase();
    final targetBase = p.basenameWithoutExtension(sourcePath).toLowerCase();
    final targetExt = p.extension(sourcePath).toLowerCase();
    final sourceSegments = _pathSegments(sourcePath);

    var bestPath = '';
    var bestScore = -1;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final candidateExt = p.extension(entity.path).toLowerCase();
      if (targetExt.isNotEmpty && candidateExt != targetExt) {
        continue;
      }

      final candidateName = p.basename(entity.path).toLowerCase();
      final candidateBase = p.basenameWithoutExtension(entity.path).toLowerCase();
      if (candidateName != targetName && candidateBase != targetBase) {
        continue;
      }

      final score = _scorePathMatch(sourceSegments, entity.path);
      if (score > bestScore) {
        bestScore = score;
        bestPath = entity.path;
      }
    }

    return bestPath;
  }

  static int _scorePathMatch(List<String> sourceSegments, String candidatePath) {
    final candidateSegments = _pathSegments(candidatePath);
    var score = 0;
    var sourceIndex = sourceSegments.length - 1;
    var candidateIndex = candidateSegments.length - 1;
    var consecutiveMatches = 0;

    while (sourceIndex >= 0 && candidateIndex >= 0) {
      if (sourceSegments[sourceIndex] == candidateSegments[candidateIndex]) {
        consecutiveMatches++;
        score += candidateIndex == candidateSegments.length - 1 ? 20 : 5 * consecutiveMatches;
        sourceIndex--;
        candidateIndex--;
        continue;
      }
      break;
    }

    return score;
  }

  static List<String> _pathSegments(String path) {
    return path
        .replaceAll('\\', '/')
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty && segment != '.')
        .toList(growable: false);
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  static String _fmtDt(DateTime dt) =>
      '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)} '
      '${_pad2(dt.hour)}:${_pad2(dt.minute)}:${_pad2(dt.second)}';
}
