import 'package:flutter/material.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/animation_strings.dart';

class KidsSection extends StatelessWidget {
  const KidsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.orange,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      'Kids Section',
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade200, fontSize: 18),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
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
