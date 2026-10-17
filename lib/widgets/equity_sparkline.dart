import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class EquitySparkline extends StatelessWidget {
  final List<double> points;
  final double height;
  final bool showGradient;

  const EquitySparkline({
    super.key,
    required this.points,
    this.height = 60.0,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppColors.primaryLight.withOpacity(0.3),
          ),
        ),
      );
    }

    final isProfit = points.last >= points.first;
    final strokeColor = isProfit ? AppColors.primaryLight : AppColors.lose;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: points,
          strokeColor: strokeColor,
          showGradient: showGradient,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color strokeColor;
  final bool showGradient;

  _SparklinePainter({
    required this.points,
    required this.strokeColor,
    required this.showGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final minVal = points.reduce(min);
    final maxVal = points.reduce(max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    const double paddingY = 8.0;
    final double drawingHeight = size.height - (paddingY * 2);
    final double stepX = size.width / (points.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minVal) / range;
      final y = size.height - paddingY - (normalized * drawingHeight);

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

    // Draw area gradient
    if (showGradient) {
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          strokeColor.withOpacity(0.35),
          strokeColor.withOpacity(0.0),
        ],
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw line stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.showGradient != showGradient;
  }
}
