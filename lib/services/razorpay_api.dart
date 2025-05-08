import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';

import '../secrets.dart';

class RazorpayService {
  late Razorpay _razorpay;

  RazorpayService() {
    _razorpay = Razorpay();
  }

  void openCheckout({
    required String orderId,
    required String email,
    required int amount,
    required void Function(PaymentSuccessResponse) onSuccess,
    required void Function(PaymentFailureResponse) onError,
  }) {
    var options = {
      'key': key,
      'order_id': orderId,
      'amount': amount,
      'currency': 'INR',
      'name': 'Babycue Pvt. Ltd',
      'description': 'Gut Health Test',
      'prefill': {'email': email},
    };

    try {
      _razorpay.open(options);
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    } catch (e) {
      debugPrint('Error in opening Razorpay: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
