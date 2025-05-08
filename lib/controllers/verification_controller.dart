import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/user/user_repository.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import '../utils/storage/user_model.dart'; // Import UserModel for Firestore

class VerificationController extends GetxController {
  static VerificationController get instance => Get.find();

  final otpController = TextEditingController();
  final verificationId = ''.obs; // Store verification ID for OTP verification
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final selectedRole = 'user'.obs;
  final phoneNumber = TextEditingController();
  final age = TextEditingController();
  var gender = ''.obs; // Added gender
  final weight = TextEditingController();
  final height = TextEditingController();

  /// Method to verify OTP
  Future<void> verifyOtp(BuildContext context) async {
    try {
      FullScreenLoader.openLoadingDialog(
        "Verifying OTP...",
        "assets/animations/loading.json",
      );

      if (otpController.text.trim().isEmpty) {
        FullScreenLoader.stopLoading();
        Loaders.warningSnackBar(
          title: "Invalid OTP",
          message: "Please enter the OTP sent to your phone.",
        );
        return;
      }

      // Create a phone auth credential using the verification ID and the user-provided OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpController.text.trim(),
      );

      // Sign in the user with the created credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      FullScreenLoader.stopLoading();
      Loaders.successSnackBar(
        title: "Verification Successful",
        message: "Your phone number has been verified.",
      );

      // Update user data in Firestore
      await _updateUserData();
    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(
        title: "Verification Failed",
        message: e.toString(),
      );
    }
  }

  /// Method to update user data in Firestore
  Future<void> _updateUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newUser = UserModel(
        id: user.uid,
        name: '${firstName.text.trim()} ${lastName.text.trim()}',
        phone: phoneNumber.text.trim(),
        age: age.text.trim(),
        selectedRole: selectedRole.value.trim(),
        gender: gender.value.trim(),
        weight: weight.text.trim(),
        height: height.text.trim(),
        email: '', gutTestPaymentStatus: false, createdAt: DateTime.now(),
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.savedUserRecord(newUser);
    }
  }
}

