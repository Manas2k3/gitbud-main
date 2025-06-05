import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/controllers/survey_controller.dart';
import 'package:gibud/survey/survey_result.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../data/repositories/survey/survey_questions.dart';
import '../secrets.dart';
import '../survey/survey_screen.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';

class GutTestController extends GetxController {
  final SurveyController surveyController = Get.put(SurveyController());
  Map<int, String> selectedResponses = {};
  String? gender;

  late Razorpay _razorpay;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  void openCheckout(double amount) async {
    var options = {
      'key': key,
      'amount': amount * 100, // Amount in paise
      'name': 'GiBud Gut Health Test',
      'description': 'Payment for Gut Health Test',
      'prefill': {'email': FirebaseAuth.instance.currentUser!.email},
    };
    try {
      FullScreenLoader.openLoadingDialog(
          "We are proceeding to the payment", AnimationStrings.loadingAnimation);
      _razorpay.open(options);
    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(
          title: "Error", message: "Unable to open Razorpay.");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    FullScreenLoader.openLoadingDialog(
      "Completing your transaction",
      AnimationStrings.loadingAnimation,
    );

    try {
      await _firestore.collection('Users').doc(userId).update({
        'gutTestPaymentStatus': true,
      });

      FullScreenLoader.stopLoading();

      // Ensure the context is valid and navigation happens smoothly
      if (Get.context != null) {
        await _submitSurvey(Get.context!);
      } else {
        // Fallback in case context is null
        Get.off(() => SurveyResultScreen(
          responses: selectedResponses,
          calculatedTotalScore: surveyController.totalScore.value,
          resultCategory: null,
        ));
      }
    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(
        title: "Error",
        message: "Failed to complete payment process.",
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    FullScreenLoader.stopLoading();
    Get.dialog(AlertDialog(
      title: Text("Payment Failed"),
      content: Text("Something went wrong. Please try again."),
      actions: [
        TextButton(
            onPressed: () {
              Get.back(); // Dismiss the dialog and return to the previous screen
            },
            child: Text("OK"))
      ],
    ));
  }

  Future<void> _submitSurvey(BuildContext context) async {
    try {
      FullScreenLoader.openLoadingDialog(
        "Submitting your survey...",
        AnimationStrings.loadingAnimation,
      );

      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading();
        _showNoInternetDialog(context);
        return;
      }

      // Calculate the number of questions the user is expected to answer
      int requiredResponsesCount = surveyQuestions.where((question) {
        // Exclude questions based on gender if applicable
        return !(question.stringResourceId == 2131820790 && gender != 'Female');
      }).length;

      if (selectedResponses.length == requiredResponsesCount) {
        await surveyController.submitSurvey(context);

        FullScreenLoader.stopLoading();
        Loaders.successSnackBar(
          title: 'Response Recorded',
          message: 'Your responses have been recorded successfully!',
        );

        Get.to(SurveyResultScreen(
          responses: selectedResponses,
          calculatedTotalScore: surveyController.totalScore.value,
          resultCategory: null,
        ));
      } else {
        FullScreenLoader.stopLoading();
        Loaders.warningSnackBar(
          title: 'Please answer all questions',
          message: "",
        );
      }
    } catch (e) {
      FullScreenLoader.stopLoading();
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showNoInternetDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text("No Internet Connection"),
        content: Text("Please check your internet connection and try again."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("OK"),
          )
        ],
      ),
    );
  }
}
