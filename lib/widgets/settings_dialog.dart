import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/config_service.dart';

void showSettingsDialog({
  required BuildContext context,
  required String? musicDirectory,
  required String? namidaPath,
  required ValueChanged<String?> onMusicDirectoryChanged,
  required ValueChanged<String?> onNamidaPathChanged,
}) {
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
                      onMusicDirectoryChanged(selectedDirectory);
                      ConfigService().set('music_directory', selectedDirectory);
                      setDialogState(() {});
                    }
                  },
                  icon: const Icon(Icons.folder_open),
                  label: Text(musicDirectory == null
                    ? l10n.chooseMusicFolder
                    : '...${musicDirectory!.length > 20 ? musicDirectory!.substring(musicDirectory!.length - 20) : musicDirectory}'),
                ),
                if (musicDirectory != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      onMusicDirectoryChanged(null);
                      ConfigService().remove('music_directory');
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.clear, size: 16),
                    label: Text(l10n.clearPath),
                  ),
                ],
                const Divider(height: 32),
                if (!kIsWeb) ...[
                  Text('${l10n.namidaPathLabel}:'),
                  const SizedBox(height: 8),
                  if (Platform.isAndroid) ...[
                    Text(
                      l10n.namidaAndroidHint,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
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
                      },
                      icon: const Icon(Icons.music_note_rounded),
                      label: Text(l10n.playInNamida),
                    ),
                  ] else ...[
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
                          onNamidaPathChanged(path);
                          ConfigService().set('namida_path', path);
                          setDialogState(() {});
                        }
                      },
                      icon: const Icon(Icons.music_note_rounded),
                      label: Text(namidaPath == null
                        ? l10n.chooseNamidaExe
                        : '...${namidaPath!.length > 20 ? namidaPath!.substring(namidaPath!.length - 20) : namidaPath}'),
                    ),
                    if (namidaPath != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          onNamidaPathChanged(null);
                          ConfigService().remove('namida_path');
                          setDialogState(() {});
                        },
                        icon: const Icon(Icons.clear, size: 16),
                        label: Text(l10n.clearPath),
                      ),
                    ],
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
