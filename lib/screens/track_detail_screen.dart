import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:android_intent_plus/android_intent.dart';
import '../l10n/app_localizations.dart';
import '../services/analysis_service.dart';
import '../services/config_service.dart';
import '../widgets/detail_screen_template.dart';

class TrackDetailScreen extends StatefulWidget {
  final String trackName;
  final Map<dynamic, dynamic> details;

  const TrackDetailScreen({
    super.key,
    required this.trackName,
    required this.details,
  });

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen> {
  String _resolvedLocalPath = '';
  bool _isResolvingPath = false;

  @override
  void initState() {
    super.initState();
    _resolveLocalPath();
  }

  Future<void> _resolveLocalPath() async {
    if (_isResolvingPath) return;
    setState(() => _isResolvingPath = true);
    try {
      final resolved = await AnalysisService().resolveLocalPathForDetailsAsync(widget.details);
      if (!mounted) return;
      setState(() => _resolvedLocalPath = resolved);
    } finally {
      if (mounted) {
        setState(() => _isResolvingPath = false);
      }
    }
  }

  String get _effectiveLocalPath {
    if (_resolvedLocalPath.isNotEmpty) {
      return _resolvedLocalPath;
    }
    final localPath = widget.details['localPath']?.toString() ?? '';
    return localPath;
  }

  Future<void> _playTrack(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final localPath = _effectiveLocalPath.isNotEmpty
        ? _effectiveLocalPath
        : await AnalysisService().resolveLocalPathForDetailsAsync(widget.details);

    if (!kIsWeb && Platform.isAndroid) {
      try {
        if (localPath.isNotEmpty) {
          // Play the specific file in Namida or default player
          final intent = AndroidIntent(
            action: 'action_view',
            data: Uri.file(localPath).toString(),
            type: 'audio/*',
            package: 'com.msob7y.namida',
          );
          await intent.launch();
        } else {
          // Just open Namida
          final intent = AndroidIntent(
            action: 'action_main',
            package: 'com.msob7y.namida',
            componentName: 'com.msob7y.namida.MainActivity',
          );
          await intent.launch();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.launchFailed}: $e')),
          );
        }
      }
      return;
    }

    if (localPath.isEmpty || !File(localPath).existsSync()) {
      if (!context.mounted) {
        return;
      }
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
    final localPath = _effectiveLocalPath;
    final bool hasLocalFile = (!kIsWeb && Platform.isAndroid) ||
        (localPath.isNotEmpty && File(localPath).existsSync());

    return DetailScreenTemplate(
      title: widget.trackName,
      details: widget.details,
      fallbackIcon: Icons.music_note_rounded,
      accentColor: Colors.blue,
      actions: [
        if (hasLocalFile)
          IconButton(
            tooltip: AppLocalizations.of(context)!.playInNamida,
            icon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: () => _playTrack(context),
          ),
        if (_isResolvingPath)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
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
