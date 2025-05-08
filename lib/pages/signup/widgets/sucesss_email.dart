import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../common/components/custom_button.dart';
import '../../../navigation_menu.dart';
import '../../../utils/constants/image_strings.dart';
import '../../login/login_page.dart';

class SucesssEmail extends StatelessWidget {
  const SucesssEmail({super.key, required this.image, required this.title, required this.subTitle, required this.onPressed});

  final String image, title, subTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.offAll(() => const LoginPage()),
          icon: const Icon(CupertinoIcons.clear),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
            crossAxisAlignment: CrossAxisAlignment.center, // Centers horizontally
            children: [
              /// Image
              Lottie.asset('assets/animations/successfully_registered.json'),
              // Image.asset(ImageStrings.successEmail),
              // const SizedBox(height: 15),

              /// Title and Subtitle
              Text(
                'Your email has been verified successfully!',
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),

              /// Button
              CustomButton(initialColor: Colors.redAccent, pressedColor: Colors.redAccent.shade100,buttonText: 'Continue', onTap: () => Get.to(LoginPage())),
            ],
          ),
        ),
      ),
    );
  }
}
