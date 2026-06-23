import 'package:flutter/material.dart';

/// onboarding_illustration.dart
/// PLACEHOLDER illustrations approximating the composition/mood of the
/// uploaded mockups (sunset path, character silhouette) using gradients
/// and simple shapes — not final art. Swap the body of
/// `JourneyPathIllustration` for an Image.asset(...) once real generated
/// illustrations are dropped into assets/images/.
class JourneyPathIllustration extends StatelessWidget {
  const JourneyPathIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Sky gradient — dawn colors matching screenshot 1
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2B2A4A),
                  Color(0xFF6B5B8C),
                  Color(0xFFE8A87C),
                  Color(0xFFF5D08A),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),
          // Sun glow
          Align(
            alignment: const Alignment(0, 0.15),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    const Color(0xFFFFD89B).withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Distant mountain silhouettes
          Positioned(
            bottom: 60,
            left: -20,
            right: -20,
            child: CustomPaint(
              size: const Size(double.infinity, 120),
              painter: _MountainPainter(color: const Color(0xFF3D3760).withOpacity(0.55)),
            ),
          ),
          Positioned(
            bottom: 20,
            left: -30,
            right: -30,
            child: CustomPaint(
              size: const Size(double.infinity, 100),
              painter: _MountainPainter(color: const Color(0xFF2A2640).withOpacity(0.8)),
            ),
          ),
          // Winding path + tiny character silhouette
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 70),
              painter: _PathPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  _MountainPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(size.width * 0.18, size.height * 0.15)
      ..lineTo(size.width * 0.32, size.height * 0.45)
      ..lineTo(size.width * 0.5, size.height * 0.05)
      ..lineTo(size.width * 0.68, size.height * 0.4)
      ..lineTo(size.width * 0.85, size.height * 0.2)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.6,
        size.width * 0.55,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.15,
        size.width * 0.6,
        0,
      );

    // dashed effect
    final dashPath = Path();
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, pathPaint);

    // character silhouette near bottom of path
    final charPaint = Paint()..color = const Color(0xFF1F1B2E);
    canvas.drawCircle(Offset(size.width * 0.5, size.height - 22), 5, charPaint); // head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height - 10),
          width: 10,
          height: 16,
        ),
        const Radius.circular(3),
      ),
      charPaint,
    ); // body
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating "island" illustration used behind each habit-category card on
/// the Habits screen — soft radial ground + gradient sky backdrop.
class FloatingIslandBackdrop extends StatelessWidget {
  const FloatingIslandBackdrop({
    super.key,
    required this.skyColors,
    required this.groundColor,
  });

  final List<Color> skyColors;
  final Color groundColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: skyColors,
            ),
          ),
        ),
        Align(
          alignment: const Alignment(0, 0.7),
          child: FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.35,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [groundColor, groundColor.withOpacity(0)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
