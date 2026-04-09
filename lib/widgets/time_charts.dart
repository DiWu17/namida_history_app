import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'app_styles.dart';
import 'interactive_line_chart.dart';

class PeriodsCard extends StatelessWidget {
  final Map<dynamic, dynamic> periods;

  const PeriodsCard({super.key, required this.periods});

  @override
  Widget build(BuildContext context) {
    final normalized = <String, int>{};
    periods.forEach((key, value) {
      normalized[key.toString()] = value is int ? value : int.tryParse(value.toString()) ?? 0;
    });

    final sortedEntries = normalized.entries.toList()
      ..sort((a, b) {
        int hourOf(String key) {
          final match = RegExp(r'^(\d{1,2})').firstMatch(key);
          if (match == null) return 999;
          return int.tryParse(match.group(1) ?? '') ?? 999;
        }
        return hourOf(a.key).compareTo(hourOf(b.key));
      });

    final chartData = <String, int>{};
    for (final entry in sortedEntries) {
      chartData[entry.key] = entry.value;
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.periodDistributionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: InteractiveLineChart(
              historyData: chartData,
              enablePanZoom: false,
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyCard extends StatelessWidget {
  final Map<dynamic, dynamic> weekly;

  const WeeklyCard({super.key, required this.weekly});

  @override
  Widget build(BuildContext context) {
    int maxVal = weekly.values.fold(0, (prev, val) => val > prev ? val : prev);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.weeklyPatternTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          for (var d in days)
            _buildSimpleBar(
              context,
              d == 'Mon' ? l10n.weekMon :
              d == 'Tue' ? l10n.weekTue :
              d == 'Wed' ? l10n.weekWed :
              d == 'Thu' ? l10n.weekThu :
              d == 'Fri' ? l10n.weekFri :
              d == 'Sat' ? l10n.weekSat :
              l10n.weekSun,
              weekly[d] ?? 0,
              maxVal,
              Colors.teal,
            ),
        ],
      ),
    );
  }

  Widget _buildSimpleBar(BuildContext context, String label, int value, int maxVal, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = maxVal == 0 ? 0 : (value / maxVal) * constraints.maxWidth;
                    return Container(
                      width: width,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 56,
            child: Text(
              '$value ${AppLocalizations.of(context)!.playsSuffix}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
