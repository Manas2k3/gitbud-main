import 'dart:convert'; // For utf8.encode()
import 'package:crypto/crypto.dart'; // For hashing
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../data/repositories/user/user_repository.dart';
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
  final age = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();

  String combinedPhoneNumber = '';
  // Observable variables
  var gender = ''.obs;
  bool isPaymentDone = false;

  // Form Key
  final GlobalKey<FormState> userDetailFormKey = GlobalKey<FormState>();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Main method to handle form submission
  void sendDetails(BuildContext context) async {
    try {
      // Show loading dialog
      FullScreenLoader.openLoadingDialog(
        "Processing your details...",
        AnimationStrings.loadingAnimation,
      );

      // Check internet connectivity
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading();
        _showNoInternetDialog(context);
        return;
      }

      // Validate the form
      if (!userDetailFormKey.currentState!.validate()) {
        FullScreenLoader.stopLoading();
        return;
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Save user details to Firestore
        final newUser = UserModel(
          id: user.uid,
          name: '${firstName.text.trim()} ${lastName.text.trim()}',
          email: email.text.trim(),
          phone: combinedPhoneNumber, // Save combined phone number
          age: age.text.trim(),
          gender: gender.value.trim(),
          weight: weight.text.trim(),
          selectedRole: selectedRole.value.trim(),
          height: height.text.trim(),
          gutTestPaymentStatus: isPaymentDone,
          createdAt: DateTime.now(),
        );

        final userRepository = Get.put(UserRepository());
        await userRepository.savedUserRecord(newUser);

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(newUser.id)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          print('Name fetched: ${userData['name'] ?? ''}');
        } else {
          print('User document does not exist in Firestore.');
        }

        // Fetch and store the OneSignal Push Subscription ID
        await _getPushSubscriptionIdAndStore();

        FullScreenLoader.stopLoading();
        Loaders.successSnackBar(
          title: "Success",
          message: "Account created successfully and details saved!",
        );
        Get.to(() => LoginPage());
      } else {
        throw Exception("Failed to create user.");
      }
    } catch (e) {
      FullScreenLoader.stopLoading();
      print('Error in sendDetails: $e');
      Loaders.errorSnackBar(
        title: "Error",
        message: "Failed to process details. Please try again.",
      );
    }
  }

  /// Function to get OneSignal Push Subscription ID and store it in Firestore
// Function to get OneSignal Push Subscription ID and store it in Firestore
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
