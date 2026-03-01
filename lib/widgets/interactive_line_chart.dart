import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class InteractiveLineChart extends StatefulWidget {
  final Map<dynamic, dynamic> historyData;

  const InteractiveLineChart({super.key, required this.historyData});

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  late List<String> _sortedKeys;
  late List<FlSpot> _spots;
  double _maxVal = 0;

  double _minX = 0;
  double _maxX = 10;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant InteractiveLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historyData != widget.historyData) {
      _initData();
    }
  }

  void _initData() {
    if (widget.historyData.isEmpty) {
      _spots = [];
      return;
    }

    _sortedKeys = widget.historyData.keys.map((k) => k.toString()).toList()..sort();
    _totalPoints = _sortedKeys.length;
    _spots = [];
    _maxVal = 0;
    
    for (int i = 0; i < _totalPoints; i++) {
      final key = _sortedKeys[i];
      final val = (widget.historyData[key] as num).toDouble();
      if (val > _maxVal) _maxVal = val;
      _spots.add(FlSpot(i.toDouble(), val));
    }

    _minX = 0;
    _maxX = (_totalPoints > 30 ? 30 : _totalPoints - 1).toDouble();
    if (_maxX < 0) _maxX = 0;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent e) {
        if (e is! PointerScrollEvent) return;
        if (_totalPoints == 0) return;
        
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        
        final chartWidth = size.width - 45; 
        double localDx = e.localPosition.dx - 45; 
        
        if (localDx < 0) localDx = 0;
        if (localDx > chartWidth) localDx = chartWidth;
        
        double fraction = localDx / chartWidth;
        fraction = fraction.clamp(0.0, 1.0);

        final currentSpan = _maxX - _minX;
        final hoverX = _minX + fraction * currentSpan;

        // dy > 0 滚轮向下滚动，按照你的意思放大还是缩小取决于习惯，这里设置向下滚动=缩小图形范围（放大），向上=放大图形范围（缩小）
        double zoom = e.scrollDelta.dy > 0 ? 1.2 : 0.8;
        double newSpan = currentSpan * zoom;

        if (newSpan < 4) newSpan = 4;
        if (newSpan > _totalPoints.toDouble() - 1) {
          newSpan = _totalPoints.toDouble() - 1;
        }
        if (newSpan < 0) newSpan = 0;

        double newMinX = hoverX - fraction * newSpan;
        double newMaxX = hoverX + (1.0 - fraction) * newSpan;

        if (newMinX < 0) {
          newMinX = 0;
          newMaxX = newMinX + newSpan;
        }
        if (newMaxX > _totalPoints - 1) {
          newMaxX = (_totalPoints - 1).toDouble();
          newMinX = newMaxX - newSpan;
          if (newMinX < 0) newMinX = 0;
        }

        setState(() {
          _minX = newMinX;
          _maxX = newMaxX;
        });
      });
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_totalPoints == 0) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final chartWidth = renderBox.size.width - 45;
    if (chartWidth <= 0) return;

    final currentSpan = _maxX - _minX;
    final deltaXUnits = -(details.delta.dx / chartWidth) * currentSpan;

    double newMinX = _minX + deltaXUnits;
    double newMaxX = _maxX + deltaXUnits;

    if (newMinX < 0) {
      newMinX = 0;
      newMaxX = newMinX + currentSpan;
      if (newMaxX > _totalPoints - 1) newMaxX = (_totalPoints - 1).toDouble();
    }
    if (newMaxX > _totalPoints - 1) {
      newMaxX = (_totalPoints - 1).toDouble();
      newMinX = newMaxX - currentSpan;
      if (newMinX < 0) newMinX = 0;
    }

    setState(() {
      _minX = newMinX;
      _maxX = newMaxX;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_spots.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.unknownLabel));
    }

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: GestureDetector(
        onPanUpdate: _handlePanUpdate,
        child: Container(
          color: Colors.transparent,
          child: LineChart(
            LineChartData(
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _maxVal > 5 ? _maxVal / 5 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.outlineVariant.withAlpha(50),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < _totalPoints) {
                        int currentSpan = (_maxX - _minX).ceil();
                        int step = (currentSpan / 6).clamp(1, currentSpan).ceil();
                        
                        // Always show boundary dates conditionally, but spread 6 labels evenly
                        if (index % step == 0 || index == _totalPoints - 1) {
                          String dateStr = _sortedKeys[index];
                          List<String> parts = dateStr.split('-');
                          String display = parts.length >= 3 ? '${parts[1]}-${parts[2]}' : dateStr;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: Text(
                              display,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: _maxVal > 5 ? _maxVal / 5 : 1,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == meta.max) return const SizedBox();
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: _minX,
              maxX: _maxX,
              minY: 0,
              maxY: (_maxVal * 1.2).ceilToDouble(),
              lineBarsData: [
                LineChartBarData(
                  spots: _spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withAlpha(100),
                        Theme.of(context).colorScheme.primary.withAlpha(10),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((LineBarSpot touchedSpot) {
                      int spotIndex = touchedSpot.x.toInt();
                      if (spotIndex < 0) spotIndex = 0;
                      if (spotIndex >= _totalPoints) spotIndex = _totalPoints - 1;
                      final date = _sortedKeys[spotIndex];
                      return LineTooltipItem(
                        '$date\n${touchedSpot.y.toInt()} ${AppLocalizations.of(context)!.playsSuffix}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
