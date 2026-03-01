import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  String _statusMessage = 'Choose a Namida Backup ZIP file to begin';
  Map<String, dynamic>? _allSummaries;
  String _selectedYear = '所有时间';
  String? _musicDirectory;

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('设置 (Settings)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('可选配置 (Optional Path):'),
                  const SizedBox(height: 8),
                  const Text(
                    '匹配本地音乐文件以补充元数据信息 (Metadata extraction)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                      if (selectedDirectory != null) {
                        setState(() {
                          _musicDirectory = selectedDirectory;
                        });
                        setDialogState(() {});
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(_musicDirectory == null 
                      ? '选择音乐文件夹 (Select Music Folder)' 
                      : '...${_musicDirectory!.length > 20 ? _musicDirectory!.substring(_musicDirectory!.length - 20) : _musicDirectory}'),
                  ),
                  if (_musicDirectory != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _musicDirectory = null;
                        });
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('清除路径 (Clear path)'),
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('完成 (Done)'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndAnalyze() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        String zipPath = result.files.single.path!;
        setState(() {
          _isLoading = true;
          _statusMessage = 'Extracting and analyzing...\nThis may take a moment.';
          _allSummaries = null;
        });

        // Resolve absolute path to python script
        final scriptPath = 'scripts/run_analysis.py';
        
        List<String> args = [scriptPath, zipPath];
        if (_musicDirectory != null) {
          args.add(_musicDirectory!);
        }
        
        final processResult = await Process.run('python', args);

        if (processResult.exitCode != 0) {
          throw Exception('Python Exit Code ${processResult.exitCode}\nError: ${processResult.stderr}');
        }

        final rawOutput = processResult.stdout.toString().trim();
        if (rawOutput.isEmpty) {
          throw Exception('No output returned from the script. Check python environment.');
        }

        String jsonText = rawOutput;
        final startIdx = rawOutput.indexOf('{');
        final endIdx = rawOutput.lastIndexOf('}');
        if (startIdx != -1 && endIdx != -1) {
          jsonText = rawOutput.substring(startIdx, endIdx + 1);
        }

        final parsed = jsonDecode(jsonText);
        if (parsed['success'] == true) {
          setState(() {
            _allSummaries = Map<String, dynamic>.from(parsed['summaries']);
            
            // Default select the broadest dataset if available
            if (_allSummaries != null && _allSummaries!.containsKey('所有时间')) {
              _selectedYear = '所有时间';
            } else if (_allSummaries != null && _allSummaries!.isNotEmpty) {
              _selectedYear = _allSummaries!.keys.first;
            }
            
            _statusMessage = 'Analysis complete!';
          });
        } else {
          throw Exception(parsed['error'] ?? 'Unknown error occurred in script');
        }
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        _statusMessage = 'An error occurred during analysis.';
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
            title: const Text('Namida History', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              year,
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
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onPressed: _showSettingsDialog,
              ),
              if (hasData)
                IconButton(
                  tooltip: 'Reset and select new file',
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _allSummaries = null;
                      _statusMessage = 'Choose a Namida Backup ZIP file to begin';
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
              'Welcome to Namida Analyzer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _statusMessage,
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
              label: const Text('Select Backup ZIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
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
          _buildSectionTitle('1. 核心数字 (全年轮廓)'),
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
                   _buildStatCard('听歌总计', '${summary['total_hours'] ?? '0'} 小时', Icons.timer_rounded, Colors.blue),
                   _buildStatCard('听歌陪伴', '${summary['total_days'] ?? '0'} 天', Icons.calendar_month_rounded, Colors.teal),
                   _buildStatCard('日均时长', '${summary['avg_daily_minutes'] ?? '0'} 分钟', Icons.hourglass_bottom_rounded, Colors.cyan),
                   _buildStatCard('累计播放', '${summary['total_plays'] ?? '0'} 次', Icons.play_circle_fill_rounded, Colors.green),
                   _buildStatCard('探索单曲', '${summary['unique_tracks'] ?? '0'} 首', Icons.library_music_rounded, Colors.orange),
                   _buildStatCard('探索歌手', '${summary['unique_artists'] ?? '0'} 位', Icons.mic_rounded, Colors.purple),
                   _buildStatCard('探索专辑', '${summary['unique_albums'] ?? '0'} 张', Icons.album_rounded, Colors.deepOrange),
                   _buildStatCard('最爱流派', '${summary['favorite_genre'] ?? '未知'}', Icons.category_rounded, Colors.pink),
                ]
              );
            },
          ),
          const SizedBox(height: 48),

          _buildSectionTitle('2. 年度排行榜'),
          if (summary['most_played'] != null && (summary['most_played'] as Map).isNotEmpty)
            _buildListSection('年度最爱单曲 Top 10', summary['most_played'], Icons.music_note, Colors.blue, type: 'track', detailsMap: summary['track_details']),
          if (summary['top_artists'] != null && (summary['top_artists'] as Map).isNotEmpty)
            _buildListSection('年度最爱歌手 Top 10', summary['top_artists'], Icons.person, Colors.purple, type: 'artist', detailsMap: summary['artist_details']),
          if (summary['top_albums'] != null && (summary['top_albums'] as Map).isNotEmpty)
            _buildListSection('年度最爱专辑 Top 10', summary['top_albums'], Icons.album, Colors.deepOrange, type: 'album', detailsMap: summary['album_details']),
          if (summary['monthly_top_song'] != null && (summary['monthly_top_song'] as Map).isNotEmpty)
            _buildMonthlyTopSongMap(summary['monthly_top_song'], summary['track_details']),
          const SizedBox(height: 32),

          _buildSectionTitle('3. 时间维度与听歌作息'),
          if (summary['listening_periods'] != null)
             _buildPeriodsCard(summary['listening_periods']),
          const SizedBox(height: 16),
          if (summary['weekly_pattern'] != null)
             _buildWeeklyCard(summary['weekly_pattern']),
          const SizedBox(height: 48),

          _buildSectionTitle('4. 高光与极值时刻'),
          if (summary['single_day_repeat_max'] != null && summary['single_day_repeat_max']['count'] > 0)
            _buildHighlightCard(
              '执念时刻：单曲循环之最', 
              '【${summary['single_day_repeat_max']['date']}】这一天一定很特别，\n你把《${summary['single_day_repeat_max']['track']}》单曲循环了 ${summary['single_day_repeat_max']['count']} 遍。',
              Icons.repeat_one_rounded,
              Colors.indigo,
              trackName: summary['single_day_repeat_max']['track'].toString(),
              trackDetails: summary['track_details']
            ),
          const SizedBox(height: 16),
          if (summary['latest_night_song'] != null && summary['latest_night_song']['time'] != "")
            _buildHighlightCard(
              '最晚的夜', 
              '全年在凌晨最晚的一次听歌是 ${summary['latest_night_song']['time']}，\n这首歌是《${summary['latest_night_song']['track']}》。',
              Icons.nights_stay_rounded,
              Colors.deepPurple,
              trackName: summary['latest_night_song']['track'].toString(),
              trackDetails: summary['track_details']
            ),
          const SizedBox(height: 16),
          if (summary['most_immersive_day'] != null && summary['most_immersive_day']['count'] > 0)
            _buildHighlightCard(
              '最沉浸的一天', 
              '【${summary['most_immersive_day']['date']}】 是你在音乐里最沉浸的一天，\n全天一共播放了 ${summary['most_immersive_day']['count']} 次。',
              Icons.headphones_rounded,
              Colors.pink
            ),
          const SizedBox(height: 48),

          _buildSectionTitle('播放历史趋势'),
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

  Widget _buildListSection(String title, Map<dynamic, dynamic> data, IconData icon, Color iconColor, {String type = 'none', Map<dynamic, dynamic>? detailsMap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
             TextButton(
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (ctx) => FullListScreen(title: title.replaceAll(' Top 10', ''), data: data, icon: icon, type: type, detailsMap: detailsMap)));
               },
               child: const Text('查看总榜', style: TextStyle(fontWeight: FontWeight.bold)),
             ),
          ]
        ),
        const SizedBox(height: 12),
        _buildTopList(data, icon: icon, type: type, detailsMap: detailsMap),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMonthlyTopSongMap(Map<dynamic, dynamic> data, Map<dynamic, dynamic>? trackDetails) {
    final sortedKeys = data.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('每月主打歌', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedKeys.length,
            separatorBuilder: (_, __) => Divider(
              height: 1, 
              indent: 72, 
              endIndent: 20, 
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)
            ),
            itemBuilder: (context, index) {
              final key = sortedKeys[index];
              final monthStr = key.toString().substring(5); // e.g., "01" from "2023-01"
              final trackName = data[key].toString();
              return ListTile(
                onTap: () {
                  final details = trackDetails?[trackName];
                  if (details != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无该单曲的详细信息')));
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
    int maxVal = periods.values.fold(0, (prev, val) => val > prev ? val : prev);
    
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
          const Text('时段分布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSimpleBar('凌晨', periods['night'] ?? 0, maxVal, Colors.indigo),
          _buildSimpleBar('上午', periods['morning'] ?? 0, maxVal, Colors.lightBlue),
          _buildSimpleBar('下午', periods['afternoon'] ?? 0, maxVal, Colors.orange),
          _buildSimpleBar('夜晚', periods['evening'] ?? 0, maxVal, Colors.deepPurple),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(Map<dynamic, dynamic> weekly) {
    int maxVal = weekly.values.fold(0, (prev, val) => val > prev ? val : prev);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labels = {'Mon': '周一', 'Tue': '周二', 'Wed': '周三', 'Thu': '周四', 'Fri': '周五', 'Sat': '周六', 'Sun': '周日'};
    
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
          const Text('一周规律', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          for (var d in days)
            _buildSimpleBar(labels[d]!, weekly[d] ?? 0, maxVal, Colors.teal),
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
            width: 48, 
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
              '$value 次', 
              textAlign: TextAlign.right, 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCard(String title, String subtitle, IconData icon, Color color, {String? trackName, Map<dynamic, dynamic>? trackDetails}) {
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
            final details = trackDetails?[trackName];
            if (details != null) {
              Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: trackName, details: details)));
            } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无该单曲的详细信息')));
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

  Widget _buildTopList(Map<dynamic, dynamic> mostPlayed, {IconData icon = Icons.music_note, String type = 'none', Map<dynamic, dynamic>? detailsMap, int maxItems = 10}) {
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
              final details = detailsMap?[name];
              
              if (details != null) {
                if (type == 'track') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => TrackDetailScreen(trackName: name, details: details)));
                } else if (type == 'artist') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => ArtistDetailScreen(artistName: name, details: details)));
                } else if (type == 'album') {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => AlbumDetailScreen(albumName: name, details: details)));
                }
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('暂无该项目详细信息')));
              }
            } : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: SizedBox(
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
                '${entry.value} 次',
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
}
