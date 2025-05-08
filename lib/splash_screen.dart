import 'package:flutter/material.dart';
import 'package:gibud/utils/constants/image_strings.dart';
import 'package:get/get.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/pages/login/login_page.dart';
import 'package:gibud/pages/onboarding/onboarding.dart';
import 'data/repositories/authentication/authentication_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Start the splash logic (redirect to the appropriate screen)
    Future.delayed(const Duration(seconds: 3), () {
      // You can replace this with your screen redirect logic
      AuthenticationRepository.instance.screenRedirect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200, // Light color

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height*0.2,),
            Image.asset("assets/images/splashScreenImage/splash.png", height: 250,),
            SizedBox(height: MediaQuery.of(context).size.height*0.3),
            Image.asset("assets/images/splashScreenImage/banner_image.png", height: 150,),
          ],
        ),
      ),
    );
  }
}
