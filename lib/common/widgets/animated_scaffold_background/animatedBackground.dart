import 'dart:math' as math;
import 'package:flutter/material.dart';

class GradientBouncingBackground extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;

  const GradientBouncingBackground({
    Key? key,
    required this.child,
    this.gradientColors = const [
      Color(0xFFEFF6FF), // very light blue tint
      Colors.white,
    ],
  }) : super(key: key);

  @override
  State<GradientBouncingBackground> createState() => _GradientBouncingBackgroundState();
}

class _GradientBouncingBackgroundState extends State<GradientBouncingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Tune speeds, sizes, and phase offsets for variety.
  final _speeds = [0.6, 0.9, 0.7, 1.1];
  final _sizes  = [140.0, 90.0, 120.0, 70.0];
  final _phase  = [0.0, math.pi / 2, math.pi, math.pi * 1.5];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(); // smooth, endless
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ball(double size, double t, double speed, double phase, BoxConstraints c) {
    // Parametric motion (sine/cosine) scaled to screen.
    final w = c.maxWidth;
    final h = c.maxHeight;

    // Gentle horizontal & vertical oscillation
    final x = (w * 0.5) + (w * 0.32) * math.sin((t * speed) + phase);
    final y = (h * 0.45) + (h * 0.30) * math.cos((t * speed * 0.9) + phase);

    return Positioned(
      left: x - size / 2,
      top: y - size / 2,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Soft glow using a radial gradient
            gradient: RadialGradient(
              colors: [
                const Color(0xFF93C5FD).withOpacity(0.45), // light blue center
                const Color(0xFFBFDBFE).withOpacity(0.20),
                Colors.white.withOpacity(0.0),              // fade to transparent
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: size * 0.25,
                spreadRadius: size * 0.02,
                color: const Color(0xFF60A5FA).withOpacity(0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi; // 0..2π
            return Stack(
              children: [
                // Background gradient (light blue → white)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradientColors,
                    ),
                  ),
                ),

                // Animated gradient balls
                ...List.generate(_sizes.length, (i) {
                  return _ball(_sizes[i], t, _speeds[i], _phase[i], c);
                }),

                // Your actual page content
                RepaintBoundary(child: widget.child),
              ],
            );
          },
        );
      },
    );
  }
}
