import 'package:gibud/features/screens/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/pages/signup/signup_page.dart';

class OnboardingController extends GetxController {
  static OnboardingController get instance => Get.find();

  // Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  // Update the Variables
  void upDatePageIndicator(index) => currentPageIndex.value = index;

  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Go to the next page or HomePage
  void nextPage() async {
    if (currentPageIndex.value == 2) { // Mark onboarding as viewed
      Get.off(() => SignupPage());        // Navigate to HomePage
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  // Skip the onboarding and go to HomePage
  void skipPage() async { // Mark onboarding as viewed
    Get.off(() => SignupPage());         // Navigate to HomePage
  }
}
