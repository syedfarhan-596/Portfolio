import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../data/models.dart';

/// Hand-rolled line chart for the last several months of net worth — no
/// charting package needed for one sparkline-style trend.
class NetWorthChart extends StatelessWidget {
  final List<NetWorthPoint> points;
  const NetWorthChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (points.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text('Keep using the app a bit longer to see a trend here.',
              style: context.text.bodySmall?.copyWith(color: t.textMid)),
        ),
      );
    }
    final color = points.last.netWorth >= points.first.netWorth ? t.success : t.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          width: double.infinity,
          child: CustomPaint(
            painter: _NetWorthPainter(points: points, lineColor: color, gridColor: t.glassBorder),
          ),
        ),
        const SizedBox(height: Insets.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: points
              .map((p) => Text(
                    Dates.month(p.dateTime).split(' ').first,
                    style: context.text.bodySmall?.copyWith(color: t.textLow, fontSize: 11),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _NetWorthPainter extends CustomPainter {
  final List<NetWorthPoint> points;
  final Color lineColor;
  final Color gridColor;
  const _NetWorthPainter({required this.points, required this.lineColor, required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.map((p) => p.netWorth).toList();
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    if ((maxV - minV).abs() < 1) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.15;
    minV -= pad;
    maxV += pad;

    final dx = points.length > 1 ? size.width / (points.length - 1) : size.width;
    Offset posFor(int i) {
      final yFrac = (values[i] - minV) / (maxV - minV);
      return Offset(dx * i, size.height - yFrac * size.height);
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final pos = posFor(i);
      if (i == 0) {
        linePath.moveTo(pos.dx, pos.dy);
        fillPath.moveTo(pos.dx, size.height);
        fillPath.lineTo(pos.dx, pos.dy);
      } else {
        linePath.lineTo(pos.dx, pos.dy);
        fillPath.lineTo(pos.dx, pos.dy);
      }
    }
    fillPath.lineTo(posFor(points.length - 1).dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: 0.28), lineColor.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(posFor(i), i == points.length - 1 ? 4.5 : 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetWorthPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}
