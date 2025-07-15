// lib/app.dart

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:gibud/bindings/general_bindings.dart';
import 'package:gibud/splash_screen.dart';

import 'chat/individual_chat_page.dart';
import 'features/screens/home/home_page.dart';
import 'features/screens/tongue_analysis/widgets/TongueAnalysisResultPage.dart';


class MyApp extends StatefulWidget {
  
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override


  Widget build(BuildContext context) {
    return GetMaterialApp(
      getPages: [
        GetPage(name: '/', page: () => HomePage()),
        // add this line 👇👇👇
        GetPage(name: '/result', page: () => TongueAnalysisResultPage()),
      ],
      navigatorObservers: [AppNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      initialBinding: GeneralBindings(),
      home: const SplashScreen(),
    );
  }
}
