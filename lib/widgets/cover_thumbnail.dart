import 'dart:io';
import 'package:flutter/material.dart';

import '../services/analysis_service.dart';
import '../services/track_detail_resolver.dart';

class CoverThumbnail extends StatefulWidget {
  final String name;
  final Map<dynamic, dynamic>? detailsMap;
  final Map<dynamic, dynamic>? allTrackCompact;
  final IconData fallbackIcon;
  final double size;

  const CoverThumbnail({
    super.key,
    required this.name,
    this.detailsMap,
    this.allTrackCompact,
    required this.fallbackIcon,
    this.size = 40,
  });

  @override
  State<CoverThumbnail> createState() => _CoverThumbnailState();
}

class _CoverThumbnailState extends State<CoverThumbnail> {
  String _dynamicCoverPath = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCoverIfNeeded();
  }

  @override
  void didUpdateWidget(covariant CoverThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name ||
        oldWidget.detailsMap != widget.detailsMap ||
        oldWidget.allTrackCompact != widget.allTrackCompact) {
      _dynamicCoverPath = '';
      _loadCoverIfNeeded();
    }
  }

  Future<void> _loadCoverIfNeeded() async {
    if (_isLoading) return;

    final details = resolveTrackDetail(
          widget.name,
          widget.detailsMap,
          widget.allTrackCompact,
        ) ??
        widget.detailsMap?[widget.name] as Map<dynamic, dynamic>?;
    if (details == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final coverPath = await AnalysisService().extractCoverForDetailsAsync(details);
      if (!mounted || coverPath.isEmpty) {
        return;
      }
      setState(() => _dynamicCoverPath = coverPath);
    } catch (_) {
      // Ignore extraction errors in list thumbnails.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = resolveTrackDetail(
          widget.name,
          widget.detailsMap,
          widget.allTrackCompact,
        ) ??
        widget.detailsMap?[widget.name] as Map<dynamic, dynamic>?;
    final String coverPath = _dynamicCoverPath.isNotEmpty
        ? _dynamicCoverPath
        : details?['cover']?.toString() ?? '';
    final bool hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: hasCover
          ? Image.file(
              File(coverPath),
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              cacheWidth: (widget.size * 2).toInt(),
              cacheHeight: (widget.size * 2).toInt(),
              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(widget.fallbackIcon, size: widget.size * 0.5, color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}
