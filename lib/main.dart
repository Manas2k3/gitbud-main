// main.dart

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gibud/app.dart';
import 'package:gibud/data/repositories/authentication/authentication_repository.dart';
import 'package:gibud/secrets.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // 🌟 Initialize Firebase FIRST
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Activate App Check Provider (Debug or Play Integrity)
  await FirebaseAppCheck.instance.activate(
    androidProvider: kReleaseMode
        ? AndroidProvider.playIntegrity
        : AndroidProvider.debug,
  );

  // 📝 Note: The debug token will be printed automatically in logcat/terminal
  if (!kReleaseMode) {
    debugPrint("🛡️ App Check debug provider is active. Token will be printed to logcat if not yet registered.");
    debugPrint("👉 Run `flutter run` or check Android Studio's Logcat for: 'Debug provider token:'");
  }

  // 🔔 OneSignal Initialization
  final oneSignalAppId = ONESIGNAL_INITIALISE_ID;
  if (oneSignalAppId.isEmpty) {
    throw Exception("ONESIGNAL_INITIALISE_ID is not set in the .env file");
  }
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);

  // 📦 Local Storage Init
  await GetStorage.init();

  // 🔐 Auth Repository Binding
  Get.put(AuthenticationRepository());

  // Load env (you had this in your original main; keep it)
  await dotenv.load(fileName: ".env");

  // ---------------------------
  // 🔎 Fetch min_app_version from Firebase Remote Config
  // ---------------------------
  String remoteMinVersion = '2.0.1'; // default fallback

  try {
    final remoteConfig = FirebaseRemoteConfig.instance;

    // Tune these settings as needed (shorter fetch interval for critical updates)
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(minutes: 5),
    ));

    // Try fetching + activating
    final fetched = await remoteConfig.fetchAndActivate();
    if (fetched) {
      final value = remoteConfig.getString('min_app_version').trim();
      if (value.isNotEmpty) {
        remoteMinVersion = value;
        debugPrint("✅ Remote Config min_app_version loaded: $remoteMinVersion");
      } else {
        debugPrint("⚠️ Remote Config param 'min_app_version' is empty — using fallback $remoteMinVersion");
      }
    } else {
      // fetchAndActivate returned false: maybe cache used, still try to read param
      final value = remoteConfig.getString('min_app_version').trim();
      if (value.isNotEmpty) {
        remoteMinVersion = value;
        debugPrint("ℹ️ Remote Config returned cached min_app_version: $remoteMinVersion");
      } else {
        debugPrint("⚠️ Remote Config fetch did not activate and param empty — using fallback $remoteMinVersion");
      }
    }
  } catch (e) {
    debugPrint("❌ Failed to fetch Remote Config: $e — using fallback min version $remoteMinVersion");
  }

  // 📲 OneSignal Push Token Save (keeps the original flow)
  await _getPushSubscriptionIdAndStore();

  // 🚀 Launch App with remoteMinVersion
  runApp(MyApp(remoteMinVersion: remoteMinVersion));
}


Future<void> _getPushSubscriptionIdAndStore() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      final pushSubscriptionId = await OneSignal.User.pushSubscription.id;
      if (pushSubscriptionId != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .update({'onesignalPlayerId': pushSubscriptionId});
        debugPrint("✅ OneSignal Push Subscription ID saved successfully.");
      } else {
        debugPrint("⚠️ Failed to retrieve OneSignal Push Subscription ID.");
      }
    } catch (error) {
      debugPrint("❌ Error saving OneSignal Push Subscription ID: $error");
    }
  } else {
    debugPrint("⚠️ No user logged in. Cannot fetch OneSignal Push Subscription ID.");
  }
}
