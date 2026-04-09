import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../l10n/app_localizations.dart';
import '../services/config_service.dart';
import '../widgets/detail_screen_template.dart';

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

    if (!kIsWeb && Platform.isAndroid) {
      try {
        await Process.run('am', [
          'start',
          '-n', 'com.msob7y.namida/.MainActivity',
        ]);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.launchFailed}: $e')),
          );
        }
      }
      return;
    }

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
    final String localPath = details['localPath']?.toString() ?? '';
    final bool hasLocalFile = (!kIsWeb && Platform.isAndroid) || (localPath.isNotEmpty && File(localPath).existsSync());

    return DetailScreenTemplate(
      title: trackName,
      details: details,
      fallbackIcon: Icons.music_note_rounded,
      accentColor: Colors.blue,
      actions: [
        if (hasLocalFile)
          IconButton(
            tooltip: AppLocalizations.of(context)!.playInNamida,
            icon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: () => _playTrack(context),
          ),
      ],
      floatingActionButton: hasLocalFile
          ? FloatingActionButton.extended(
              onPressed: () => _playTrack(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(AppLocalizations.of(context)!.playInNamida),
            )
          : null,
    );
  }
}
