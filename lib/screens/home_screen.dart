import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';

import '../services/analysis_service.dart';
import '../services/config_service.dart';
import '../widgets/interactive_line_chart.dart';
import '../widgets/app_styles.dart';
import '../widgets/stat_card.dart';
import '../widgets/highlight_card.dart';
import '../widgets/time_charts.dart';
import '../widgets/top_list_section.dart';
import '../widgets/welcome_placeholder.dart';
import 'settings_screen.dart';

class AnalyzerHome extends StatefulWidget {
  const AnalyzerHome({super.key});

  @override
  State<AnalyzerHome> createState() => _AnalyzerHomeState();
}

class _AnalyzerHomeState extends State<AnalyzerHome> {
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _allSummaries;
  String _selectedYear = '';
  String? _musicDirectory;
  String? _namidaPath;

  @override
  void initState() {
    super.initState();
    _musicDirectory = ConfigService().get('music_directory');
    _namidaPath = ConfigService().get('namida_path');
    // Default namida path on Windows
    if (_namidaPath == null && !kIsWeb && Platform.isWindows) {
      const defaultPath = r'C:\Program Files\namida\namida.exe';
      if (File(defaultPath).existsSync()) {
        _namidaPath = defaultPath;
        ConfigService().set('namida_path', defaultPath);
      }
    }
  }

  void _showSettingsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SettingsScreen(
          musicDirectory: _musicDirectory,
          namidaPath: _namidaPath,
          onMusicDirectoryChanged: (val) => setState(() => _musicDirectory = val),
          onNamidaPathChanged: (val) => setState(() => _namidaPath = val),
        ),
      ),
    ).then((_) {
      // Refresh after returning from settings
      if (mounted) setState(() {});
    });
  }

  String _normalizeNewlines(String s) {
    return s.replaceAll('\\n', '\n');
  }

  Future<void> _pickAndAnalyze() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final validPaths = result.files
            .where((f) => f.path != null)
            .map((f) => f.path!)
            .toList();
        if (validPaths.isEmpty) return;

          // Request storage permission on Android when music directory is set
          if (!kIsWeb && Platform.isAndroid && _musicDirectory != null) {
            PermissionStatus status;
            // Android 13+ uses granular media permissions
            if (await Permission.audio.status.isDenied) {
              status = await Permission.audio.request();
            } else {
              status = await Permission.storage.request();
            }
            if (!status.isGranted && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.permissionDenied)),
              );
            }
          }

          setState(() {
          _isLoading = true;
          _statusMessage = _normalizeNewlines(l10n.extractingMessage);
          _allSummaries = null;
        });

        final service = AnalysisService();
        final parsed = await service.analyze(
          validPaths,
          _musicDirectory,
          onProgress: (msg) {
            if (!mounted) return;
            String display;
            if (msg.startsWith('extracting:')) {
              final total = msg.split(':')[1];
              display = l10n.progressExtracting(1, int.tryParse(total) ?? 1);
            } else if (msg == 'scanning') {
              display = l10n.progressScanning;
            } else if (msg == 'analyzing') {
              display = l10n.progressAnalyzing;
            } else if (msg == 'cleanup') {
              display = l10n.progressCleanup;
            } else {
              display = msg;
            }
            setState(() => _statusMessage = display);
          },
        );

        if (parsed['success'] == true) {
            setState(() {
            _allSummaries = Map<String, dynamic>.from(parsed['summaries']);

            // Find the actual map key that represents the broadest dataset (All Time)
            String? allTimeKey;
            for (var k in _allSummaries!.keys) {
              if (k == l10n.allTime || k == 'All Time' || k == '所有时间') {
                allTimeKey = k;
                break;
              }
            }
            if (allTimeKey != null) {
              _selectedYear = allTimeKey;
            } else if (_allSummaries != null && _allSummaries!.isNotEmpty) {
              _selectedYear = _allSummaries!.keys.first;
            }
            _statusMessage = l10n.analysisComplete;
          });
        } else {
          throw Exception(parsed['error'] ?? 'Unknown error');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.errorTitle),
          content: Text(_normalizeNewlines(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      setState(() {
        _statusMessage = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _allSummaries != null && _allSummaries!.containsKey(_selectedYear);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(AppLocalizations.of(context)!.namidaHistory, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: [
              if (hasData)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedYear,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: _allSummaries!.keys.map((String year) {
                          return DropdownMenuItem<String>(
                            value: year,
                            child: Text(
                              _displayYearLabel(year),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedYear = newValue;
                            });
                          }
                        }
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.settingsTitle,
                icon: const Icon(Icons.settings),
                onPressed: _showSettingsDialog,
              ),
              if (hasData)
                IconButton(
                  tooltip: AppLocalizations.of(context)!.resetAndSelectNewFile,
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _allSummaries = null;
                      _statusMessage = '';
                    });
                  },
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: hasData
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(child: WelcomePlaceholder(
                        isLoading: _isLoading,
                        statusMessage: _statusMessage,
                        onPickFile: _pickAndAnalyze,
                      )),
                    ),
            ),
          ),
          if (hasData)
            ..._buildDashboardSlivers(_allSummaries![_selectedYear]!),
        ],
      ),
    );
  }

  String _displayYearLabel(String year) {
    final l10n = AppLocalizations.of(context)!;
    if (year == l10n.allTime || year == 'All Time' || year == '所有时间') {
      return l10n.allTime;
    }
    return year;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(220),
        ),
      ),
    );
  }

  List<Widget> _buildDashboardSlivers(Map<String, dynamic> summary) {
    final l10n = AppLocalizations.of(context)!;
    final cfg = ConfigService();
    final topTracksCount = cfg.getInt('top_tracks_count', 10);
    final topArtistsCount = cfg.getInt('top_artists_count', 10);
    final topAlbumsCount = cfg.getInt('top_albums_count', 10);
    final monthlyPreviewCount = cfg.getInt('monthly_preview_count', 10);
    final coreItems = loadCoreNumbersConfig();
    final visibleCoreItems = coreItems.where((e) => e.value).toList();

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(l10n.sectionCoreNumbers),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  double width = constraints.maxWidth;
                  if (width > 1000) {
                    crossAxisCount = 4;
                  } else if (width > 700) {
                    crossAxisCount = 3;
                  }
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: crossAxisCount == 4 ? 1.4 : (crossAxisCount == 3 ? 1.25 : 1.15),
                    children: visibleCoreItems.map((item) => _buildStatCard(item.key, summary, l10n)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(l10n.sectionTopLists),
              if (summary['most_played'] != null && (summary['most_played'] as Map).isNotEmpty)
                TopListSection(title: l10n.annualTopTracks(topTracksCount), data: summary['most_played'], icon: Icons.music_note, iconColor: Colors.blue, type: 'track', detailsMap: summary['track_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact'], maxItems: topTracksCount),
              if (summary['top_artists'] != null && (summary['top_artists'] as Map).isNotEmpty)
                TopListSection(title: l10n.annualTopArtists(topArtistsCount), data: summary['top_artists'], icon: Icons.person, iconColor: Colors.purple, type: 'artist', detailsMap: summary['artist_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact'], maxItems: topArtistsCount),
              if (summary['top_albums'] != null && (summary['top_albums'] as Map).isNotEmpty)
                TopListSection(title: l10n.annualTopAlbums(topAlbumsCount), data: summary['top_albums'], icon: Icons.album, iconColor: Colors.deepOrange, type: 'album', detailsMap: summary['album_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact'], maxItems: topAlbumsCount),
              if (summary['monthly_top_song'] != null && (summary['monthly_top_song'] as Map).isNotEmpty)
                MonthlyTopSongPreview(data: summary['monthly_top_song'], monthlyRankings: summary['monthly_rankings'], trackDetails: summary['track_details'], allTrackCompact: summary['all_track_compact'], maxPreview: monthlyPreviewCount),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(l10n.sectionTimeDimension),
              if (summary['listening_periods'] != null)
                 PeriodsCard(periods: summary['listening_periods']),
              const SizedBox(height: 16),
              if (summary['weekly_pattern'] != null)
                 WeeklyCard(weekly: summary['weekly_pattern']),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(l10n.sectionHighlights),
              if (summary['single_day_repeat_max'] != null && summary['single_day_repeat_max']['count'] > 0)
                HighlightCard(
                  title: l10n.highlightRepeatTitle,
                  subtitle: _normalizeNewlines(l10n.highlightRepeatBody(
                    summary['single_day_repeat_max']['count'].toString(),
                    summary['single_day_repeat_max']['date'].toString(),
                    summary['single_day_repeat_max']['track'].toString(),
                  )),
                  icon: Icons.repeat_one_rounded,
                  color: Colors.indigo,
                  trackName: summary['single_day_repeat_max']['track'].toString(),
                  trackDetails: summary['track_details'],
                  allTrackCompact: summary['all_track_compact'],
                ),
              const SizedBox(height: 16),
              if (summary['latest_night_song'] != null && summary['latest_night_song']['time'] != "")
                HighlightCard(
                  title: l10n.latestNightTitle,
                  subtitle: _normalizeNewlines(l10n.latestNightBody(
                    summary['latest_night_song']['time'].toString(),
                    summary['latest_night_song']['track'].toString(),
                  )),
                  icon: Icons.nights_stay_rounded,
                  color: Colors.deepPurple,
                  trackName: summary['latest_night_song']['track'].toString(),
                  trackDetails: summary['track_details'],
                  allTrackCompact: summary['all_track_compact'],
                ),
              const SizedBox(height: 16),
              if (summary['most_immersive_day'] != null && summary['most_immersive_day']['count'] > 0)
                HighlightCard(
                  title: l10n.mostImmersiveTitle,
                  subtitle: _normalizeNewlines(l10n.mostImmersiveBody(
                    summary['most_immersive_day']['count'].toString(),
                    summary['most_immersive_day']['date'].toString(),
                  )),
                  icon: Icons.headphones_rounded,
                  color: Colors.pink,
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(l10n.sectionPlayHistoryTrend),
              Container(
                height: 300,
                padding: const EdgeInsets.all(20.0),
                decoration: namidaCardDecoration(context, borderRadius: 16),
                child: InteractiveLineChart(historyData: summary['play_history_by_date'] ?? {}),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  StatCard _buildStatCard(String key, Map<String, dynamic> summary, AppLocalizations l10n) {
    switch (key) {
      case 'total_hours':
        return StatCard(title: l10n.statTotalListening, value: '${summary['total_hours'] ?? '0'} ${l10n.hoursUnit}', icon: Icons.timer_rounded, color: Colors.blue);
      case 'total_days':
        return StatCard(title: l10n.statListeningCompanion, value: '${summary['total_days'] ?? '0'} ${l10n.daysUnit}', icon: Icons.calendar_month_rounded, color: Colors.teal);
      case 'avg_daily_minutes':
        return StatCard(title: l10n.statAvgDaily, value: '${summary['avg_daily_minutes'] ?? '0'} ${l10n.minutesUnit}', icon: Icons.hourglass_bottom_rounded, color: Colors.cyan);
      case 'total_plays':
        return StatCard(title: l10n.statTotalPlays, value: '${summary['total_plays'] ?? '0'} ${l10n.playsSuffix}', icon: Icons.play_circle_fill_rounded, color: Colors.green);
      case 'unique_tracks':
        return StatCard(title: l10n.statUniqueTracks, value: '${summary['unique_tracks'] ?? '0'} ${l10n.tracksUnit}', icon: Icons.library_music_rounded, color: Colors.orange);
      case 'unique_artists':
        return StatCard(title: l10n.statUniqueArtists, value: '${summary['unique_artists'] ?? '0'} ${l10n.artistsUnit}', icon: Icons.mic_rounded, color: Colors.purple);
      case 'unique_albums':
        return StatCard(title: l10n.statUniqueAlbums, value: '${summary['unique_albums'] ?? '0'} ${l10n.albumsUnit}', icon: Icons.album_rounded, color: Colors.deepOrange);
      case 'favorite_genre':
        return StatCard(title: l10n.statFavoriteGenre, value: '${summary['favorite_genre'] ?? l10n.unknownLabel}', icon: Icons.category_rounded, color: Colors.pink);
      default:
        return StatCard(title: key, value: '?', icon: Icons.help_outline, color: Colors.grey);
    }
  }
}
