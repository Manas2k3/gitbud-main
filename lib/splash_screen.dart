import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:gibud/data/repositories/authentication/authentication_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () {
      AuthenticationRepository.instance.screenRedirect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),

            // Logo with bounce-in effect
            BounceInDown(
              duration: const Duration(milliseconds: 1200),
              child: Image.asset("assets/images/splashScreenImage/splash.png", height: 250),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            FadeInUp(
              duration: const Duration(milliseconds: 1200),
              child: Image.asset("assets/images/splashScreenImage/banner_image.png", height: 150),
            ),
          ],
        ),
      ),
    );
  }
}
