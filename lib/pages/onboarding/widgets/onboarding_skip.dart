import 'package:flutter/material.dart';
import 'package:gibud/controllers/onboarding_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class onBoardingSkip extends StatelessWidget {
  const onBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: kToolbarHeight,
        right: 25,
        child: TextButton(
          onPressed: () => OnboardingController.instance.skipPage(),
          child: Text(
            'Skip',
            style: GoogleFonts.poppins(
                color: Colors.redAccent, fontSize: 18),
          ),
        ));
  }
}
