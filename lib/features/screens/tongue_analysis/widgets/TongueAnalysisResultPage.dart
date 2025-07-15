import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TongueAnalysisResultPage extends StatelessWidget {
  const TongueAnalysisResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FD),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "AI Tongue Analysis",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Position your tongue in the center",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: Colors.blue),
                  SizedBox(width: 5),
                  Text(
                    "AI Processing Ready",
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: 350,
                height: MediaQuery.of(context).size.height * 0.60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3A3456), Color(0xFF4B3E63)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _blackStatusChip("🤖 AI Ready - Position tongue in circle"),
                    const Spacer(),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CustomPaint(
                            painter: DashedCirclePainter(),
                          ),
                        ),
                        Column(
                          children: const [
                            Icon(Icons.face_retouching_natural,
                                size: 50, color: Colors.pinkAccent),
                            SizedBox(height: 8),
                            Text(
                              "Center tongue here",
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              "🧠 AI will analyze",
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    child: Align(alignment: Alignment.center,child: Text("Back", style: TextStyle(color: Colors.black, fontSize: 16),)),
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.06,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    child: Align(alignment: Alignment.center,child: Text("Capture",style: TextStyle(color: Colors.white, fontSize: 16))),
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.06,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.purple],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade100,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _blackStatusChip(String label, {bool isError = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isError ? Colors.redAccent : Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _gradientButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.purple],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// 🎯 Custom dashed circle painter — no package needed
class DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double dashLength = 6;
    const double gapLength = 4;
    final Paint paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashLength + gapLength)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (2 * math.pi / dashCount) * i;
      final double x1 = center.dx + radius * math.cos(startAngle);
      final double y1 = center.dy + radius * math.sin(startAngle);
      final double x2 =
          center.dx + radius * math.cos(startAngle + dashLength / radius);
      final double y2 =
          center.dy + radius * math.sin(startAngle + dashLength / radius);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
