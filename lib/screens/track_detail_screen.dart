import 'package:flutter/material.dart';
import '../widgets/interactive_line_chart.dart';

class TrackDetailScreen extends StatelessWidget {
  final String trackName;
  final Map<dynamic, dynamic> details;

  const TrackDetailScreen({
    super.key,
    required this.trackName,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final int totalPlays = details['total_plays'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(trackName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                   const Icon(Icons.music_note_rounded, size: 80, color: Colors.blue),
                   const SizedBox(height: 16),
                   Text(
                     trackName,
                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                     textAlign: TextAlign.center,
                   ),
                   if (totalPlays > 0) ...[
                     const SizedBox(height: 8),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                       decoration: BoxDecoration(
                         color: Colors.blue.withAlpha(30),
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.blue.withAlpha(50)),
                       ),
                       child: Text(
                         '累计播放 $totalPlays 次',
                         style: const TextStyle(
                           fontSize: 16, 
                           fontWeight: FontWeight.w600,
                           color: Colors.blue,
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
                    _buildTimeRow(context, '加入/首次听歌', details['first_play']?.toString() ?? '未知', Icons.fiber_new_rounded, Colors.green),
                    const Divider(height: 24),
                    _buildTimeRow(context, '最后一次听歌', details['last_play']?.toString() ?? '未知', Icons.update_rounded, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
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
