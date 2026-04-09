import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/config_service.dart';

/// The 8 core stat card keys in default order.
const List<String> kDefaultCoreKeys = [
  'total_hours',
  'total_days',
  'avg_daily_minutes',
  'total_plays',
  'unique_tracks',
  'unique_artists',
  'unique_albums',
  'favorite_genre',
];

/// Resolve a core-stat key to its localized display name.
String coreKeyLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'total_hours':
      return l10n.statTotalListening;
    case 'total_days':
      return l10n.statListeningCompanion;
    case 'avg_daily_minutes':
      return l10n.statAvgDaily;
    case 'total_plays':
      return l10n.statTotalPlays;
    case 'unique_tracks':
      return l10n.statUniqueTracks;
    case 'unique_artists':
      return l10n.statUniqueArtists;
    case 'unique_albums':
      return l10n.statUniqueAlbums;
    case 'favorite_genre':
      return l10n.statFavoriteGenre;
    default:
      return key;
  }
}

IconData coreKeyIcon(String key) {
  switch (key) {
    case 'total_hours':
      return Icons.timer_rounded;
    case 'total_days':
      return Icons.calendar_month_rounded;
    case 'avg_daily_minutes':
      return Icons.hourglass_bottom_rounded;
    case 'total_plays':
      return Icons.play_circle_fill_rounded;
    case 'unique_tracks':
      return Icons.library_music_rounded;
    case 'unique_artists':
      return Icons.mic_rounded;
    case 'unique_albums':
      return Icons.album_rounded;
    case 'favorite_genre':
      return Icons.category_rounded;
    default:
      return Icons.help_outline;
  }
}

/// Load ordered + visibility list from config.
/// Returns list of (key, visible).
List<MapEntry<String, bool>> loadCoreNumbersConfig() {
  final raw = ConfigService().get('core_numbers_order');
  if (raw == null || raw.isEmpty) {
    return kDefaultCoreKeys.map((k) => MapEntry(k, true)).toList();
  }
  // format: key1:1,key2:0,key3:1,...
  final items = <MapEntry<String, bool>>[];
  final seen = <String>{};
  for (final part in raw.split(',')) {
    final segs = part.split(':');
    if (segs.length == 2 && kDefaultCoreKeys.contains(segs[0])) {
      items.add(MapEntry(segs[0], segs[1] == '1'));
      seen.add(segs[0]);
    }
  }
  // append any missing keys
  for (final k in kDefaultCoreKeys) {
    if (!seen.contains(k)) {
      items.add(MapEntry(k, true));
    }
  }
  return items;
}

Future<void> saveCoreNumbersConfig(List<MapEntry<String, bool>> items) async {
  final encoded = items.map((e) => '${e.key}:${e.value ? '1' : '0'}').join(',');
  await ConfigService().set('core_numbers_order', encoded);
}

class SettingsScreen extends StatefulWidget {
  final String? musicDirectory;
  final String? namidaPath;
  final ValueChanged<String?> onMusicDirectoryChanged;
  final ValueChanged<String?> onNamidaPathChanged;

  const SettingsScreen({
    super.key,
    required this.musicDirectory,
    required this.namidaPath,
    required this.onMusicDirectoryChanged,
    required this.onNamidaPathChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String? _musicDirectory;
  late String? _namidaPath;

  late int _topTracksCount;
  late int _topArtistsCount;
  late int _topAlbumsCount;
  late int _monthlyPreviewCount;
  late String _monthFormat; // 'numeric' or 'english'

  late List<MapEntry<String, bool>> _coreItems;

  @override
  void initState() {
    super.initState();
    _musicDirectory = widget.musicDirectory;
    _namidaPath = widget.namidaPath;

    final cfg = ConfigService();
    _topTracksCount = cfg.getInt('top_tracks_count', 10);
    _topArtistsCount = cfg.getInt('top_artists_count', 10);
    _topAlbumsCount = cfg.getInt('top_albums_count', 10);
    _monthlyPreviewCount = cfg.getInt('monthly_preview_count', 10);
    _monthFormat = cfg.get('month_format') ?? 'numeric';

    _coreItems = loadCoreNumbersConfig();
  }

  Future<void> _setIntConfig(String key, int value) async {
    await ConfigService().set(key, value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // -- General Settings --
          _sectionHeader(l10n.settingsGeneralSection),
          _buildLanguageTile(l10n),
          _buildMonthFormatTile(l10n),

          // -- Path Settings --
          _sectionHeader(l10n.settingsPathSection),
          _buildMusicDirTile(l10n),
          if (!kIsWeb) _buildNamidaPathTile(l10n),

          // -- Display Settings --
          _sectionHeader(l10n.settingsDisplaySection),
          _buildNumberTile(
            title: l10n.settingsTopTracksCount,
            value: _topTracksCount,
            onChanged: (v) {
              setState(() => _topTracksCount = v);
              _setIntConfig('top_tracks_count', v);
            },
          ),
          _buildNumberTile(
            title: l10n.settingsTopArtistsCount,
            value: _topArtistsCount,
            onChanged: (v) {
              setState(() => _topArtistsCount = v);
              _setIntConfig('top_artists_count', v);
            },
          ),
          _buildNumberTile(
            title: l10n.settingsTopAlbumsCount,
            value: _topAlbumsCount,
            onChanged: (v) {
              setState(() => _topAlbumsCount = v);
              _setIntConfig('top_albums_count', v);
            },
          ),
          _buildNumberTile(
            title: l10n.settingsMonthlyPreviewCount,
            value: _monthlyPreviewCount,
            onChanged: (v) {
              setState(() => _monthlyPreviewCount = v);
              _setIntConfig('monthly_preview_count', v);
            },
          ),

          // -- Core Numbers --
          _sectionHeader(l10n.settingsCoreNumbers),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(l10n.dragToReorder, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 4),
          _buildCoreNumbersList(l10n),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  // --- Language ---
  Widget _buildLanguageTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      trailing: DropdownButton<Locale>(
        value: Provider.of<LocaleProvider>(context, listen: false).locale,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(value: const Locale('zh'), child: Text(l10n.chinese)),
          DropdownMenuItem(value: const Locale('en'), child: Text(l10n.english)),
        ],
        onChanged: (Locale? newLocale) {
          if (newLocale != null) {
            Provider.of<LocaleProvider>(context, listen: false).setLocale(newLocale);
            setState(() {});
          }
        },
      ),
    );
  }

  // --- Month Format ---
  Widget _buildMonthFormatTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.date_range),
      title: Text(l10n.settingsMonthFormat),
      trailing: DropdownButton<String>(
        value: _monthFormat,
        underline: const SizedBox.shrink(),
        items: [
          DropdownMenuItem(value: 'numeric', child: Text(l10n.monthFormatNumeric)),
          DropdownMenuItem(value: 'english', child: Text(l10n.monthFormatEnglish)),
        ],
        onChanged: (val) {
          if (val != null) {
            setState(() => _monthFormat = val);
            ConfigService().set('month_format', val);
          }
        },
      ),
    );
  }

  // --- Music Dir ---
  Widget _buildMusicDirTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.folder_open),
      title: Text('${l10n.optionalPath}'),
      subtitle: Text(
        _musicDirectory ?? l10n.chooseMusicFolder,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _musicDirectory != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                widget.onMusicDirectoryChanged(null);
                ConfigService().remove('music_directory');
                setState(() => _musicDirectory = null);
              },
            )
          : null,
      onTap: () async {
        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory != null) {
          widget.onMusicDirectoryChanged(selectedDirectory);
          ConfigService().set('music_directory', selectedDirectory);
          setState(() => _musicDirectory = selectedDirectory);
        }
      },
    );
  }

  // --- Namida Path ---
  Widget _buildNamidaPathTile(AppLocalizations l10n) {
    if (kIsWeb) return const SizedBox.shrink();
    if (Platform.isAndroid) {
      return ListTile(
        leading: const Icon(Icons.music_note_rounded),
        title: Text(l10n.namidaPathLabel),
        subtitle: Text(l10n.namidaAndroidHint, style: const TextStyle(fontSize: 12)),
        onTap: () async {
          try {
            await Process.run('am', ['start', '-n', 'com.msob7y.namida/.MainActivity']);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.launchFailed}: $e')));
            }
          }
        },
      );
    }
    return ListTile(
      leading: const Icon(Icons.music_note_rounded),
      title: Text(l10n.namidaPathLabel),
      subtitle: Text(
        _namidaPath ?? l10n.chooseNamidaExe,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _namidaPath != null
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                widget.onNamidaPathChanged(null);
                ConfigService().remove('namida_path');
                setState(() => _namidaPath = null);
              },
            )
          : null,
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['exe'],
        );
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          widget.onNamidaPathChanged(path);
          ConfigService().set('namida_path', path);
          setState(() => _namidaPath = path);
        }
      },
    );
  }

  // --- Number picker ---
  Widget _buildNumberTile({
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 1
                ? () => onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: 32,
            child: Center(
              child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < 50
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }

  // --- Core numbers reorderable list ---
  Widget _buildCoreNumbersList(AppLocalizations l10n) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _coreItems.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _coreItems.removeAt(oldIndex);
          _coreItems.insert(newIndex, item);
        });
        saveCoreNumbersConfig(_coreItems);
      },
      itemBuilder: (context, index) {
        final entry = _coreItems[index];
        final key = entry.key;
        final visible = entry.value;
        return ListTile(
          key: ValueKey(key),
          leading: Icon(coreKeyIcon(key), color: visible ? null : Theme.of(context).disabledColor),
          title: Text(
            coreKeyLabel(key, l10n),
            style: TextStyle(
              color: visible ? null : Theme.of(context).disabledColor,
              decoration: visible ? null : TextDecoration.lineThrough,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                visible ? l10n.visible : l10n.hidden,
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.drag_handle),
            ],
          ),
          onTap: () {
            setState(() {
              _coreItems[index] = MapEntry(key, !visible);
            });
            saveCoreNumbersConfig(_coreItems);
          },
        );
      },
    );
  }
}
