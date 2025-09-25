import 'dart:convert'; // For utf8.encode()
import 'package:crypto/crypto.dart'; // For hashing
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../data/repositories/authentication/authentication_repository.dart';
import '../data/repositories/user/user_repository.dart';
import '../pages/signup/widgets/verify_mail.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';
import '../utils/storage/user_model.dart';

class Userdetailscontroller extends GetxController {
  static Userdetailscontroller get instance => Get.find();

  // Text Controllers for user details
  final password = TextEditingController();
  final email = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final selectedRole = 'user'.obs;
  final phoneNumber = TextEditingController();
  // final age = TextEditingController();
  // final weight = TextEditingController();
  // final height = TextEditingController();

  String combinedPhoneNumber = '';
  // Observable variables
  // var gender = ''.obs;
  bool isPaymentDone = false;

  // Form Key
  final GlobalKey<FormState> userDetailFormKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // GetStorage key for OTP phone
  static const String otpPhoneKey = 'otp_phone';

  @override
  void onClose() {
    // Dispose controllers
    password.dispose();
    email.dispose();
    firstName.dispose();
    lastName.dispose();
    phoneNumber.dispose();
    super.onClose();
  }

  /// Main method to handle form submission
  void sendDetails(BuildContext context) async {
    try {
      // Show loading
      FullScreenLoader.openLoadingDialog(
        "Processing your details...",
        AnimationStrings.loadingAnimation,
      );

      // Check internet
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading();
        _showNoInternetDialog(context);
        return;
      }

      // Validate form
      if (!(userDetailFormKey.currentState?.validate() ?? false)) {
        FullScreenLoader.stopLoading();
        return;
      }

      // Normalize combinedPhoneNumber: ensure no spaces
      combinedPhoneNumber = combinedPhoneNumber.replaceAll(' ', '').trim();

      // Read stored OTP phone from GetStorage
      final storage = GetStorage();
      final storedOtpPhone = storage.read('otp_phone') as String?;
      if (storedOtpPhone != null) Text("OTP sent to: $storedOtpPhone");

      if (storedOtpPhone == null) {
        FullScreenLoader.stopLoading();
        Loaders.errorSnackBar(
          title: "Session Expired",
          message: "OTP session expired. Please request OTP again.",
        );
        return;
      }

      // Compare canonical formats (both should include country code, e.g. '+91XXXXXXXXXX')
      if (storedOtpPhone.trim() != combinedPhoneNumber) {
        FullScreenLoader.stopLoading();
        Loaders.errorSnackBar(
          title: "Phone Mismatch",
          message: "The phone number you entered does not match the number used for OTP. Please enter the same number.",
        );
        return;
      }

      // Create user account (email/password)
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = userCredential.user;

      if (user != null) {
        // Send verification email using your repository helper
        await AuthenticationRepository.instance.sendEmailVerification();

        final newUser = UserModel(
          id: user.uid,
          name: '${firstName.text.trim()} ${lastName.text.trim()}',
          email: email.text.trim(),
          phone: combinedPhoneNumber,
          selectedRole: selectedRole.value.trim(),
          gutTestPaymentStatus: isPaymentDone,
          createdAt: DateTime.now(),
        );

        final userRepository = Get.put(UserRepository());
        await userRepository.savedUserRecord(newUser);

        // Optional: verify user doc exists
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(newUser.id)
            .get();

        if (userDoc.exists) {
          print('Name fetched: ${userDoc['name'] ?? ''}');
        }

        // Store OneSignal player ID in user's doc
        await _getPushSubscriptionIdAndStore();

        FullScreenLoader.stopLoading();

        // Remove stored OTP phone since we've used it successfully
        await storage.remove(otpPhoneKey);

        Loaders.successSnackBar(
          title: "Email Sent",
          message: "Verification email has been sent. Please verify to continue.",
        );

        Get.offAll(() => VerifyMail(email: email.text.trim()));
      } else {
        FullScreenLoader.stopLoading();
        throw Exception("Failed to create user.");
      }
    } on FirebaseAuthException catch (e) {
      FullScreenLoader.stopLoading();
      String errorMsg;

      switch (e.code) {
        case 'email-already-in-use':
          errorMsg = 'Email is already registered. Please use a different email.';
          break;
        case 'invalid-email':
          errorMsg = 'Invalid email format. Please check your email.';
          break;
        case 'operation-not-allowed':
          errorMsg = 'Email/password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMsg = 'Password is too weak. Please choose a stronger password.';
          break;
        default:
          errorMsg = 'Authentication failed. Please try again.';
      }

      print('FirebaseAuthException: $errorMsg');
      Loaders.errorSnackBar(
        title: "Signup Error",
        message: errorMsg,
      );
    } catch (e) {
      FullScreenLoader.stopLoading();
      print('Error in sendDetails: $e');
      Loaders.errorSnackBar(
        title: "Error",
        message: "Something went wrong. Please try again.",
      );
    }
  }

  /// Function to get OneSignal Push Subscription ID and store it in Firestore
  Future<void> _getPushSubscriptionIdAndStore() async {
    // Check if the user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        // Retrieve the OneSignal Push Subscription ID
        final pushSubscriptionId = await OneSignal.User.pushSubscription.id;

        if (pushSubscriptionId != null) {
          // Store the Push Subscription ID in Firestore under the user's document
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(currentUser.uid) // Use the current user ID
              .update({
            'onesignalPlayerId': pushSubscriptionId,
          });
          print("OneSignal Push Subscription ID saved successfully.");
        } else {
          print("Failed to retrieve OneSignal Push Subscription ID.");
        }
      } catch (error) {
        print("Error while saving OneSignal Push Subscription ID: $error");
      }
    } else {
      print("No user logged in. Cannot fetch OneSignal Push Subscription ID.");
    }
  }

  /// Hash the password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final hash = sha256.convert(bytes); // Perform SHA-256 hash
    return hash.toString(); // Return hashed password as a string
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
