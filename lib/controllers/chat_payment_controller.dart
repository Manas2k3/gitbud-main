import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../secrets.dart';
import '../utils/constants/animation_strings.dart';
import '../utils/popups/full_screen.dart';
import '../utils/popups/loaders.dart';
import '../chat/chat_page.dart';

class ChatPaymentController extends GetxController {
  late Razorpay _razorpay;
  final String currentUserId;
  final String userRole;
  final String dieticianId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatPaymentController({
    required this.currentUserId,
    required this.userRole,
    required this.dieticianId,
  });

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
      'amount': amount * 100, // Convert to paise
      'name': 'GiBud Gut Health Test',
      'description': 'Payment for consultation',
      'prefill': {'email': FirebaseAuth.instance.currentUser!.email},
    };

    try {
      FullScreenLoader.openLoadingDialog(
        "We are proceeding to the payment",
        AnimationStrings.loadingAnimation,
      );
      _razorpay.open(options);
    } catch (e) {
      FullScreenLoader.stopLoading();
      Loaders.errorSnackBar(
        title: "Error",
        message: "Unable to open Razorpay.",
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    FullScreenLoader.openLoadingDialog(
      "Completing your transaction",
      AnimationStrings.loadingAnimation,
    );

    try {
      // Update payment status in Firestore
      await _firestore.collection('Users').doc(currentUserId).update({
        'gutTestPaymentStatus': true,
      });

      FullScreenLoader.stopLoading();

      // Navigate to the chat page
      Get.off(() => ChatPage(
        currentUserId: currentUserId,
        userRole: userRole,
        dieticianId: dieticianId,
      ));
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
            Get.back(); // Dismiss the dialog
          },
          child: Text("OK"),
        )
      ],
    ));
  }
}
