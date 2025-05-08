import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/pages/signup/widgets/details_page.dart';
import 'package:http/http.dart' as http;
import 'package:gibud/utils/popups/full_screen.dart';
import 'package:gibud/utils/popups/loaders.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../navigation_menu.dart';
import '../pages/signup/widgets/otp_page.dart';
import '../utils/constants/animation_strings.dart';

class SignUpPhoneAuthController extends GetxController {
  static SignUpPhoneAuthController get instance => Get.find();


  final hidePassword = true.obs;
  late final TextEditingController phoneNumber;
  final verificationId = ''.obs;
  final otpSent = false.obs;
  final privacyPolicy = false.obs; // Observable for checkbox state
  GlobalKey<FormState> signUpPhoneAuthFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    phoneNumber = TextEditingController();
  }

  @override
  void onClose() {
    phoneNumber.dispose();
    super.onClose();
  }

  /// Generate OTP
  String generateOtp() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  /// Send OTP via SMS
  Future<bool> sendOtpSms(String otp) async {
    final url =
        'https://app.rpsms.in/api/push.json?apikey=6732fa15e03a1&sender=BABYCU&mobileno=${phoneNumber.text.trim()}&text=$otp%20is%20the%20OTP%20to%20login%20to%20your%20GIBUD.%20Please%20do%20not%20share%20this%20with%20anyone.%20Thanks%20-%20BabyCue%20Private%20Limited';
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// Validate phone number
  bool isValidPhoneNumber(String phone) {
    return phone.length == 10 && RegExp(r'^\d+$').hasMatch(phone);
  }

  /// Send OTP
  Future<void> sendOtp(BuildContext context) async {
    try {

      FullScreenLoader.openLoadingDialog(
        "We are processing your information",
        AnimationStrings.loadingAnimation,
      );

      // Check internet connectivity
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading();
        _showNoInternetDialog(context);
        return;
      }
      // Privacy policy validation
      if (!privacyPolicy.value) {
        FullScreenLoader.stopLoading();
        Future.delayed(Duration(milliseconds: 100), () {
          Loaders.warningSnackBar(
            title: "Accept Privacy Policy",
            message: "You must agree to the Privacy Policy and Terms.",
          );
        });
        return;
      }

      // Phone number validation
      if (!isValidPhoneNumber(phoneNumber.text.trim())) {
        Loaders.errorSnackBar(
          title: "Invalid Phone Number",
          message: "Enter a valid 10-digit phone number.",
        );
        return;
      }

      FullScreenLoader.openLoadingDialog(
        "Sending OTP",
        AnimationStrings.loadingAnimation,
      );

      final otp = generateOtp();
      final sent = await sendOtpSms(otp);

      FullScreenLoader.stopLoading();

      if (!sent) {
        Loaders.errorSnackBar(
          title: "Error",
          message: "Failed to send OTP. Try again later.",
        );
        return;
      }

      verificationId.value = otp;
      otpSent.value = true;

      // Navigating to OTP page
      Get.to(() => OtpPage(isSignup: true,)); // Assuming isSignup is used to differentiate sign up flow
    } catch (e) {
      // Catch any errors and stop the loader
      FullScreenLoader.stopLoading();
      print('Error in sendOtp: $e');

      // Display a general error message to the user
      Loaders.errorSnackBar(
        title: "Error",
        message: "An unexpected error occurred. Please try again.",
      );
    }
  }


  /// Verify OTP and navigate to the next page
  Future<void> verifyOtp(BuildContext context, String enteredOtp) async {
    // OTP verification
    if (enteredOtp != verificationId.value) {
      Loaders.errorSnackBar(
        title: "Invalid OTP",
        message: "Please check the OTP and try again.",
      );
      return;
    }

    FullScreenLoader.openLoadingDialog(
      "Verifying OTP",
      AnimationStrings.loadingAnimation,
    );

    FullScreenLoader.stopLoading();
    Loaders.successSnackBar(
      title: "Verification Successful",
      message: "You have been successfully authenticated!",
    );

    // Proceed to the next page
    Get.offAll(() => DetailsPage());
  }

  /// Method to show no internet connection dialog
  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
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
  }
}
