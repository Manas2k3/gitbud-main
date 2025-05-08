// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/controllers/onboarding_controller.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/pages/onboarding/widgets/onBoardingNavigation.dart';
import 'package:gibud/pages/onboarding/widgets/onboarding_circular_button.dart';
import 'package:gibud/pages/onboarding/widgets/onboarding_page.dart';
import 'package:gibud/pages/onboarding/widgets/onboarding_skip.dart';
import 'package:gibud/utils/constants/image_strings.dart';
import 'package:gibud/utils/constants/text_strings.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// Horizontal Scrollable Pages
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.upDatePageIndicator,
            children: [
              onBoardingPage(
                image: ImageStrings.onBoardingImage1,
                title: TextStrings.onBoardingTitle1,
                subTitle: TextStrings.onBoardingSubTitle1,
              ),
              onBoardingPage(
                image: ImageStrings.onBoardingImage2,
                title: TextStrings.onBoardingTitle2,
                subTitle: TextStrings.onBoardingSubTitle2,
              ),
              onBoardingPage(
                image: ImageStrings.onBoardingImage3,
                title: TextStrings.onBoardingTitle3,
                subTitle: TextStrings.onBoardingSubTitle3,
              ),
            ],
          ),

          // Skip Button
          onBoardingSkip(),

          // Dot Navigation SmoothPageIndicator
          onBoardingNavigation(),

          // Circular Button
          onBoardingCircularButton()
        ],
      ),
    );
  }
}
