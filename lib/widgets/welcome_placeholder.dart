import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class WelcomePlaceholder extends StatelessWidget {
  final bool isLoading;
  final String statusMessage;
  final VoidCallback onPickFile;

  const WelcomePlaceholder({
    super.key,
    required this.isLoading,
    required this.statusMessage,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            Text(
              statusMessage,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.analytics_rounded, size: 72, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.welcomeMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              statusMessage.isNotEmpty ? statusMessage : l10n.chooseBackupZip,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: isLoading ? null : onPickFile,
              icon: const Icon(Icons.file_open),
              label: Text(l10n.selectBackupZip, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}
