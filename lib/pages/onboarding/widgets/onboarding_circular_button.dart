// ignore_for_file: prefer_const_constructors, camel_case_types

import 'package:flutter/material.dart';
import 'package:gibud/controllers/onboarding_controller.dart';
import 'package:iconsax/iconsax.dart';

class onBoardingCircularButton extends StatelessWidget {
  const onBoardingCircularButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 25,
      bottom: 45,
      child: ElevatedButton(
        onPressed: () => OnboardingController.instance.nextPage(),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.redAccent,
          minimumSize: Size(60, 60),
          shape: CircleBorder(),
        ),
        child: Icon(
          color: Colors.black,
          Iconsax.arrow_right_3,
        ),
      ),
    );
  }
}
