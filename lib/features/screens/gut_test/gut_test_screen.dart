import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
// import 'package:gibud/payment/payments_page.dart'; // Commented out for now
import 'package:google_fonts/google_fonts.dart';
import '../../../payment/payments_page.dart';
import '../../../survey/survey_screen.dart';
import '../tongue_image/tongue_image.dart';

class GutTestScreen extends StatelessWidget {
  const GutTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header
            PrimaryHeaderContainer(
              color: Colors.green,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      "Gut Test",
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade200,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                ],
              ),
            ),

            /// Instructions
            /// Instructions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Instructions for taking Gut Test",
                        textAlign: TextAlign.start,
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // New Section for Tongue Analysis Instruction
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We're working on a feature that will provide helpful insights based on your tongue image. "
                              "To assist with this, please capture a clear picture of your tongue under good lighting. "
                              "Use the example image below as a reference:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/tongue_image.jpg',
                            height: MediaQuery.of(context).size.height*0.4,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Original Instructions
                  Column(
                    children: [
                      Text(
                        "1. Answer each question as honestly and accurately as possible.\n"
                            "2. Your privacy is our utmost priority; all responses provided in this "
                            "questionnaire are strictly confidential.\n"
                            "3. While this questionnaire provides insights into your gut health, it is "
                            "not a substitute for professional medical advice.\n",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        "Note: If you have specific concerns about your gut health or any medical "
                            "conditions, please consult a healthcare professional.",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  /// Button to start Gut Health Test
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CustomButton(
                      buttonText: 'Start Gut Health Test',
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
                        final userName = userDoc['name'] as String;
                        final safeFileName = userName.replaceAll(' ', '_');
                        final fileName = '$safeFileName.jpg';
                        final storageRef = FirebaseStorage.instance.ref().child('tongue_images/$fileName');

                        try {
                          // Check if the file exists
                          await storageRef.getDownloadURL();

                          // File exists: Go to SurveyScreen
                          Get.to(() => SurveyScreen());
                        } catch (e) {
                          // File doesn't exist: Go to TongueImage screen
                          Get.to(() => TongueImage());
                        }
                      },

                      // onTap: () => Get.to(SurveyScreen()),
                      initialColor: Colors.green,
                      pressedColor: Colors.greenAccent.shade100,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
