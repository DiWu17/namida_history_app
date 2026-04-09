import 'package:flutter/material.dart';

Color getRankColor(int rank, BuildContext context) {
  if (rank == 1) return Colors.amber;
  if (rank == 2) return Colors.grey.shade400;
  if (rank == 3) return Colors.brown.shade300;
  return Theme.of(context).colorScheme.onSurfaceVariant;
}
