import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/analysis_service.dart';
import 'app_styles.dart';
import 'interactive_line_chart.dart';
import 'time_row.dart';

class DetailScreenTemplate extends StatefulWidget {
  final String title;
  final Map<dynamic, dynamic> details;
  final IconData fallbackIcon;
  final Color accentColor;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final List<Widget> extraSections;

  const DetailScreenTemplate({
    super.key,
    required this.title,
    required this.details,
    required this.fallbackIcon,
    required this.accentColor,
    this.actions,
    this.floatingActionButton,
    this.extraSections = const [],
  });

  @override
  State<DetailScreenTemplate> createState() => _DetailScreenTemplateState();
}

class _DetailScreenTemplateState extends State<DetailScreenTemplate> {
  String _dynamicCoverPath = '';
  bool _isLoadingCover = false;

  @override
  void initState() {
    super.initState();
    _loadCoverAsync();
  }

  Future<void> _loadCoverAsync() async {
    if (_isLoadingCover) return;
    setState(() => _isLoadingCover = true);
    try {
      final coverPath = await AnalysisService().extractCoverForDetailsAsync(widget.details);
      if (mounted && coverPath.isNotEmpty) {
        setState(() => _dynamicCoverPath = coverPath);
      }
    } catch (_) {
      // Ignore extraction errors
    } finally {
      if (mounted) {
        setState(() => _isLoadingCover = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPlays = widget.details['total_plays'] ?? 0;
    final String coverPath = _dynamicCoverPath.isNotEmpty
        ? _dynamicCoverPath
        : widget.details['cover']?.toString() ?? '';
    final bool hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();
    final l10n = AppLocalizations.of(context)!;
    final hasExtraSections = widget.extraSections.isNotEmpty;

    final tabs = <Widget>[
      Tab(icon: const Icon(Icons.info_outline_rounded), text: l10n.tabOverview),
      if (hasExtraSections)
        Tab(icon: const Icon(Icons.queue_music_rounded), text: l10n.tabTopSongs),
      Tab(icon: const Icon(Icons.trending_up_rounded), text: l10n.tabTrend),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          actions: widget.actions,
        ),
        floatingActionButton: widget.floatingActionButton,
        body: Column(
          children: [
            // Compact header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(100),
              ),
              child: Row(
                children: [
                  if (hasCover)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(coverPath),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        cacheWidth: 144,
                        cacheHeight: 144,
                        errorBuilder: (_, __, ___) => _buildIconBox(context),
                      ),
                    )
                  else
                    _buildIconBox(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (totalPlays > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: widget.accentColor.withAlpha(50)),
                            ),
                            child: Text(
                              '$totalPlays ${l10n.playsSuffix}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.accentColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TabBar
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                tabs: tabs,
                labelColor: widget.accentColor,
                indicatorColor: widget.accentColor,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            // TabBarView
            Expanded(
              child: TabBarView(
                children: [
                  // Overview tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.historyTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TimeRow(label: l10n.firstPlayLabel, time: widget.details['first_play']?.toString() ?? l10n.unknownLabel, icon: Icons.fiber_new_rounded, color: Colors.green),
                                const Divider(height: 24),
                                TimeRow(label: l10n.lastPlayLabel, time: widget.details['last_play']?.toString() ?? l10n.unknownLabel, icon: Icons.update_rounded, color: Colors.orange),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top Songs tab (conditional)
                  if (hasExtraSections)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.extraSections,
                      ),
                    ),
                  // Trend tab
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.playTrend, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: namidaCardDecoration(context, borderRadius: 16),
                            child: InteractiveLineChart(historyData: widget.details['history'] ?? {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: widget.accentColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(widget.fallbackIcon, size: 32, color: widget.accentColor),
    );
  }
}
