import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../utils/constants/animation_strings.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';

class LoginController extends GetxController {
  // Controllers for the email and password fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final loginFormKey = GlobalKey<FormState>();

  /// Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Function to handle login using Firebase Authentication
  Future<void> loginWithEmail(BuildContext context) async {
    try {
      // Show loading dialog
      FullScreenLoader.openLoadingDialog(
        "Signing you in...",
        AnimationStrings.loadingAnimation,
      );

      // Get user input
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      // Validate the form fields
      if (!loginFormKey.currentState!.validate()) {
        Get.back(); // Close the loading dialog
        return;
      }

      // Authenticate user with Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('Users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Retrieve the user data from Firestore
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Access user data from Firestore
          String name = userData['name'] ?? 'No name available';
          String phone = userData['phone'] ?? 'No phone available';
          String gender = userData['gender'] ?? 'No gender available';
          String email = userData['email'] ?? 'No email available';

          // Print or use the fetched user data as required
          print('Name: $name');
          print('Phone: $phone');
          print('Gender: $gender');
          print('Email: $email');

          // Call the function to store the OneSignal Push Subscription ID
          await _getPushSubscriptionIdAndStore();

          // Proceed to the navigation menu after successful login and data retrieval
          Loaders.successSnackBar(
            title: "Login Successful",
            message: "Login successful and data fetched!",
          );
          Get.offAll(() => NavigationMenu());
        } else {
          // Handle case where user document doesn't exist
          Loaders.errorSnackBar(
            title: 'User does not exist!',
            message: 'Consider creating an account first',
          );
        }
      } else {
        throw Exception("Failed to log in.");
      }
    } on FirebaseAuthException catch (e) {
      // Display an appropriate error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getFirebaseAuthErrorMessage(e)),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      Loaders.errorSnackBar(title: 'Oops!', message: 'An error occurred');
    } finally {
      Get.back(); // Close the loading dialog
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

  /// Error message mapper for Firebase Authentication
  String _getFirebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}
