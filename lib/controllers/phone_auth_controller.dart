import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/pages/signup/widgets/details_page.dart';
import 'package:http/http.dart' as http;
import 'package:gibud/utils/popups/full_screen.dart';
import 'package:gibud/utils/popups/loaders.dart';
import '../navigation_menu.dart';
import '../pages/signup/widgets/email-auth.dart';
import '../pages/signup/widgets/otp_page.dart';
import '../utils/constants/animation_strings.dart';

class PhoneAuthController extends GetxController {
  static PhoneAuthController get instance => Get.find();

  late final TextEditingController phoneNumber;
  final verificationId = ''.obs;
  final otpSent = false.obs;
  final userId = FirebaseFirestore.instance.collection('Users').doc().id;

  GlobalKey<FormState> phoneAuthFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    phoneNumber = TextEditingController();
  }

  /// Generate OTP
  String generateOtp() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  /// Send OTP via SMS
  Future<bool> sendOtpSms(String otp, String fullPhoneNumber) async {
    final url =
        'https://app.rpsms.in/api/push.json?apikey=6732fa15e03a1&sender=BABYCU&mobileno=$fullPhoneNumber&text=$otp%20is%20the%20OTP%20to%20login%20to%20your%20GIBUD.%20Please%20do%20not%20share%20this%20with%20anyone.%20Thanks%20-%20BabyCue%20Private%20Limited';
    try {
      final response = await http.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// Validate phone number
  bool isValidPhoneNumber(String phone, String countryCode) {
    final Map<String, RegExp> phoneRegex = {
      '+91': RegExp(r'^[6789]\d{9}$'), // India (10 digits, starts with 6-9)
      '+1': RegExp(r'^\d{10}$'), // USA (10 digits)
      '+44': RegExp(r'^7\d{9}$'), // UK (Mobile starts with 7, 10 digits)
      '+61': RegExp(r'^[45]\d{8,9}$'), // Australia (9-10 digits)
      '+81': RegExp(r'^\d{9,10}$'), // Japan (9-10 digits)
      '+49': RegExp(r'^1\d{9}$'), // Germany (10 digits)
      '+86': RegExp(r'^\d{11}$'), // China (11 digits)
      '+33': RegExp(r'^[67]\d{8}$'), // France (9 digits)
    };

    final regex = phoneRegex[countryCode];
    if (regex != null) {
      return regex.hasMatch(phone);
    }

    // Default fallback validation (basic international format)
    return RegExp(r'^\d{6,15}$').hasMatch(phone);
  }

  /// Check if the phone number exists in Firestore
  Future<bool> isPhoneNumberExist(String phone) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .where('phone', isEqualTo: phone)
        .get();
    return userDoc.docs.isNotEmpty;
  }

  /// Send OTP or Navigate Based on Country
  Future<void> handlePhoneAuth(BuildContext context, String fullPhoneNumber, String countryCode) async {
    if (!isValidPhoneNumber(fullPhoneNumber, countryCode)) {
      Loaders.errorSnackBar(
        title: "Invalid Phone Number",
        message: "Enter a valid phone number for your region.",
      );
      return;
    }

    if (countryCode == '+91') {
      /// Proceed with OTP for Indian numbers
      FullScreenLoader.openLoadingDialog(
        "Sending OTP",
        AnimationStrings.loadingAnimation,
      );

      final otp = generateOtp();
      final sent = await sendOtpSms(otp, fullPhoneNumber);

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

      Get.to(() => OtpPage(isSignup: true));
    } else {
      /// Navigate to EmailAuthPage for non-Indian numbers
      Get.to(() => EmailAuth());
    }
  }

  /// Verify OTP
  Future<void> verifyOtp(BuildContext context, String enteredOtp) async {
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

    final phoneExists = await isPhoneNumberExist(phoneNumber.text.trim());
    FullScreenLoader.stopLoading();

    if (phoneExists) {
      Loaders.warningSnackBar(
        title: 'Phone Number exists already',
        message: 'Consider logging in instead of creating a new account',
      );
    } else {
      Get.offAll(() => DetailsPage());
      Loaders.successSnackBar(
        title: "Verification Successful",
        message: "You have been successfully authenticated!",
      );
    }
  }
}
