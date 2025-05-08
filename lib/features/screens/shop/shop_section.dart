import 'package:flutter/material.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ShopSection extends StatelessWidget {
  const ShopSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.indigo,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      "Shop Section",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                    )
                ],
              ),
            ),

            Center(
              child: Lottie.asset(AnimationStrings.comingSoonAnimation, height: 200)
            )
          ],
        ),
      ),
    );
  }
}
