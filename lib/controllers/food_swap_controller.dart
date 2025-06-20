import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../chat/individual_chat_page.dart';
import '../chat/models/chat_model.dart';
import '../services/firestore_service.dart';
import '../utils/constants/animation_strings.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';

class FoodSwapController extends GetxController {
  static FoodSwapController get instance => Get.find();


  String combinedPhoneNumber = '';

  /// Main Sign-Up Function
  Future<void> signUp(BuildContext context) async {
    try {
      _showLoader();

      // Check internet connectivity
      if (!await _isInternetConnected()) {
        _hideLoader();
        _showNoInternetDialog(context);
        return;
      }

      _hideLoader();



    } catch (e, stackTrace) {
    }
  }

  /// Show Loader
  void _showLoader() {
    FullScreenLoader.openLoadingDialog(
      "We are processing your information",
      AnimationStrings.loadingAnimation,
    );
  }

  /// Hide Loader
  void _hideLoader() {
    FullScreenLoader.stopLoading();
  }

  /// Check Internet Connectivity
  Future<bool> _isInternetConnected() async {
    return await InternetConnectionChecker().hasConnection;
  }




  /// Show No Internet Dialog
  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("No Internet"),
          content: const Text("Please check your internet connection."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
