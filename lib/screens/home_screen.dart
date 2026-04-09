import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

import '../services/analysis_service.dart';
import '../services/config_service.dart';
import '../services/track_detail_resolver.dart';
import '../widgets/interactive_line_chart.dart';
import 'full_list_screen.dart';
import 'track_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'album_detail_screen.dart';

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
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.settingsTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l10n.optionalPath}:'),
                  const SizedBox(height: 8),
                  Text(
                    l10n.metadataExtraction,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                        setState(() {
                          _musicDirectory = selectedDirectory;
                        });
                        ConfigService().set('music_directory', selectedDirectory);
                        setDialogState(() {});
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(_musicDirectory == null 
                      ? l10n.chooseMusicFolder 
                      : '...${_musicDirectory!.length > 20 ? _musicDirectory!.substring(_musicDirectory!.length - 20) : _musicDirectory}'),
                  ),
                  if (_musicDirectory != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _musicDirectory = null;
                        });
                        ConfigService().remove('music_directory');
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(l10n.clearPath),
                    ),
                  ],
                  const Divider(height: 32),
                  if (!kIsWeb && !Platform.isAndroid) ...[
                  Text('${l10n.namidaPathLabel}:'),
                  const SizedBox(height: 8),
                  Text(
                    l10n.namidaPathHint,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['exe'],
                      );
                      if (result != null && result.files.single.path != null) {
                        final path = result.files.single.path!;
                        setState(() {
                          _namidaPath = path;
                        });
                        ConfigService().set('namida_path', path);
                        setDialogState(() {});
                      }
                    },
                    icon: const Icon(Icons.music_note_rounded),
                    label: Text(_namidaPath == null
                      ? l10n.chooseNamidaExe
                      : '...${_namidaPath!.length > 20 ? _namidaPath!.substring(_namidaPath!.length - 20) : _namidaPath}'),
                  ),
                  if (_namidaPath != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _namidaPath = null;
                        });
                        ConfigService().remove('namida_path');
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(l10n.clearPath),
                    ),
                  ],
                  ],
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.language, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.language),
                      const Spacer(),
                      DropdownButton<Locale>(
                        value: Provider.of<LocaleProvider>(context, listen: false).locale,
                        items: [
                          DropdownMenuItem(
                            value: const Locale('zh'),
                            child: Text(l10n.chinese),
                          ),
                          DropdownMenuItem(
                            value: const Locale('en'),
                            child: Text(l10n.english),
                          ),
                        ],
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            Provider.of<LocaleProvider>(context, listen: false).setLocale(newLocale);
                            setDialogState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.done),
                ),
              ],
            );
          },
        );
      },
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
                  ? _buildDashboard(_allSummaries![_selectedYear]!)
                  : SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(child: _buildPlaceholder()),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.analytics_rounded, size: 80, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context)!.welcomeMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage.isNotEmpty ? _statusMessage : AppLocalizations.of(context)!.chooseBackupZip,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isLoading ? null : _pickAndAnalyze,
              icon: const Icon(Icons.file_open),
              label: Text(AppLocalizations.of(context)!.selectBackupZip, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
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

  Widget _buildDashboard(Map<String, dynamic> summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
                   _buildStatCard(AppLocalizations.of(context)!.statTotalListening, '${summary['total_hours'] ?? '0'} ${AppLocalizations.of(context)!.hoursUnit}', Icons.timer_rounded, Colors.blue),
                   _buildStatCard(AppLocalizations.of(context)!.statListeningCompanion, '${summary['total_days'] ?? '0'} ${AppLocalizations.of(context)!.daysUnit}', Icons.calendar_month_rounded, Colors.teal),
                   _buildStatCard(AppLocalizations.of(context)!.statAvgDaily, '${summary['avg_daily_minutes'] ?? '0'} ${AppLocalizations.of(context)!.minutesUnit}', Icons.hourglass_bottom_rounded, Colors.cyan),
                   _buildStatCard(AppLocalizations.of(context)!.statTotalPlays, '${summary['total_plays'] ?? '0'} ${AppLocalizations.of(context)!.playsSuffix}', Icons.play_circle_fill_rounded, Colors.green),
                   _buildStatCard(AppLocalizations.of(context)!.statUniqueTracks, '${summary['unique_tracks'] ?? '0'} ${AppLocalizations.of(context)!.tracksUnit}', Icons.library_music_rounded, Colors.orange),
                   _buildStatCard(AppLocalizations.of(context)!.statUniqueArtists, '${summary['unique_artists'] ?? '0'} ${AppLocalizations.of(context)!.artistsUnit}', Icons.mic_rounded, Colors.purple),
                   _buildStatCard(AppLocalizations.of(context)!.statUniqueAlbums, '${summary['unique_albums'] ?? '0'} ${AppLocalizations.of(context)!.albumsUnit}', Icons.album_rounded, Colors.deepOrange),
                   _buildStatCard(AppLocalizations.of(context)!.statFavoriteGenre, '${summary['favorite_genre'] ?? AppLocalizations.of(context)!.unknownLabel}', Icons.category_rounded, Colors.pink),
                ]
              );
            },
          ),
          const SizedBox(height: 48),

          _buildSectionTitle(AppLocalizations.of(context)!.sectionTopLists),
          if (summary['most_played'] != null && (summary['most_played'] as Map).isNotEmpty)
            _buildListSection(AppLocalizations.of(context)!.annualTopTracks, summary['most_played'], Icons.music_note, Colors.blue, type: 'track', detailsMap: summary['track_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact']),
          if (summary['top_artists'] != null && (summary['top_artists'] as Map).isNotEmpty)
            _buildListSection(AppLocalizations.of(context)!.annualTopArtists, summary['top_artists'], Icons.person, Colors.purple, type: 'artist', detailsMap: summary['artist_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact']),
          if (summary['top_albums'] != null && (summary['top_albums'] as Map).isNotEmpty)
            _buildListSection(AppLocalizations.of(context)!.annualTopAlbums, summary['top_albums'], Icons.album, Colors.deepOrange, type: 'album', detailsMap: summary['album_details'], trackDetailsMap: summary['track_details'], allTrackCompact: summary['all_track_compact']),
          if (summary['monthly_top_song'] != null && (summary['monthly_top_song'] as Map).isNotEmpty)
            _buildMonthlyTopSongMap(summary['monthly_top_song'], summary['track_details'], summary['all_track_compact']),
          const SizedBox(height: 32),

          _buildSectionTitle(AppLocalizations.of(context)!.sectionTimeDimension),
          if (summary['listening_periods'] != null)
             _buildPeriodsCard(summary['listening_periods']),
          const SizedBox(height: 16),
          if (summary['weekly_pattern'] != null)
             _buildWeeklyCard(summary['weekly_pattern']),
          const SizedBox(height: 48),

          _buildSectionTitle(AppLocalizations.of(context)!.sectionHighlights),
          if (summary['single_day_repeat_max'] != null && summary['single_day_repeat_max']['count'] > 0)
            _buildHighlightCard(
              AppLocalizations.of(context)!.highlightRepeatTitle,
              _normalizeNewlines(AppLocalizations.of(context)!.highlightRepeatBody(
                summary['single_day_repeat_max']['count'].toString(),
                summary['single_day_repeat_max']['date'].toString(),
                summary['single_day_repeat_max']['track'].toString(),
              )),
              Icons.repeat_one_rounded,
              Colors.indigo,
              trackName: summary['single_day_repeat_max']['track'].toString(),
              trackDetails: summary['track_details'],
              allTrackCompact: summary['all_track_compact'],
            ),
          const SizedBox(height: 16),
          if (summary['latest_night_song'] != null && summary['latest_night_song']['time'] != "")
            _buildHighlightCard(
              AppLocalizations.of(context)!.latestNightTitle,
              _normalizeNewlines(AppLocalizations.of(context)!.latestNightBody(
                summary['latest_night_song']['time'].toString(),
                summary['latest_night_song']['track'].toString(),
              )),
              Icons.nights_stay_rounded,
              Colors.deepPurple,
              trackName: summary['latest_night_song']['track'].toString(),
              trackDetails: summary['track_details'],
              allTrackCompact: summary['all_track_compact'],
            ),
          const SizedBox(height: 16),
          if (summary['most_immersive_day'] != null && summary['most_immersive_day']['count'] > 0)
            _buildHighlightCard(
              AppLocalizations.of(context)!.mostImmersiveTitle,
              _normalizeNewlines(AppLocalizations.of(context)!.mostImmersiveBody(
                summary['most_immersive_day']['count'].toString(),
                summary['most_immersive_day']['date'].toString(),
              )),
              Icons.headphones_rounded,
              Colors.pink
            ),
          const SizedBox(height: 48),

          _buildSectionTitle(AppLocalizations.of(context)!.sectionPlayHistoryTrend),
          Container(
            height: 300,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InteractiveLineChart(historyData: summary['play_history_by_date'] ?? {}),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, Map<dynamic, dynamic> data, IconData icon, Color iconColor, {String type = 'none', Map<dynamic, dynamic>? detailsMap, Map<dynamic, dynamic>? trackDetailsMap, Map<dynamic, dynamic>? allTrackCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             TextButton(
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (ctx) => FullListScreen(title: title.replaceAll(' Top 10', ''), data: data, icon: icon, type: type, detailsMap: detailsMap, trackDetailsMap: trackDetailsMap, allTrackCompact: allTrackCompact)));
               },
               child: Text(AppLocalizations.of(context)!.viewFullList, style: const TextStyle(fontWeight: FontWeight.bold)),
             ),
          ]
        ),
        const SizedBox(height: 12),
        _buildTopList(data, icon: icon, type: type, detailsMap: detailsMap, trackDetailsMap: trackDetailsMap, allTrackCompact: allTrackCompact),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMonthlyTopSongMap(Map<dynamic, dynamic> data, Map<dynamic, dynamic>? trackDetails, Map<dynamic, dynamic>? allTrackCompact) {
    final sortedKeys = data.keys.toList()..sort();
    final int maxPreview = 12;
    final bool needsTruncation = sortedKeys.length > maxPreview;
    final displayKeys = needsTruncation ? sortedKeys.sublist(sortedKeys.length - maxPreview) : sortedKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.monthlyTopSong, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              if (needsTruncation)
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => _MonthlyTopSongFullScreen(data: data, trackDetails: trackDetails, allTrackCompact: allTrackCompact)));
                  },
                  child: Text(AppLocalizations.of(context)!.viewFullList, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayKeys.length,
            separatorBuilder: (_, __) => Divider(
              height: 1, 
              indent: 72, 
              endIndent: 20, 
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)
            ),
            itemBuilder: (context, index) {
              final key = displayKeys[index];
              final monthStr = key.toString().substring(5); // e.g., "01" from "2023-01"
              final trackName = data[key].toString();
                  return ListTile(
                onTap: () {
                  final details = resolveTrackDetail(trackName, trackDetails, allTrackCompact);
                  if (details != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noTrackDetails)));
                  }
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    monthStr, 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer, 
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
                title: Text(
                  trackName, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(key.toString(), style: const TextStyle(fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPeriodsCard(Map<dynamic, dynamic> periods) {
    final normalized = <String, int>{};
    periods.forEach((key, value) {
      normalized[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
    });

    final sortedEntries = normalized.entries.toList()
      ..sort((a, b) {
        int hourOf(String key) {
          final match = RegExp(r'^(\d{1,2})').firstMatch(key);
          if (match == null) return 999;
          return int.tryParse(match.group(1) ?? '') ?? 999;
        }

        return hourOf(a.key).compareTo(hourOf(b.key));
      });

    final chartData = <String, int>{};
    for (final entry in sortedEntries) {
      chartData[entry.key] = entry.value;
    }
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.periodDistributionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: InteractiveLineChart(
              historyData: chartData,
              enablePanZoom: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(Map<dynamic, dynamic> weekly) {
    int maxVal = weekly.values.fold(0, (prev, val) => val > prev ? val : prev);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.weeklyPatternTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          for (var d in days)
            _buildSimpleBar(
              d == 'Mon' ? AppLocalizations.of(context)!.weekMon :
              d == 'Tue' ? AppLocalizations.of(context)!.weekTue :
              d == 'Wed' ? AppLocalizations.of(context)!.weekWed :
              d == 'Thu' ? AppLocalizations.of(context)!.weekThu :
              d == 'Fri' ? AppLocalizations.of(context)!.weekFri :
              d == 'Sat' ? AppLocalizations.of(context)!.weekSat :
              AppLocalizations.of(context)!.weekSun,
              weekly[d] ?? 0,
              maxVal,
              Colors.teal
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleBar(String label, int value, int maxVal, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 72, 
            child: Text(
              label, 
              style: TextStyle(
                fontWeight: FontWeight.w600, 
                color: Theme.of(context).colorScheme.onSurfaceVariant
              )
            )
          ),
          Expanded(
            child: Container(
              height: 12, 
              decoration: BoxDecoration(
                color: color.withAlpha(20), 
                borderRadius: BorderRadius.circular(6)
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = maxVal == 0 ? 0 : (value / maxVal) * constraints.maxWidth;
                    return Container(
                      width: width,
                      height: 12, 
                      decoration: BoxDecoration(
                        color: color, 
                        borderRadius: BorderRadius.circular(6)
                      )
                    );
                  }
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 56, 
            child: Text(
              '$value ${AppLocalizations.of(context)!.playsSuffix}', 
              textAlign: TextAlign.right, 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(String title, String subtitle, IconData icon, Color color, {String? trackName, Map<dynamic, dynamic>? trackDetails, Map<dynamic, dynamic>? allTrackCompact}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(40), color.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: trackName != null ? () {
            final details = resolveTrackDetail(trackName, trackDetails, allTrackCompact);
            if (details != null) {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
            } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noTrackDetails)));
            }
          } : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(50), 
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20, 
                        color: color,
                        letterSpacing: 0.5,
                      )
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle, 
                      style: TextStyle(
                        height: 1.6, 
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const Spacer(),
              Text(
                title, 
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value, 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900, 
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopList(Map<dynamic, dynamic> mostPlayed, {IconData icon = Icons.music_note, String type = 'none', Map<dynamic, dynamic>? detailsMap, Map<dynamic, dynamic>? trackDetailsMap, Map<dynamic, dynamic>? allTrackCompact, int maxItems = 10}) {
    if (mostPlayed.isEmpty) {
      return const Text('No data available.');
    }

    final sortedEntries = mostPlayed.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));

    final displayEntries = sortedEntries.take(maxItems).toList();

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayEntries.length,
        separatorBuilder: (_, __) => Divider(
          height: 1, 
          indent: 64, 
          endIndent: 20, 
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)
        ),
        itemBuilder: (context, index) {
          final entry = displayEntries[index];
          final rank = index + 1;
          Color rankColor;
          if (rank == 1) rankColor = Colors.amber;
          else if (rank == 2) rankColor = Colors.grey.shade400;
          else if (rank == 3) rankColor = Colors.brown.shade300;
          else rankColor = Theme.of(context).colorScheme.onSurfaceVariant;

          return ListTile(
            onTap: type != 'none' ? () {
              final name = entry.key.toString();
              final details = resolveTrackDetail(name, detailsMap, allTrackCompact);
              
              if (details != null) {
                if (type == 'track') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: name, details: details)));
                } else if (type == 'artist') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => ArtistDetailScreen(artistName: name, details: details, trackDetails: trackDetailsMap, allTrackCompact: allTrackCompact)));
                } else if (type == 'album') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => AlbumDetailScreen(albumName: name, details: details, trackDetails: trackDetailsMap, allTrackCompact: allTrackCompact)));
                }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.noItemDetails)));
                }
            } : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 20 : 16,
                        fontWeight: rank <= 3 ? FontWeight.w900 : FontWeight.w600,
                        color: rankColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildCoverThumbnail(entry.key.toString(), detailsMap, icon, 40),
              ],
            ),
            title: Text(
              entry.key.toString(), 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis, 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${entry.value} ${AppLocalizations.of(context)!.playsSuffix}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.onPrimaryContainer, 
                  fontSize: 13
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoverThumbnail(String name, Map<dynamic, dynamic>? detailsMap, IconData fallbackIcon, double size) {
    final details = detailsMap?[name];
    final String coverPath = details?['cover']?.toString() ?? '';
    final bool hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasCover
          ? Image.file(
              File(coverPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(fallbackIcon, size: size * 0.5, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            )
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(fallbackIcon, size: size * 0.5, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
    );
  }
}

class _MonthlyTopSongFullScreen extends StatelessWidget {
  final Map<dynamic, dynamic> data;
  final Map<dynamic, dynamic>? trackDetails;
  final Map<dynamic, dynamic>? allTrackCompact;

  const _MonthlyTopSongFullScreen({
    required this.data,
    this.trackDetails,
    this.allTrackCompact,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monthlyTopSong, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: sortedKeys.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          endIndent: 20,
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
        ),
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final monthStr = key.toString().substring(5);
          final trackName = data[key].toString();
          return ListTile(
            onTap: () {
              final details = resolveTrackDetail(trackName, trackDetails, allTrackCompact);
              if (details != null) {
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noTrackDetails)));
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                monthStr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              trackName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(key.toString(), style: const TextStyle(fontSize: 13)),
            ),
          );
        },
      ),
    );
  }
}
