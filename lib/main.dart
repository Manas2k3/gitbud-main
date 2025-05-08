import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:gibud/app.dart'; // Your App entry point
import 'package:gibud/data/repositories/authentication/authentication_repository.dart';
import 'package:gibud/secrets.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();


  // Debug: Print environment variables

  final oneSignalAppId = ONESIGNAL_INITIALISE_ID;
  if (oneSignalAppId.isEmpty) {
    throw Exception("ONESIGNAL_INITIALISE_ID is not set in the .env file");
  }

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);

  // Initialize GetStorage
  await GetStorage.init();

  // Initialize Authentication Repository
  Get.put(AuthenticationRepository());

  // Store OneSignal Push Subscription ID in Firestore
  await _getPushSubscriptionIdAndStore();

  // Run the app
  runApp(const MyApp());
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
