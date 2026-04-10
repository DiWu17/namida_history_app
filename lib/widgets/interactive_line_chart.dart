import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';

class InteractiveLineChart extends StatefulWidget {
  final Map<dynamic, dynamic> historyData;
  final bool enablePanZoom;

  const InteractiveLineChart({
    super.key,
    required this.historyData,
    this.enablePanZoom = true,
  });

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

  static const double _leftReserved = 40.0;

  // Desktop: mouse drag-to-pan state
  bool _isDragging = false;
  Offset _dragStartPos = Offset.zero;
  double _dragStartMinX = 0;
  double _dragStartMaxX = 0;

  bool get _isDesktop {
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  bool get _isZoomed {
    if (_totalPoints <= 1) return false;
    final fullSpan = (_totalPoints - 1).toDouble();
    final currentSpan = _maxX - _minX;
    return currentSpan < fullSpan - 0.5;
  }

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
    _maxX = (_totalPoints - 1).toDouble();
    if (_maxX < 0) _maxX = 0;
  }

  // ---- Zoom / Pan helpers ----

  void _zoomBy(double factor, [double focalFraction = 0.5]) {
    if (_totalPoints <= 1) return;
    final currentSpan = _maxX - _minX;
    final focalX = _minX + focalFraction * currentSpan;
    double newSpan = currentSpan * factor;
    if (newSpan < 4) newSpan = 4;
    final maxSpan = (_totalPoints - 1).toDouble();
    if (newSpan > maxSpan) newSpan = maxSpan;

    double newMinX = focalX - focalFraction * newSpan;
    double newMaxX = focalX + (1.0 - focalFraction) * newSpan;
    _clampAndApply(newMinX, newMaxX, newSpan);
  }

  void _panBy(double fraction) {
    if (_totalPoints <= 1) return;
    final currentSpan = _maxX - _minX;
    final delta = currentSpan * fraction;
    double newMinX = _minX + delta;
    double newMaxX = _maxX + delta;
    _clampAndApply(newMinX, newMaxX, currentSpan);
  }

  void _resetZoom() {
    setState(() {
      _minX = 0;
      _maxX = (_totalPoints - 1).toDouble();
    });
  }

  void _clampAndApply(double newMinX, double newMaxX, double span) {
    if (newMinX < 0) {
      newMinX = 0;
      newMaxX = newMinX + span;
    }
    if (newMaxX > _totalPoints - 1) {
      newMaxX = (_totalPoints - 1).toDouble();
      newMinX = newMaxX - span;
      if (newMinX < 0) newMinX = 0;
    }
    setState(() {
      _minX = newMinX;
      _maxX = newMaxX;
    });
  }

  // ---- Desktop: Ctrl+Scroll to zoom (without Ctrl → passes to parent scroll) ----

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final isCtrlHeld = HardwareKeyboard.instance.logicalKeysPressed
          .any((key) =>
              key == LogicalKeyboardKey.controlLeft ||
              key == LogicalKeyboardKey.controlRight);
      if (!isCtrlHeld) return; // let parent CustomScrollView handle normal scroll

      GestureBinding.instance.pointerSignalResolver.register(event,
          (PointerSignalEvent e) {
        if (e is! PointerScrollEvent || _totalPoints == 0) return;

        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final chartWidth = renderBox.size.width - _leftReserved;
        double localDx =
            (e.localPosition.dx - _leftReserved).clamp(0.0, chartWidth);
        double fraction = (localDx / chartWidth).clamp(0.0, 1.0);

        // Scroll down (dy>0) = zoom out, scroll up = zoom in (standard convention)
        double zoom = e.scrollDelta.dy > 0 ? 1.2 : 0.8;
        _zoomBy(zoom, fraction);
      });
    }
  }

  // ---- Desktop: Mouse drag to pan (Listener-based, no gesture arena conflict) ----

  void _handleDesktopPointerDown(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons == kPrimaryButton) {
      _isDragging = true;
      _dragStartPos = event.localPosition;
      _dragStartMinX = _minX;
      _dragStartMaxX = _maxX;
    }
  }

  void _handleDesktopPointerMove(PointerMoveEvent event) {
    if (!_isDragging) return;
    if (event.buttons != kPrimaryButton) {
      _isDragging = false;
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final chartWidth = renderBox.size.width - _leftReserved;
    if (chartWidth <= 0) return;

    final startSpan = _dragStartMaxX - _dragStartMinX;
    final deltaDx = event.localPosition.dx - _dragStartPos.dx;
    final deltaXUnits = -(deltaDx / chartWidth) * startSpan;

    double newMinX = _dragStartMinX + deltaXUnits;
    double newMaxX = _dragStartMaxX + deltaXUnits;
    _clampAndApply(newMinX, newMaxX, startSpan);
  }

  void _handleDesktopPointerUp(PointerUpEvent event) {
    if (_isDragging) {
      setState(() => _isDragging = false);
    }
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    if (_spots.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.unknownLabel));
    }

    final chart = _buildChart(context);

    if (!widget.enablePanZoom) {
      return chart;
    }

    if (_isDesktop) {
      return _buildDesktopWrapper(chart);
    } else {
      return _buildMobileWrapper(chart);
    }
  }

  // Desktop: Listener for Ctrl+scroll zoom & drag-to-pan (passive, no gesture arena)
  // fl_chart's built-in touch handles hover tooltip independently.
  Widget _buildDesktopWrapper(Widget chart) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      onPointerDown: _handleDesktopPointerDown,
      onPointerMove: _handleDesktopPointerMove,
      onPointerUp: _handleDesktopPointerUp,
      child: MouseRegion(
        cursor:
            _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Stack(
          children: [
            chart,
            if (_isZoomed)
              Positioned(
                right: 8,
                top: 8,
                child: _buildIconButton(Icons.fit_screen_rounded, _resetZoom),
              ),
          ],
        ),
      ),
    );
  }

  // Mobile: No GestureDetector wrapping → no conflict with parent scroll/TabBarView.
  // fl_chart handles tap tooltip. Overlay buttons for zoom/pan/reset.
  Widget _buildMobileWrapper(Widget chart) {
    return Stack(
      children: [
        chart,
        Positioned(
          right: 4,
          top: 4,
          child: _buildMobileControls(),
        ),
      ],
    );
  }

  Widget _buildMobileControls() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(200),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildControlButton(Icons.add, () => _zoomBy(0.7)),
          _buildControlButton(Icons.remove, () => _zoomBy(1.4)),
          if (_isZoomed) ...[
            _buildControlButton(Icons.chevron_left, () => _panBy(-0.3)),
            _buildControlButton(Icons.chevron_right, () => _panBy(0.3)),
            _buildControlButton(Icons.fit_screen_rounded, _resetZoom),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withAlpha(200),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return Container(
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
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withAlpha(50),
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
                    int step =
                        (currentSpan / 6).clamp(1, currentSpan).ceil();

                    if (index % step == 0 || index == _totalPoints - 1) {
                      String dateStr = _sortedKeys[index];
                      List<String> parts = dateStr.split('-');
                      String display = parts.length >= 3
                          ? '${parts[1]}-${parts[2]}'
                          : dateStr;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Text(
                          display,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
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
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: _leftReserved,
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
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
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  int spotIndex = touchedSpot.x.round();
                  if (spotIndex < 0) spotIndex = 0;
                  if (spotIndex >= _totalPoints) spotIndex = _totalPoints - 1;
                  final date = _sortedKeys[spotIndex];
                  return LineTooltipItem(
                    '$date\n${touchedSpot.y.toInt()} ${AppLocalizations.of(context)!.playsSuffix}',
                    TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onInverseSurface,
                        fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
