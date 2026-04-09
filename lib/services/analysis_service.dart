import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:metadata_audio/metadata_audio.dart';
import 'package:path/path.dart' as p;

class AnalysisService {
  final Map<String, Map<String, dynamic>> _musicMetadata = {};
  final Map<String, String> _albumCovers = {};
  final Map<String, String> _trackCovers = {};
  late final String _coversDir;

  AnalysisService() {
    _coversDir = p.join(Directory.systemTemp.path, 'namida_covers');
    Directory(_coversDir).createSync(recursive: true);
  }

  /// Internal constructor for isolate workers (no dir creation needed).
  AnalysisService._worker(
    String coversDir,
    Map<String, Map<String, dynamic>> musicMeta,
    Map<String, String> albumCovers,
    Map<String, String> trackCovers,
  ) {
    _coversDir = coversDir;
    _musicMetadata.addAll(musicMeta);
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

    // Phase 1: Extract ZIPs
    onProgress?.call('extracting:${zipPaths.length}');
    final extractCount = await Isolate.run(() {
      return _extractAndMerge(zipPaths, tempDir, mergedDir);
    });
    if (extractCount == 0) {
      return {'success': false, 'error': '提取历史文件夹失败，请检查ZIP格式或路径'};
    }

    // Phase 2: Scan music directory
    final coversDir = _coversDir;
    Map<String, Map<String, dynamic>> musicMeta = {};
    Map<String, String> albumCovers = {};
    Map<String, String> trackCovers = {};
    if (musicDir != null) {
      onProgress?.call('scanning');
      final scanResult = await Isolate.run(() async {
        final worker = AnalysisService._worker(coversDir, {}, {}, {});
        await worker._scanMusicDirectory(musicDir);
        return {
          'musicMetadata': worker._musicMetadata,
          'albumCovers': worker._albumCovers,
          'trackCovers': worker._trackCovers,
        };
      });
      musicMeta = Map<String, Map<String, dynamic>>.from(
        (scanResult['musicMetadata'] as Map).map((k, v) =>
          MapEntry(k.toString(), Map<String, dynamic>.from(v as Map))),
      );
      albumCovers = Map<String, String>.from(scanResult['albumCovers'] as Map);
      trackCovers = Map<String, String>.from(scanResult['trackCovers'] as Map);
    }

    // Phase 3: Load, enrich, and analyze
    onProgress?.call('analyzing');
    final result = await Isolate.run(() {
      final worker = AnalysisService._worker(coversDir, musicMeta, albumCovers, trackCovers);
      final records = worker._loadRecords(mergedDir);
      worker._enrichRecords(records);
      final summaries = worker._getAllSummaries(records);
      return {'success': true, 'summaries': summaries};
    });

    // Phase 4: Cleanup
    onProgress?.call('cleanup');
    try {
      Directory(tempDir).deleteSync(recursive: true);
    } catch (_) {}

    return result;
  }

  /// Runs in background isolate: extract ZIPs and merge JSON files.
  static int _extractAndMerge(
      List<String> zipPaths, String tempDir, String mergedDir) {
    int successCount = 0;
    for (int i = 0; i < zipPaths.length; i++) {
      final resultPath =
          _extractHistoryFolderSync(zipPaths[i], p.join(tempDir, 'zip_$i'));
      if (resultPath != null && Directory(resultPath).existsSync()) {
        _mergeJsonFiles(resultPath, mergedDir);
        successCount++;
        try {
          Directory(resultPath).deleteSync(recursive: true);
        } catch (_) {}
      }
    }
    return successCount;
  }

  // ---------------------------------------------------------------------------
  // ZIP extraction (replaces extractor.py)
  // ---------------------------------------------------------------------------

  static String? _extractHistoryFolderSync(
      String backupZipPath, String extractToPath) {
    final zipFile = File(backupZipPath);
    if (!zipFile.existsSync()) return null;

    try {
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find the nested TEMPDIR_History.zip
      ArchiveFile? historyZipEntry;
      for (final file in archive) {
        if (file.name == 'TEMPDIR_History.zip' && file.isFile) {
          historyZipEntry = file;
          break;
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
      return historyDir;
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

  // ---------------------------------------------------------------------------
  // Music metadata scanning (replaces parser.py scan_music_directory)
  // ---------------------------------------------------------------------------

  Future<void> _scanMusicDirectory(String musicDir) async {
    final dir = Directory(musicDir);
    if (!dir.existsSync()) return;

    final supportedExts = {
      '.mp3', '.flac', '.m4a', '.wav', '.ogg', '.opus', '.aac', '.wma'
    };

    await for (final entity in dir.list(recursive: true)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (!supportedExts.contains(ext)) continue;

      try {
        final metadata = await parseFile(entity.path);
        final baseName =
            p.basenameWithoutExtension(entity.path).toLowerCase();

        if (!_musicMetadata.containsKey(baseName)) {
          final common = metadata.common;
          final durationVal = metadata.format.duration;
          final duration = durationVal?.toDouble() ?? 0.0;

          _musicMetadata[baseName] = {
            'artist': common.artist,
            'album': common.album,
            'title': common.title,
            'duration': duration,
            'genre': common.genre?.firstOrNull,
            'localPath': entity.path,
          };

          // Extract cover art
          final cover = selectCover(common.picture);
          if (cover != null &&
              cover.data.length >= 100) {
            _saveCover(cover.data, baseName, common.album);
          }
        }
      } catch (_) {
        // skip un-parseable files
      }
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
      r['track_name'] = trackName;
      r['track_base'] = trackBase;

      // Map metadata
      final meta = _musicMetadata[trackBase];
      r['artist'] = _metaStr(meta, 'artist', 'Unknown Artist');
      r['album'] = _metaStr(meta, 'album', 'Unknown Album');
      r['title'] = _metaStr(meta, 'title', '') .isEmpty
          ? trackName
          : _metaStr(meta, 'title', trackName);
      r['duration'] = (meta?['duration'] is num)
          ? (meta!['duration'] as num).toDouble()
          : 0.0;
      r['genre'] = _metaStr(meta, 'genre', 'Unknown Genre');
      r['localPath'] = meta?['localPath']?.toString() ?? '';

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
        'localPath': tRecords.firstWhere((r) => (r['localPath']?.toString() ?? '').isNotEmpty, orElse: () => {})['localPath']?.toString() ?? '',
      };
    }

    // ---- 6. Artist details (top 200) ----
    final artistDetails = <String, dynamic>{};
    for (final aName in topArtists.keys.take(200)) {
      final aRecords =
          records.where((r) => r['artist'] == aName).toList();
      if (aRecords.isEmpty) continue;
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
      };
    }

    // ---- 7. Album details (top 200) ----
    final albumDetails = <String, dynamic>{};
    for (final alName in topAlbums.keys.take(200)) {
      final alRecords =
          records.where((r) => r['album'] == alName).toList();
      if (alRecords.isEmpty) continue;
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
        'localPath': tRecords.firstWhere(
          (r) => (r['localPath']?.toString() ?? '').isNotEmpty,
          orElse: () => {},
        )['localPath']?.toString() ?? '',
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

  String _sanitizeFilename(String name) {
    var s = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (s.length > 100) s = s.substring(0, 100);
    return s;
  }

  static String _pad2(int n) => n.toString().padLeft(2, '0');

  static String _fmtDt(DateTime dt) =>
      '${dt.year}-${_pad2(dt.month)}-${_pad2(dt.day)} '
      '${_pad2(dt.hour)}:${_pad2(dt.minute)}:${_pad2(dt.second)}';
}
