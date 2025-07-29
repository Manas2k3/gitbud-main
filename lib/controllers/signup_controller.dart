import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/data/repositories/authentication/authentication_repository.dart';
import 'package:gibud/data/repositories/user/user_repository.dart';
import 'package:gibud/pages/signup/widgets/verify_mail.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:gibud/utils/popups/full_screen.dart';
import 'package:gibud/utils/popups/loaders.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../utils/storage/user_model.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  /// Variables
  final hidePassword = true.obs;
  final email = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final selectedRole = 'user'.obs;
  final password = TextEditingController();
  final phoneNumber = TextEditingController();
  final age = TextEditingController();
  final gender = ''.obs;
  final weight = TextEditingController();
  final height = TextEditingController();
  final isPaymentDone = false;
  final privacyPolicy = false.obs;
  final GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();

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

      // Validate the form
      if (!_validateForm()) {
        _hideLoader();
        return;
      }

      // Register the user
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(email.text.trim(), password.text.trim());

      if (userCredential.user == null) {
        throw Exception("User creation failed.");
      }

      // Save user data
      await _saveUserData(userCredential.user!.uid);

      // Fetch and store the OneSignal Push Subscription ID
      await _getPushSubscriptionIdAndStore(userCredential.user!.uid);

      // Fetch and display user data from Firestore
      await _fetchUserData(userCredential.user!.uid);

      _hideLoader();

      // Success snackbar and redirection
      Loaders.successSnackBar(
        title: 'Congratulations!',
        message: "Your account has been created. Verify your email to proceed.",
      );

      Get.to(() => VerifyMail(email: email.text.trim()));
    } catch (e, stackTrace) {
      _handleSignUpError(e, stackTrace);
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

  /// Validate Form
  bool _validateForm() {
    return signUpFormKey.currentState?.validate() ?? false;
  }

  /// Save User Data
  ///
  Future<void> _saveUserData(String userId) async {
    final newUser = UserModel(
      id: userId,
      name: '${firstName.text.trim()} ${lastName.text.trim()}',
      email: email.text.trim(),
      phone: phoneNumber.text.trim(),
      // age: age.text.trim(),
      // gender: gender.value.trim(),
      // weight: weight.text.trim(),
      // height: height.text.trim(),
      gutTestPaymentStatus: isPaymentDone,
      selectedRole: selectedRole.value.trim(),
      createdAt: DateTime.now(),
    );

    final userRepository = Get.put(UserRepository());
    await userRepository.savedUserRecord(newUser);
  }

  /// Fetch and Store OneSignal Push Subscription ID
  Future<void> _getPushSubscriptionIdAndStore(String userId) async {
    try {
      // Retrieve the OneSignal Push Subscription ID
      final pushSubscriptionId = await OneSignal.User.pushSubscription.id;

      if (pushSubscriptionId != null) {
        // Store the Push Subscription ID in Firestore under the user's document
        await FirebaseFirestore.instance.collection('Users').doc(userId).update({
          'onesignalPlayerId': pushSubscriptionId,
        });
        debugPrint("OneSignal Push Subscription ID saved successfully.");
      } else {
        debugPrint("Failed to retrieve OneSignal Push Subscription ID.");
      }
    } catch (error) {
      debugPrint("Error while saving OneSignal Push Subscription ID: $error");
    }
  }

  /// Fetch User Data from Firestore
  Future<void> _fetchUserData(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      debugPrint('User data fetched: $userData');
    } else {
      debugPrint('User document does not exist in Firestore.');
    }
  }

  /// Handle Errors
  void _handleSignUpError(Object e, StackTrace stackTrace) {
    _hideLoader();
    debugPrint("Error occurred during sign-up: $e");
    debugPrint("Stack trace: $stackTrace");

    Future.delayed(const Duration(milliseconds: 100), () {
      Loaders.errorSnackBar(
        title: "Oh Snap!",
        message: e.toString(),
      );
    });
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
