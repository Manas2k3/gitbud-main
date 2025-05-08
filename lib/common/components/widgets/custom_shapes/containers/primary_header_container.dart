import 'package:flutter/material.dart';

import '../curved_edges/curved_edges_widget.dart';
import 'circular_container.dart';

class PrimaryHeaderContainer extends StatelessWidget {
  const PrimaryHeaderContainer({
    super.key,
    required this.child, this.color,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomCurvedEdgesWidget(
      child: Container(
        color: color,
        padding: EdgeInsets.all(0),
        child: Stack(
          children: [
            Positioned(
                top: -150,
                right: -250,
                child: CustomCircularWidget(
                    backgroundColor: Colors.white.withOpacity(0.1))),
            Positioned(
              top: 100,
              right: -300,
              child: CustomCircularWidget(
                  backgroundColor: Colors.white.withOpacity(0.1)),
            ),
            child,
          ],
        ),
      ),
    );
  }
}