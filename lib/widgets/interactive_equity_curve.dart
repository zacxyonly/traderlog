import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';

class InteractiveEquityCurve extends StatefulWidget {
  final List<double> equityPoints;
  final List<Trade> trades;
  final double initialCapital;
  final String currency;
  final double height;

  const InteractiveEquityCurve({
    super.key,
    required this.equityPoints,
    required this.trades,
    required this.initialCapital,
    required this.currency,
    this.height = 160.0,
  });

  @override
  State<InteractiveEquityCurve> createState() => _InteractiveEquityCurveState();
}

class _InteractiveEquityCurveState extends State<InteractiveEquityCurve> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.equityPoints;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final softColor = isDark ? AppColors.darkSoft : AppColors.lightSoft;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final lang = context.watch<TradeProvider>().settings.languageCode;

    if (points.length < 2) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            lang == 'en'
                ? 'Curve will form as trades are logged.'
                : 'Kurva akan terbentuk setelah Anda mencatat trade.',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
        ),
      );
    }

    final minVal = points.reduce(min);
    final maxVal = points.reduce(max);
    final latestVal = points.last;
    final isOverallProfit = latestVal >= widget.initialCapital;
    final themeColor = isOverallProfit ? AppColors.primary : AppColors.lose;

    // Data for currently scrubbed point or latest
    final activeIdx = _selectedIndex ?? (points.length - 1);
    final activeVal = points[activeIdx.clamp(0, points.length - 1)];
    final diffFromStart = activeVal - widget.initialCapital;
    final percentFromStart = widget.initialCapital > 0 ? (diffFromStart / widget.initialCapital) * 100 : 0.0;

    String tooltipSubtitle = '';
    if (activeIdx == 0) {
      tooltipSubtitle = AppStrings.tr('initial_capital', lang);
    } else if (activeIdx - 1 < widget.trades.length) {
      final t = widget.trades[activeIdx - 1];
      tooltipSubtitle = 'Trade #$activeIdx: ${t.sym} (${Formatters.formatAmountSigned(t.pl, currency: widget.currency)})';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live scrubbing header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: softColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tooltipSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: mutedColor,
                      ),
                    ),
                    Text(
                      Formatters.formatAmount(activeVal, currency: widget.currency),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: diffFromStart >= 0
                      ? AppColors.win.withOpacity(0.18)
                      : AppColors.lose.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${diffFromStart >= 0 ? "+" : ""}${percentFromStart.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: diffFromStart >= 0 ? AppColors.winText : AppColors.loseText,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Interactive Canvas with touch events
        GestureDetector(
          onPanDown: (details) => _updateTouch(details.localPosition),
          onPanUpdate: (details) => _updateTouch(details.localPosition),
          onPanEnd: (_) => setState(() => _selectedIndex = null),
          onPanCancel: () => setState(() => _selectedIndex = null),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              painter: _InteractiveCurvePainter(
                points: points,
                initialCapital: widget.initialCapital,
                selectedIndex: _selectedIndex,
                strokeColor: themeColor,
                minVal: minVal,
                maxVal: maxVal,
                isDark: isDark,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),
        // Min / Peak labels footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Min: ${Formatters.formatAmount(minVal, currency: widget.currency)}',
              style: TextStyle(fontSize: 10.5, color: mutedColor),
            ),
            Text(
              'Modal: ${Formatters.formatAmount(widget.initialCapital, currency: widget.currency)}',
              style: TextStyle(fontSize: 10.5, color: mutedColor, fontWeight: FontWeight.w600),
            ),
            Text(
              'Puncak: ${Formatters.formatAmount(maxVal, currency: widget.currency)}',
              style: const TextStyle(fontSize: 10.5, color: AppColors.primaryLight, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }

  void _updateTouch(Offset localPos) {
    final points = widget.equityPoints;
    if (points.length < 2) return;

    final RenderBox? box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 300.0;
    final stepX = width / (points.length - 1);

    final idx = (localPos.dx / stepX).round().clamp(0, points.length - 1);
    if (idx != _selectedIndex) {
      setState(() {
        _selectedIndex = idx;
      });
    }
  }
}

class _InteractiveCurvePainter extends CustomPainter {
  final List<double> points;
  final double initialCapital;
  final int? selectedIndex;
  final Color strokeColor;
  final double minVal;
  final double maxVal;
  final bool isDark;

  _InteractiveCurvePainter({
    required this.points,
    required this.initialCapital,
    required this.selectedIndex,
    required this.strokeColor,
    required this.minVal,
    required this.maxVal,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    const double paddingY = 12.0;
    final double drawingHeight = size.height - (paddingY * 2);
    final double stepX = size.width / (points.length - 1);

    // Baseline (Modal Awal) dashed line
    final baseNorm = (initialCapital - minVal) / range;
    final baseY = size.height - paddingY - (baseNorm * drawingHeight);

    final basePaint = Paint()
      ..color = (isDark ? Colors.white24 : Colors.black26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw dashed horizontal line for baseline
    double curX = 0.0;
    const dashW = 4.0;
    const dashSpace = 4.0;
    while (curX < size.width) {
      canvas.drawLine(
        Offset(curX, baseY),
        Offset(min(curX + dashW, size.width), baseY),
        basePaint,
      );
      curX += dashW + dashSpace;
    }

    final path = Path();
    final fillPath = Path();

    final List<Offset> pointCoords = [];

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minVal) / range;
      final y = size.height - paddingY - (normalized * drawingHeight);
      pointCoords.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Area Gradient Fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        strokeColor.withOpacity(0.38),
        strokeColor.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Peak Marker Dot
    final peakIdx = points.indexOf(maxVal);
    if (peakIdx != -1) {
      final peakCoord = pointCoords[peakIdx];
      final peakPaint = Paint()..color = AppColors.winText;
      canvas.drawCircle(peakCoord, 3.5, peakPaint);
    }

    // Selected Scrubbed Indicator
    if (selectedIndex != null && selectedIndex! < pointCoords.length) {
      final selectedCoord = pointCoords[selectedIndex!];

      // Vertical guideline
      final guidePaint = Paint()
        ..color = strokeColor.withOpacity(0.6)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(selectedCoord.dx, 0),
        Offset(selectedCoord.dx, size.height),
        guidePaint,
      );

      // Glowing dot
      final glowPaint = Paint()..color = strokeColor.withOpacity(0.3);
      canvas.drawCircle(selectedCoord, 8.0, glowPaint);

      final dotPaint = Paint()..color = strokeColor;
      canvas.drawCircle(selectedCoord, 4.5, dotPaint);

      final centerDot = Paint()..color = Colors.white;
      canvas.drawCircle(selectedCoord, 2.0, centerDot);
    } else {
      // Latest Point Dot
      final lastCoord = pointCoords.last;
      final dotPaint = Paint()..color = strokeColor;
      canvas.drawCircle(lastCoord, 4.5, dotPaint);
      final centerDot = Paint()..color = Colors.white;
      canvas.drawCircle(lastCoord, 2.0, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveCurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.strokeColor != strokeColor;
  }
}
