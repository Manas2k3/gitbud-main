import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/controllers/gut_test_controller.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation_menu.dart';

class PaymentsPage extends StatelessWidget {
  final Map<int, String> selectedResponses;
  final String? gender;

  PaymentsPage({
    required this.selectedResponses,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(NavigationMenu());
        return false;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // PrimaryHeaderContainer with CustomAppBar
              PrimaryHeaderContainer(
                color: Colors.blue,
                child: Column(
                  children: [
                    CustomAppBar(
                      showBackArrow: true,
                      leadingOnPressed: () {
                        Get.back();
                      },
                      title: Column(
                        children: [
                          Text(
                            "Payment Page",
                            style: GoogleFonts.poppins(color: Colors.grey.shade200),
                          ),
                        ],
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            // Add any additional action or navigation here
                          },
                          icon: const Icon(
                            Icons.payment,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 50,),
                  ],
                ),
              ),

              // Body content for PaymentsPage
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.25, // Adjusted height
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Instructional text
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Text(
                                "To get a detailed report for the survey, you need to pay:",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            // ₹21 in a bigger font
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                "₹51",
                                style: GoogleFonts.poppins(
                                  fontSize: 40, // Bigger font size for ₹21
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            // Purchase button
                            TextButton(
                              onPressed: () {
                                GutTestController controller = Get.put(GutTestController());
                                controller.selectedResponses = selectedResponses;
                                controller.gender = gender;
                                controller.openCheckout(51); // Example amount
                              },
                              child: const Text(
                                "Purchase",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
