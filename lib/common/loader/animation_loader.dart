import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class AnimationLoader extends StatelessWidget {
  final String text;
  final String animation;

  const AnimationLoader({
    Key? key,
    required this.text,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(animation,
              width: MediaQuery.of(context).size.width * 0.8), // Load animation from the path
          const SizedBox(height: 20),
          Text(
            text,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
