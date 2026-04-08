import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/config_service.dart';
import '../widgets/interactive_line_chart.dart';

class TrackDetailScreen extends StatelessWidget {
  final String trackName;
  final Map<dynamic, dynamic> details;

  const TrackDetailScreen({
    super.key,
    required this.trackName,
    required this.details,
  });

  Future<void> _playTrack(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localPath = details['localPath']?.toString() ?? '';

    if (localPath.isEmpty || !File(localPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileNotFound)),
      );
      return;
    }

    final namidaPath = ConfigService().get('namida_path');
    try {
      if (namidaPath != null && namidaPath.isNotEmpty && File(namidaPath).existsSync()) {
        await Process.start(namidaPath, [localPath]);
      } else {
        await Process.run('cmd', ['/c', 'start', '""', localPath]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.launchFailed}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPlays = details['total_plays'] ?? 0;
    final String coverPath = details['cover']?.toString() ?? '';
    final bool hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();

    final String localPath = details['localPath']?.toString() ?? '';
    final bool hasLocalFile = localPath.isNotEmpty && File(localPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(trackName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (hasLocalFile)
            IconButton(
              tooltip: AppLocalizations.of(context)!.playInNamida,
              icon: const Icon(Icons.play_circle_outline_rounded),
              onPressed: () => _playTrack(context),
            ),
        ],
      ),
      floatingActionButton: hasLocalFile
          ? FloatingActionButton.extended(
              onPressed: () => _playTrack(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(AppLocalizations.of(context)!.playInNamida),
            )
          : null,
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
                  if (hasCover)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(coverPath),
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.music_note_rounded, size: 80, color: Colors.blue),
                      ),
                    )
                  else
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
                        '$totalPlays ${AppLocalizations.of(context)!.playsSuffix}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(AppLocalizations.of(context)!.historyTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTimeRow(context, AppLocalizations.of(context)!.firstPlayLabel, details['first_play']?.toString() ?? AppLocalizations.of(context)!.unknownLabel, Icons.fiber_new_rounded, Colors.green),
                    const Divider(height: 24),
                    _buildTimeRow(context, AppLocalizations.of(context)!.lastPlayLabel, details['last_play']?.toString() ?? AppLocalizations.of(context)!.unknownLabel, Icons.update_rounded, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text(AppLocalizations.of(context)!.playTrend, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
