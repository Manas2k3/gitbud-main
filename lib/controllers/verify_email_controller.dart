import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:gibud/pages/signup/widgets/sucesss_email.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:gibud/utils/popups/loaders.dart';

import '../data/repositories/authentication/authentication_repository.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();


  @override
  void onInit() {
    sendEmailVerification();
    sendTimerForAutoRedirect();
    super.onInit();
  }

  ///Set Email Verification Link
  sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      Loaders.successSnackBar(title: 'Email Sent!!', message: 'Please check your inbox and verify your email ');
    }catch(e) {

    }
  }

  ///Timer to automatically redirect on Email Verification

  void sendTimerForAutoRedirect() {
    Timer.periodic(
      const Duration(seconds: 1),
          (timer) async {
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          timer.cancel();

          Get.offAll(() => SucesssEmail(image: AnimationStrings.sucessfullyRegisteredAnimation, title: 'Account created successfully', subTitle: 'Welcome to the App', onPressed: () => AuthenticationRepository.instance.screenRedirect())); // Replace 'YourNextPage' with your desired page
        }
      },
    );
  }


  ///Manually check if email is verified
  checkEmailVerificationStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if(currentUser != null && currentUser.emailVerified) {
      Get.off(
          () => SucesssEmail(image: AnimationStrings.sucessfullyRegisteredAnimation , title: 'Account created successfully', subTitle: 'Welcome to the App', onPressed: () => AuthenticationRepository.instance.screenRedirect())
      );
    }
  }

}