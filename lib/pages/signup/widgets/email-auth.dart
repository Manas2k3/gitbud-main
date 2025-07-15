import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/controllers/signup_controller.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/pages/privacy_policy_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/formatters/formatters.dart';

class EmailAuth extends StatefulWidget {
  const EmailAuth({super.key});

  @override
  State<EmailAuth> createState() => _EmailAuthState();
}

class _EmailAuthState extends State<EmailAuth> {
  final controller = Get.put(SignUpController());
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.offAll(() => const LoginPage()),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeading(),
              const SizedBox(height: 25),
              Form(
                key: controller.signUpFormKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: controller.email,
                      label: "Enter your email",
                      prefixIcon: const Icon(Iconsax.direct_right),
                      validator: InputValidators.validateEmail,
                    ),
                    const SizedBox(height: 25),
                    _buildPasswordField(),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: controller.firstName,
                      label: "First Name",
                      prefixIcon: const Icon(Iconsax.direct_right),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: controller.lastName,
                      label: "Last Name",
                      prefixIcon: const Icon(Iconsax.direct_right),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: controller.phoneNumber,
                      label: "Phone Number (with country code)",
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty == true
                          ? 'Phone Number is required'
                          : null,
                    ),
                    const SizedBox(height: 25),
                    _buildRoleSelection(),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: controller.age,
                      label: "Age",
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    const SizedBox(height: 25),
                    _buildDropdownField(),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: controller.weight,
                      label: "Weight (in Kgs)",
                      prefixIcon: const Icon(Icons.fitness_center),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                      controller: controller.height,
                      label: "Height (in cms)",
                      prefixIcon: const Icon(Icons.height),
                    ),
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text("By continuing, I accept the",style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),),
                          TextButton(onPressed: () => Get.to(PrivacyPolicyPage()), child: Text("Privacy Policy", style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),))
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Authenticate with your email',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "We are unable to proceed with the entered phone number. Please use your email to proceed ahead!",
          style: GoogleFonts.poppins(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    Icon? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
        ),
      ),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
          prefixIcon: prefixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField() {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
        ),
      ),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        controller: controller.password,
        obscureText: _obscureText,
        decoration: InputDecoration(
          labelText: "Enter your password",
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.redAccent,
            ),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
        validator: (value) => value != null && value.length < 6
            ? 'Password must be at least 6 characters'
            : null,
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Specify Your Role:',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        Obx(
              () => Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        'User',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      leading: Radio<String>(
                        activeColor: Colors.redAccent,
                        value: 'user',
                        groupValue: controller.selectedRole.value,
                        onChanged: (value) {
                          controller.selectedRole.value = value!;
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      'Dietician',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: Radio<String>(
                      activeColor: Colors.redAccent,
                      value: 'dietician',
                      groupValue: controller.selectedRole.value,
                      onChanged: (value) {
                        controller.selectedRole.value = value!;
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildPrivacyPolicyCheckbox() {
  //   return Row(
  //     children: [
  //       Obx(() => Checkbox(
  //         activeColor: Colors.redAccent,
  //             value: controller.privacyPolicy.value,
  //             onChanged: (value) => controller.privacyPolicy.value = value!,
  //           )),
  //       Text("I agree to the",
  //           style: GoogleFonts.poppins(color: Colors.black)),
  //       TextButton(
  //         onPressed: () => Get.to(() => PrivacyPolicyPage()),
  //         child: Text(
  //           "Privacy Policy",
  //           style: GoogleFonts.poppins(
  //             color: Colors.redAccent,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: CustomButton(
        initialColor: Colors.redAccent,
        pressedColor: Colors.redAccent.shade100,
        buttonText: "Submit",
        onTap: () => controller.signUp(context),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Obx(() => DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: "Select Gender",
            labelStyle: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
          value:
              controller.gender.value.isEmpty ? null : controller.gender.value,
          items: ['Male', 'Female', 'Other'].map((String gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(
                gender,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (String? value) {
            if (value != null) {
              controller.gender.value = value;
            }
          },
          validator: (value) => value == null ? 'Please select a gender' : null,
        ));
  }
}
