import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
import '../widgets/settings_dialog.dart';

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
    showSettingsDialog(
      context: context,
      musicDirectory: _musicDirectory,
      namidaPath: _namidaPath,
      onMusicDirectoryChanged: (val) => setState(() => _musicDirectory = val),
      onNamidaPathChanged: (val) => setState(() => _namidaPath = val),
    );
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
            if (mounted) setState(() => _statusMessage = msg);
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
            title: Text(AppLocalizations.of(context)!.namidaHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Center(
        child: Text(
          title, 
          style: const TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 0.5
          )
        ),
      ),
    );
  }

  List<Widget> _buildDashboardSlivers(Map<String, dynamic> summary) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle(AppLocalizations.of(context)!.sectionCoreNumbers),
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
                    children: [
                       StatCard(title: AppLocalizations.of(context)!.statTotalListening, value: '${summary['total_hours'] ?? '0'} ${AppLocalizations.of(context)!.hoursUnit}', icon: Icons.timer_rounded, color: Colors.blue),
                       StatCard(title: AppLocalizations.of(context)!.statListeningCompanion, value: '${summary['total_days'] ?? '0'} ${AppLocalizations.of(context)!.daysUnit}', icon: Icons.calendar_month_rounded, color: Colors.teal),
                       StatCard(title: AppLocalizations.of(context)!.statAvgDaily, value: '${summary['avg_daily_minutes'] ?? '0'} ${AppLocalizations.of(context)!.minutesUnit}', icon: Icons.hourglass_bottom_rounded, color: Colors.cyan),
                       StatCard(title: AppLocalizations.of(context)!.statTotalPlays, value: '${summary['total_plays'] ?? '0'} ${AppLocalizations.of(context)!.playsSuffix}', icon: Icons.play_circle_fill_rounded, color: Colors.green),
                       StatCard(title: AppLocalizations.of(context)!.statUniqueTracks, value: '${summary['unique_tracks'] ?? '0'} ${AppLocalizations.of(context)!.tracksUnit}', icon: Icons.library_music_rounded, color: Colors.orange),
                       StatCard(title: AppLocalizations.of(context)!.statUniqueArtists, value: '${summary['unique_artists'] ?? '0'} ${AppLocalizations.of(context)!.artistsUnit}', icon: Icons.mic_rounded, color: Colors.purple),
                       StatCard(title: AppLocalizations.of(context)!.statUniqueAlbums, value: '${summary['unique_albums'] ?? '0'} ${AppLocalizations.of(context)!.albumsUnit}', icon: Icons.album_rounded, color: Colors.deepOrange),
                       StatCard(title: AppLocalizations.of(context)!.statFavoriteGenre, value: '${summary['favorite_genre'] ?? AppLocalizations.of(context)!.unknownLabel}', icon: Icons.category_rounded, color: Colors.pink),
                    ]
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
              _buildSectionTitle(AppLocalizations.of(context)!.sectionTopLists),
              if (summary['most_played'] != null && (summary['most_played'] as Map).isNotEmpty)
                TopListSection(title: AppLocalizations.of(context)!.annualTopTracks, data: summary['most_played'], icon: Icons.music_note, iconColor: Colors.blue, type: 'track', detailsMap: summary['track_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact']),
              if (summary['top_artists'] != null && (summary['top_artists'] as Map).isNotEmpty)
                TopListSection(title: AppLocalizations.of(context)!.annualTopArtists, data: summary['top_artists'], icon: Icons.person, iconColor: Colors.purple, type: 'artist', detailsMap: summary['artist_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact']),
              if (summary['top_albums'] != null && (summary['top_albums'] as Map).isNotEmpty)
                TopListSection(title: AppLocalizations.of(context)!.annualTopAlbums, data: summary['top_albums'], icon: Icons.album, iconColor: Colors.deepOrange, type: 'album', detailsMap: summary['album_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact']),
              if (summary['monthly_top_song'] != null && (summary['monthly_top_song'] as Map).isNotEmpty)
                MonthlyTopSongPreview(data: summary['monthly_top_song'], trackDetails: summary['track_details'], allTrackCompact: summary['all_track_compact']),
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
              _buildSectionTitle(AppLocalizations.of(context)!.sectionTimeDimension),
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
              _buildSectionTitle(AppLocalizations.of(context)!.sectionHighlights),
              if (summary['single_day_repeat_max'] != null && summary['single_day_repeat_max']['count'] > 0)
                HighlightCard(
                  title: AppLocalizations.of(context)!.highlightRepeatTitle,
                  subtitle: _normalizeNewlines(AppLocalizations.of(context)!.highlightRepeatBody(
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
                  title: AppLocalizations.of(context)!.latestNightTitle,
                  subtitle: _normalizeNewlines(AppLocalizations.of(context)!.latestNightBody(
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
                  title: AppLocalizations.of(context)!.mostImmersiveTitle,
                  subtitle: _normalizeNewlines(AppLocalizations.of(context)!.mostImmersiveBody(
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
              _buildSectionTitle(AppLocalizations.of(context)!.sectionPlayHistoryTrend),
              Container(
                height: 300,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: kCardBoxShadow,
                ),
                child: InteractiveLineChart(historyData: summary['play_history_by_date'] ?? {}),
              ),
            ],
          ),
        ),
      ),
    ];
  }

}
