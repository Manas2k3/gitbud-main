// lib/app.dart

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:gibud/bindings/general_bindings.dart';
import 'package:gibud/splash_screen.dart';

import 'chat/individual_chat_page.dart';


class MyApp extends StatefulWidget {
  
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override


  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorObservers: [AppNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      initialBinding: GeneralBindings(),
      home: const SplashScreen(),
    );
  }
}
