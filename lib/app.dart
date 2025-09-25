// lib/app.dart

import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:upgrader/upgrader.dart';

import 'package:gibud/bindings/general_bindings.dart';
import 'package:gibud/splash_screen.dart';

import 'chat/individual_chat_page.dart';
import 'features/screens/home/home_page.dart';
import 'features/screens/tongue_analysis/widgets/TongueAnalysisResultPage.dart';

class MyApp extends StatefulWidget {
  // Accept remote-provided minimum version (nullable)
  final String? remoteMinVersion;
  const MyApp({super.key, this.remoteMinVersion});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String get _minVersion => (widget.remoteMinVersion != null && widget.remoteMinVersion!.isNotEmpty)
      ? widget.remoteMinVersion!
      : '2.0.1'; // fallback if remote not available

  @override
  Widget build(BuildContext context) {
    // Uncomment this for dev testing to reset upgrader cache
    // Upgrader().clearSavedSettings();

    return UpgradeAlert(
      upgrader: Upgrader(
        debugLogging: true,
        debugDisplayOnce: true,
        durationUntilAlertAgain: const Duration(days: 1),
        // Use runtime-provided min version (ignores +build metadata)
        minAppVersion: _minVersion,
        willDisplayUpgrade: ({
          required bool display,
          String? installedVersion,
          UpgraderVersionInfo? versionInfo,
        }) {
          debugPrint(
            'Will display upgrade? $display (installed=$installedVersion, store=${versionInfo?.appStoreVersion})',
          );
        },
      ),
      child: GetMaterialApp(
        getPages: [
          GetPage(name: '/', page: () => HomePage()),
          GetPage(name: '/result', page: () => TongueAnalysisResultPage()),
        ],
        navigatorObservers: [AppNavigatorObserver()],
        debugShowCheckedModeBanner: false,
        initialBinding: GeneralBindings(),
        home: const SplashScreen(),
      ),
    );
  }
}
