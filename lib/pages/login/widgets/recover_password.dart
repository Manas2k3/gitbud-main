import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/controllers/forget_password_controller.dart';
import 'package:gibud/pages/login/widgets/reset_password.dart';
import 'package:gibud/utils/formatters/formatters.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../login_page.dart';

class RecoverPassword extends StatelessWidget {
  const RecoverPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.offAll(() => const LoginPage()),
          icon: const Icon(Icons.arrow_back), // Use back arrow
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Heading
            Text(
              'Recover your password',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600, // Added proper styling
              ),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              "Don't worry we've got your back, enter your email and we will send you a password reset link",
              textAlign: TextAlign.start,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),

            SizedBox(height: 25),

            Form(
              key: controller.forgetPasswordFormKey,
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionHandleColor: Colors.redAccent, // 👈 Change this to your desired color
                  ),
                ),
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: controller.email,
                  decoration: InputDecoration(
                    floatingLabelStyle: TextStyle(color: Colors.grey.shade700),
                    labelText: "Enter your email", labelStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade700, fontWeight: FontWeight.bold
                  ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.black)
                    ),
                    prefixIcon: Icon(Iconsax.direct_right),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)
                    )
                  ),
                  validator: InputValidators.validateEmail,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(40.0),
              child: CustomButton(initialColor: Colors.redAccent, pressedColor: Colors.redAccent.shade100,buttonText: "Submit", onTap: () => ForgetPasswordController.instance.sendPasswordResetMail(context)),
            )
            // You can add further widgets for email input, recovery steps, etc.
          ],
        ),
      ),
    );
  }
}
