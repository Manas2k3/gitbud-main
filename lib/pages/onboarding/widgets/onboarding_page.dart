import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';


class onBoardingPage extends StatelessWidget {
  const onBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  final String image, title, subTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Image(
            width: MediaQuery.of(Get.context!).size.width * 0.8,
            height: MediaQuery.of(Get.context!).size.height * 0.6,
            image: AssetImage(image),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            subTitle,
            style: GoogleFonts.poppins(fontSize: 16),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}
