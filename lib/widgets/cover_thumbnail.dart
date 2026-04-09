import 'dart:io';
import 'package:flutter/material.dart';

class CoverThumbnail extends StatelessWidget {
  final String name;
  final Map<dynamic, dynamic>? detailsMap;
  final IconData fallbackIcon;
  final double size;

  const CoverThumbnail({
    super.key,
    required this.name,
    this.detailsMap,
    required this.fallbackIcon,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final details = detailsMap?[name];
    final String coverPath = details?['cover']?.toString() ?? '';
    final bool hasCover = coverPath.isNotEmpty && File(coverPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasCover
          ? Image.file(
              File(coverPath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * 2).toInt(),
              cacheHeight: (size * 2).toInt(),
              errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            )
          : _buildPlaceholder(context),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(fallbackIcon, size: size * 0.5, color: Theme.of(context).colorScheme.onPrimaryContainer),
    );
  }
}
