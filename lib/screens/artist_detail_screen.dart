import 'package:flutter/material.dart';
import '../widgets/interactive_line_chart.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  final Map<dynamic, dynamic> details;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPlays = details['total_plays'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(artistName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                   const Icon(Icons.mic_rounded, size: 80, color: Colors.purple),
                   const SizedBox(height: 16),
                   Text(
                     artistName,
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                     textAlign: TextAlign.center,
                   ),
                   if (totalPlays > 0) ...[
                     const SizedBox(height: 8),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                       decoration: BoxDecoration(
                         color: Colors.purple.withAlpha(30),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.purple.withAlpha(50)),
                       ),
                       child: Text(
                         '累计播放 $totalPlays 次',
                         style: const TextStyle(
                           fontSize: 16, 
                           fontWeight: FontWeight.w600,
                           color: Colors.purple,
                         ),
                       ),
                     ),
                   ],
                ]
              ),
            ),
            const SizedBox(height: 32),
            const Text('历史时刻', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTimeRow(context, '首次播放', details['first_play']?.toString() ?? '未知', Icons.fiber_new_rounded, Colors.green),
                    const Divider(height: 24),
                    _buildTimeRow(context, '最后播放', details['last_play']?.toString() ?? '未知', Icons.update_rounded, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // 最爱歌曲 Top 10
            if (details['top_songs'] != null && (details['top_songs'] as Map).isNotEmpty) ...[
               const Text('歌手热歌 Top 10', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (details['top_songs'] as Map).length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1, 
                    indent: 64, 
                    endIndent: 20, 
                    color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50)
                  ),
                  itemBuilder: (context, index) {
                    final entries = (details['top_songs'] as Map).entries.toList()
                        ..sort((a, b) => (b.value as num).compareTo(a.value as num));
                    final entry = entries[index];
                    final rank = index + 1;
                    Color rankColor = Theme.of(context).colorScheme.onSurfaceVariant;
                    if (rank == 1) rankColor = Colors.amber;
                    else if (rank == 2) rankColor = Colors.grey.shade400;
                    else if (rank == 3) rankColor = Colors.brown.shade300;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: SizedBox(
                        width: 32,
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                      trailing: Text(
                        '${entry.value} 次',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).colorScheme.primary, 
                          fontSize: 13
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
            ],
            const Text('播放趋势', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
              child: InteractiveLineChart(historyData: details['history'] ?? {}),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, String label, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
