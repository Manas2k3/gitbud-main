import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/chat_payment_controller.dart';

class ChatPayment extends StatelessWidget {
  final String currentUserId;
  final String userRole;
  final String dieticianId;

  ChatPayment({
    required this.currentUserId,
    required this.userRole,
    required this.dieticianId,
  });

  @override
  Widget build(BuildContext context) {
    final ChatPaymentController controller = Get.put(ChatPaymentController(
      currentUserId: currentUserId,
      userRole: userRole,
      dieticianId: dieticianId,
    ));

    const double paymentAmount = 51.0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Container
            Container(
              color: Colors.blue,
              child: Column(
                children: [
                  AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    title: Text(
                      "Payment Page",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),

            // Payment Section
            Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Instruction Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "To access the consultation feature with our dieticians, payment is required:",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      SizedBox(height: 15),

                      // Payment Amount
                      Text(
                        "₹$paymentAmount",
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 15),

                      ///Purchase Button
                      TextButton(onPressed: ()=> controller.openCheckout(paymentAmount), child: Text("Purchase", style: GoogleFonts.poppins(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),))
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
