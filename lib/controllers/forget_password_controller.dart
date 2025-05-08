import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/data/repositories/authentication/authentication_repository.dart';
import 'package:gibud/pages/login/widgets/reset_password.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../utils/constants/animation_strings.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  /// Variables
  final email = TextEditingController();
  GlobalKey<FormState> forgetPasswordFormKey = GlobalKey<FormState>();

  /// Send Reset Password Email
  sendPasswordResetMail(BuildContext context) async {
    try {
      FullScreenLoader.openLoadingDialog(
        "We are processing your information",
        AnimationStrings.loadingAnimation,
      );

      /// Internet connection check
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading(); // Stopping loader if there's no internet

        // Show dialog box instead of snackbar
        showDialog(
          context: context,  // Pass the context from the widget
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("No Internet"),
              content: const Text("Please check your internet connection."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }

      /// Form Validation
      if (!forgetPasswordFormKey.currentState!.validate()) {
        FullScreenLoader.stopLoading();
        return;
      }

      /// Send Email to Reset the Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email.text.trim());

      /// Removal of the loader
      FullScreenLoader.stopLoading();

      /// Show success screen
      Loaders.successSnackBar(
        title: 'Email Sent!',
        message: 'Email link has been sent to reset your password!',
      );

      /// Pass the email entered to the ResetPassword page
      Get.to(() => ResetPassword(email: email.text.trim()));

    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(
        title: 'Oh Snap!',
        message: e.toString(),
      );
    }
  }

  resendPasswordResetMail(String email, BuildContext context) async {
    try {
      FullScreenLoader.openLoadingDialog(
        "We are processing your information",
        AnimationStrings.loadingAnimation,
      );

      /// Internet connection check
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading(); // Stopping loader if there's no internet

        // Show dialog box instead of snackbar
        showDialog(
          context: context,  // Pass the context from the widget
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("No Internet"),
              content: const Text("Please check your internet connection."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }

      /// Send Email to Reset the Password
      await AuthenticationRepository.instance.sendPasswordResetEmail(email);

      /// Removal of the loader
      FullScreenLoader.stopLoading();

      /// Show success screen
      Loaders.successSnackBar(
        title: 'Email Sent!',
        message: 'Email link has been sent to reset your password!',
      );

    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(
        title: 'Oh Snap!',
        message: e.toString(),
      );
    }
  }
}
