import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/controllers/verify_email_controller.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/pages/signup/widgets/sucesss_email.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../utils/constants/animation_strings.dart';
import '../../../utils/constants/image_strings.dart';

class VerifyMail extends StatelessWidget {
  const VerifyMail({super.key, required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => AuthenticationRepository.instance.logOut(),
          icon: const Icon(CupertinoIcons.clear),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              /// Image
              Image.asset(ImageStrings.verifyEmail),
              const SizedBox(height: 15),

              /// Title and Subtitle
              Text(
                'Verify Your Email Address!',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w600),
              ),

              SizedBox(
                height: 10,
              ),
              Text(
                'Your account has been created sucessfully, please do verify your email to proceed ahead',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(),
              ),
              SizedBox(height: 25),

              Column(
                children: [
                  Text('Mail has been sent to '),
                  Text('$email', style: GoogleFonts.poppins(color: Colors.blue, fontSize: 18),)
                ],
              ),
              /// Buttons (you can add your buttons here)

              // CustomButton(color: Colors.redAccent,buttonText: 'Continue', onTap: () => controller.checkEmailVerificationStatus()),

              SizedBox(height: 10),

              TextButton(
                onPressed: () => controller.sendEmailVerification(),
                child: Text(
                  'Resend Email',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
