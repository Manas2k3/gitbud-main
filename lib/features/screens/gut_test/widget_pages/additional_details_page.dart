import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/components/custom_button.dart';
import '../../../../controllers/additionalDetailsController.dart';
import '../../../../utils/formatters/formatters.dart';

class AdditionalDetailsPage extends StatelessWidget {
  const AdditionalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdditionalDetailsController());
    final size = MediaQuery.of(context).size;

    InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.red.shade50,
      labelStyle: GoogleFonts.poppins(color: Colors.red.shade300),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "About You",
          style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Let's Get to Know You Better!",
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                "These additional details will help us gain deeper insights and guide you better. Please fill them in to proceed with the questionnaire.",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
              ),
              const SizedBox(height: 32),

              // Age
              Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                  ),
                ),
                child: TextFormField(
                  cursorColor: Colors.black,
                  controller: controller.age,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: ageValidator,
                  decoration: _inputDecoration("Age"),
                ),
              ),
              const SizedBox(height: 16),

              // Height
              Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                  ),
                ),
                child: TextFormField(
                  controller: controller.height,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: heightValidator,
                  decoration: _inputDecoration("Height (cm)"),
                ),
              ),
              const SizedBox(height: 16),

              // Weight
              Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                  ),
                ),
                child: TextFormField(
                  controller: controller.weight,
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: weightValidator,
                  decoration: _inputDecoration("Weight (kg)"),
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                value: controller.gender.value.isNotEmpty ? controller.gender.value : null,
                onChanged: (value) {
                  if (value != null) controller.gender.value = value;
                },
                items: ['Male', 'Female', 'Other'].map(
                      (gender) => DropdownMenuItem(
                    value: gender,
                    child: Text(gender, style: GoogleFonts.poppins()),
                  ),
                ).toList(),
                decoration: _inputDecoration("Gender"),
                validator: (value) =>
                (value == null || value.isEmpty) ? "Please select a gender" : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          width: double.infinity,
          child: CustomButton(
            buttonText: "Continue",
            initialColor: Colors.redAccent,
            pressedColor: Colors.redAccent.shade100,
            onTap: () => controller.updateAdditionalDetails(context),
          ),
        ),
      ),
    );
  }
}
