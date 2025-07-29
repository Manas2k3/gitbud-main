import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 👈 Added for SVG support

import 'package:gibud/utils/constants/image_strings.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/features/screens/gut_test/widget_pages/additional_details_page.dart';
import '../../../survey/survey_screen.dart';

class GutTestScreen extends StatelessWidget {
  const GutTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        title: Text(
          "Gut Test",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header title
              Text(
                "Instructions for taking Gut Test",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 24),

              /// Instruction Cards
              _buildInstructionCard(
                iconAsset: ImageStrings.honestImage,
                title: "Answer honestly",
                description:
                "Please answer honestly to help us better understand your gut health, symptoms, and lifestyle.",
              ),
              const SizedBox(height: 16),
              _buildInstructionCard(
                iconAsset: ImageStrings.lockImage,
                title: "Confidentiality",
                description:
                "Your information is completely confidential and protected under strict data privacy standards.",
              ),
              const SizedBox(height: 16),
              _buildInstructionCard(
                iconAsset: ImageStrings.informationImage,
                title: "Informational tool",
                description:
                "This survey is meant for informational purposes only and does not replace professional medical advice.",
              ),
              const SizedBox(height: 24),

              /// Note
              Text(
                "Note: For specific health concerns, always consult with a healthcare professional.",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height*0.07),

              /// Start Button
              Center(
                child: CustomButton(
                  buttonText: 'Start Gut Health Test',
                  onTap: () async {
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final docSnapshot = await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(user.uid)
                          .get();

                      final data = docSnapshot.data();
                      if (data != null &&
                          data.containsKey('gender') &&
                          data['gender'] != null) {
                        Get.to(() => SurveyScreen());
                      } else {
                        Get.to(() => AdditionalDetailsPage());
                      }
                    } catch (e) {
                      debugPrint("🔥 Error checking gender field: $e");
                    }
                  },
                  initialColor: Colors.green,
                  pressedColor: Colors.greenAccent.shade100,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for instruction cards
  Widget _buildInstructionCard({
    required String iconAsset,
    required String title,
    required String description,
  }) {
    bool isSvg = iconAsset.toLowerCase().endsWith('.svg');

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Icon/Image
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: isSvg
                ? SvgPicture.asset(
              iconAsset,
              fit: BoxFit.contain,
            )
                : Image.asset(
              iconAsset,
              fit: BoxFit.contain,
            ),
          ),

          /// Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
