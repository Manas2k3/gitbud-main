import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/pages/signup/signup_page.dart';
import 'package:gibud/pages/signup/widgets/verify_mail.dart';

import '../../../features/screens/gut_test/gut_test_screen.dart';
import '../../../pages/onboarding/onboarding.dart';
import '../../../splash_screen.dart';
import '../../../survey/survey_screen.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  /// Variables
  final deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void onReady() {
    // Replace FlutterNativeSplash with our custom SplashScreen
    Get.offAll(() => const SplashScreen()); // Directly navigate to SplashScreen
  }

  /// Function to determine the screen redirection based on user status
  Future<void> screenRedirect() async {
    User? user = _auth.currentUser;

    if (user != null) {
      if (user.emailVerified) {
        // ✅ Check if Firestore document exists
        final userDoc = await _firestore.collection('Users').doc(user.uid).get();

        if (userDoc.exists) {
          // Normal flow: user is verified and has Firestore data
          Get.offAll(() => NavigationMenu());
        } else {
          // 🚨 User logged in but no Firestore data
          await _auth.signOut(); // clear the broken session
          Get.offAll(() => const SignupPage());
        }
      } else {
        // Email not verified
        Get.offAll(() => VerifyMail(
          email: _auth.currentUser?.email,
        ));
      }
    } else {
      // First-time user or logged-out user
      deviceStorage.writeIfNull('isFirstTime', true);
      deviceStorage.read('isFirstTime') != true
          ? Get.offAll(() => const LoginPage())
          : Get.offAll(() => const OnboardingPage());
    }
  }


  /// Function to register credentials with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // More detailed logging
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'email-already-in-use':
          throw 'Email is already registered. Please use a different email.';
        case 'invalid-email':
          throw 'Invalid email format. Please check your email.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        case 'weak-password':
          throw 'Password is too weak. Please choose a stronger password.';
        default:
          throw 'Authentication failed. Please try again.';
      }
    } catch (e) {
      debugPrint('Unexpected error during registration: $e');
      throw 'Something went wrong. Please try again.';
    }
  }

  /// Function that sends email verification to the registered email id
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(message: e.message, code: e.code);
    } on FirebaseException catch (e) {
      throw FirebaseException(message: e.message, code: e.code, plugin: '');
    } on FormatException {
      throw const FormatException('Invalid format.');
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  /// Function to log in using email and password
  Future<UserCredential> loginWithEmailandPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(message: e.message, code: e.code);
    } on FirebaseException catch (e) {
      throw FirebaseException(message: e.message, code: e.code, plugin: '');
    } on FormatException {
      throw const FormatException('Invalid format.');
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  /// Function for the forget password functionality
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(message: e.message, code: e.code);
    } on FirebaseException catch (e) {
      throw FirebaseException(message: e.message, code: e.code, plugin: '');
    } on FormatException {
      throw const FormatException('Invalid format.');
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  /// Function to log out from the signed-in account
  Future<void> logOut() async {
    try {
      await _auth.signOut();
      Get.offAll(() => const LoginPage());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(message: e.message, code: e.code);
    } on FirebaseException catch (e) {
      throw FirebaseException(message: e.message, code: e.code, plugin: '');
    } on FormatException {
      throw const FormatException('Invalid format.');
    } on PlatformException catch (e) {
      throw PlatformException(message: e.message, code: e.code);
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }
}
