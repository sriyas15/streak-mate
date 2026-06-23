import 'package:flutter/material.dart';

/// goal_icon_widgets.dart
/// Custom icon widgets for each GoalOption — matches the illustrated
/// circular icon style in the onboarding mockup (screen 2/4).
/// Each returns a sized widget meant to sit inside the 40×40 colored circle
/// in GoalCard.

// ─── Get Fit — dumbbell + figure ────────────────────────────────────────────
class GetFitIcon extends StatelessWidget {
  const GetFitIcon({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DumbbellPainter(color: color),
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  final Color color;
  const _DumbbellPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.13
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Bar
    canvas.drawLine(
      Offset(size.width * 0.18, cy),
      Offset(size.width * 0.82, cy),
      paint,
    );

    // Left plates
    final leftPlateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.14, cy), width: size.width * 0.12, height: size.height * 0.42),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(leftPlateRect, fillPaint);

    final leftPlate2Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.22, cy), width: size.width * 0.10, height: size.height * 0.30),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(leftPlate2Rect, fillPaint);

    // Right plates
    final rightPlateRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.86, cy), width: size.width * 0.12, height: size.height * 0.42),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(rightPlateRect, fillPaint);

    final rightPlate2Rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width * 0.78, cy), width: size.width * 0.10, height: size.height * 0.30),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(rightPlate2Rect, fillPaint);

    // Person head above bar
    canvas.drawCircle(
      Offset(cx, cy - size.height * 0.32),
      size.width * 0.10,
      fillPaint,
    );

    // Person arms raised holding bar
    final armPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.width * 0.11
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(cx - size.width * 0.18, cy),
      Offset(cx - size.width * 0.06, cy - size.height * 0.18),
      armPaint,
    );
    canvas.drawLine(
      Offset(cx + size.width * 0.18, cy),
      Offset(cx + size.width * 0.06, cy - size.height * 0.18),
      armPaint,
    );

    // Torso
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.22),
      Offset(cx, cy + size.height * 0.10),
      armPaint,
    );
  }

  @override
  bool shouldRepaint(_DumbbellPainter old) => old.color != color;
}

// ─── Spiritual Growth — crescent moon + star ────────────────────────────────
class SpiritualGrowthIcon extends StatelessWidget {
  const SpiritualGrowthIcon({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CrescentPainter(color: color),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  final Color color;
  const _CrescentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Crescent: large circle minus offset circle
    final path = Path();
    final cx = size.width * 0.44;
    final cy = size.height * 0.52;
    final r = size.width * 0.36;

    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    final cutPath = Path();
    cutPath.addOval(Rect.fromCircle(
      center: Offset(cx + r * 0.55, cy - r * 0.18),
      radius: r * 0.80,
    ));

    final crescent = Path.combine(PathOperation.difference, path, cutPath);
    canvas.drawPath(crescent, fillPaint);

    // 4-point star top-right
    final sx = size.width * 0.80;
    final sy = size.height * 0.20;
    final sr = size.width * 0.11;
    _draw4Star(canvas, sx, sy, sr, fillPaint);
  }

  void _draw4Star(Canvas canvas, double cx, double cy, double r, Paint paint) {
    final path = Path();
    path.moveTo(cx, cy - r);
    path.lineTo(cx + r * 0.28, cy - r * 0.28);
    path.lineTo(cx + r, cy);
    path.lineTo(cx + r * 0.28, cy + r * 0.28);
    path.lineTo(cx, cy + r);
    path.lineTo(cx - r * 0.28, cy + r * 0.28);
    path.lineTo(cx - r, cy);
    path.lineTo(cx - r * 0.28, cy - r * 0.28);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CrescentPainter old) => old.color != color;
}

// ─── Study & Learn — open book ───────────────────────────────────────────────
class StudyLearnIcon extends StatelessWidget {
  const StudyLearnIcon({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OpenBookPainter(color: color),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  final Color color;
  const _OpenBookPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.09
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final top = size.height * 0.22;
    final bottom = size.height * 0.82;
    final left = size.width * 0.06;
    final right = size.width * 0.94;

    // Left page
    final leftPage = Path()
      ..moveTo(cx, top + size.height * 0.06)
      ..lineTo(left + size.width * 0.06, top)
      ..lineTo(left, top + size.height * 0.08)
      ..lineTo(left, bottom)
      ..lineTo(cx, bottom - size.height * 0.04)
      ..close();
    canvas.drawPath(leftPage, fillPaint);
    canvas.drawPath(leftPage, paint);

    // Right page
    final rightPage = Path()
      ..moveTo(cx, top + size.height * 0.06)
      ..lineTo(right - size.width * 0.06, top)
      ..lineTo(right, top + size.height * 0.08)
      ..lineTo(right, bottom)
      ..lineTo(cx, bottom - size.height * 0.04)
      ..close();
    canvas.drawPath(rightPage, fillPaint);
    canvas.drawPath(rightPage, paint);

    // Spine center line
    canvas.drawLine(Offset(cx, top + size.height * 0.06), Offset(cx, bottom - size.height * 0.04), paint);

    // Lines on left page
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final y = top + size.height * 0.22 + i * size.height * 0.14;
      canvas.drawLine(Offset(left + size.width * 0.10, y), Offset(cx - size.width * 0.08, y), linePaint);
    }
    // Lines on right page
    for (int i = 0; i < 3; i++) {
      final y = top + size.height * 0.22 + i * size.height * 0.14;
      canvas.drawLine(Offset(cx + size.width * 0.08, y), Offset(right - size.width * 0.10, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_OpenBookPainter old) => old.color != color;
}

// ─── Live Healthy — heart ───────────────────────────────────────────────────
class LiveHealthyIcon extends StatelessWidget {
  const LiveHealthyIcon({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeartPainter(color: color),
    );
  }
}

class _HeartPainter extends CustomPainter {
  final Color color;
  const _HeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final path = Path();

    final topY = size.height * 0.28;
    final r = size.width * 0.24;

    // Left lobe
    path.addOval(Rect.fromCircle(center: Offset(cx - r * 0.72, topY), radius: r));
    // Right lobe
    path.addOval(Rect.fromCircle(center: Offset(cx + r * 0.72, topY), radius: r));
    // Triangle bottom
    path.moveTo(cx - r * 1.55, topY + r * 0.3);
    path.lineTo(cx, size.height * 0.84);
    path.lineTo(cx + r * 1.55, topY + r * 0.3);
    path.close();

    canvas.drawPath(path, paint);

    // Small ECG line across heart
    final linePaint = Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final mid = size.height * 0.52;
    final ecg = Path()
      ..moveTo(cx - size.width * 0.30, mid)
      ..lineTo(cx - size.width * 0.12, mid)
      ..lineTo(cx - size.width * 0.06, mid - size.height * 0.10)
      ..lineTo(cx, mid + size.height * 0.12)
      ..lineTo(cx + size.width * 0.06, mid - size.height * 0.06)
      ..lineTo(cx + size.width * 0.12, mid)
      ..lineTo(cx + size.width * 0.30, mid);
    canvas.drawPath(ecg, linePaint);
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.color != color;
}

// ─── Be Productive — briefcase ───────────────────────────────────────────────
class BeProductiveIcon extends StatelessWidget {
  const BeProductiveIcon({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BriefcasePainter(color: color),
    );
  }
}

class _BriefcasePainter extends CustomPainter {
  final Color color;
  const _BriefcasePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final bgPaint = Paint()
      ..color = color.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    // Case body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.36, size.width * 0.84, size.height * 0.46),
      Radius.circular(size.width * 0.10),
    );
    canvas.drawRRect(bodyRect, bgPaint);
    canvas.drawRRect(bodyRect, strokePaint);

    // Handle
    final handleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.32, size.height * 0.18, size.width * 0.36, size.height * 0.22),
      Radius.circular(size.width * 0.08),
    );
    canvas.drawRRect(handleRect, strokePaint);

    // Center clasp
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.59),
          width: size.width * 0.18,
          height: size.height * 0.16,
        ),
        Radius.circular(size.width * 0.04),
      ),
      fillPaint,
    );

    // Horizontal divider line
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.59),
      Offset(size.width * 0.92, size.height * 0.59),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(_BriefcasePainter old) => old.color != color;
}

// ─── Something Else — three dots in speech bubble ───────────────────────────
class SomethingElseIcon extends StatelessWidget {
  const SomethingElseIcon({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ChatBubblePainter(color: color),
    );
  }
}

class _ChatBubblePainter extends CustomPainter {
  final Color color;
  const _ChatBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color.withOpacity(0.22)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.09
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Bubble body
    final bubblePath = Path();
    final left = size.width * 0.06;
    final top = size.height * 0.10;
    final right = size.width * 0.94;
    final bottom = size.height * 0.76;
    final r = size.width * 0.14;

    bubblePath.moveTo(left + r, top);
    bubblePath.lineTo(right - r, top);
    bubblePath.arcToPoint(Offset(right, top + r), radius: Radius.circular(r));
    bubblePath.lineTo(right, bottom - r);
    bubblePath.arcToPoint(Offset(right - r, bottom), radius: Radius.circular(r));
    // Tail
    bubblePath.lineTo(size.width * 0.45, bottom);
    bubblePath.lineTo(size.width * 0.30, size.height * 0.92);
    bubblePath.lineTo(size.width * 0.25, bottom);
    bubblePath.lineTo(left + r, bottom);
    bubblePath.arcToPoint(Offset(left, bottom - r), radius: Radius.circular(r));
    bubblePath.lineTo(left, top + r);
    bubblePath.arcToPoint(Offset(left + r, top), radius: Radius.circular(r));
    bubblePath.close();

    canvas.drawPath(bubblePath, fillPaint);
    canvas.drawPath(bubblePath, strokePaint);

    // Three dots
    final cy = (top + bottom) / 2;
    final dotR = size.width * 0.07;
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.32 + i * size.width * 0.18, cy),
        dotR,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ChatBubblePainter old) => old.color != color;
}