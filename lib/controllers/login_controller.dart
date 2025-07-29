import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../data/repositories/authentication/authentication_repository.dart';
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
      // Show loading animation
      FullScreenLoader.openLoadingDialog(
        "Signing you in...",
        AnimationStrings.loadingAnimation,
      );

      // Get input
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      // Validate form
      if (!loginFormKey.currentState!.validate()) return;

      // Call the repository login function
      final authRepo = AuthenticationRepository.instance;
      UserCredential userCredential =
      await authRepo.loginWithEmailandPassword(email, password);

      final User? user = userCredential.user;

      if (user != null) {
        // Fetch user data from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final userData = doc.data()!;

          print("Name: ${userData['name']}");
          print("Phone: ${userData['phone']}");
          print("Gender: ${userData['gender']}");
          print("Email: ${userData['email']}");

          // Save push subscription
          await _getPushSubscriptionIdAndStore();

          // Success!
          Loaders.successSnackBar(
            title: "Login Successful",
            message: "Welcome back!",
          );
          Get.offAll(() => NavigationMenu());
        } else {
          Loaders.errorSnackBar(
            title: "User Not Found",
            message: "No user profile found. Please sign up first.",
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Try again.';
          break;
        case 'invalid-email':
          message = 'That email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        default:
          message = 'Authentication failed. ${e.message}';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on FirebaseException catch (e) {
      Loaders.errorSnackBar(
        title: 'Firebase Error',
        message: e.message ?? 'An unknown Firebase error occurred.',
      );
    } on PlatformException catch (e) {
      Loaders.errorSnackBar(
        title: 'Platform Error',
        message: e.message ?? 'Something went wrong on the platform side.',
      );
    } on FormatException catch (_) {
      Loaders.errorSnackBar(
        title: 'Invalid Format',
        message: 'Check your input fields.',
      );
    } catch (e) {
      Loaders.errorSnackBar(
        title: 'Oops!',
        message: e.toString(),
      );
    } finally {
      Get.back(); // close loading dialog
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
