import 'package:flutter/material.dart';

const kCardBoxShadow = [
  BoxShadow(
    color: Color.fromARGB(12, 0, 0, 0),
    blurRadius: 12,
    offset: Offset(0, 4),
    spreadRadius: 0,
  ),
];

const kCardBorderRadius = 14.0;
const kListCardBorderRadius = 16.0;
const kTileVerticalPadding = 4.0;

/// Builds a Namida-style tinted card decoration with alpha-blend surface color.
BoxDecoration namidaCardDecoration(BuildContext context, {double borderRadius = kCardBorderRadius}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final seedColor = isDark ? const Color(0xFF4e4c72) : const Color(0xFF9c99c1);
  return BoxDecoration(
    color: isDark
        ? Color.alphaBlend(seedColor.withAlpha(35), const Color(0xFF1a1a1a))
        : Color.alphaBlend(seedColor.withAlpha(20), Colors.white),
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: isDark ? null : kCardBoxShadow,
  );
}
