import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'call_constants.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallingPage extends StatelessWidget {
  final String callID;
  final String otherUserId;
  final String? otherUserName;

  const CallingPage({
    Key? key,
    required this.callID,
    required this.otherUserId,
    this.otherUserName,
  }) : super(key: key);

  // Generate a random fallback user ID
  String _generateRandomUserID() {
    return 'user_${Random().nextInt(100000)}';
  }

  @override
  Widget build(BuildContext context) {
    final fallbackUserID = _generateRandomUserID();

    if (otherUserId.isEmpty) {
      return _buildZegoCallUI(
        userID: fallbackUserID,
        userName: "Guest User",
      );
    }

    // If userName is already passed, use it directly
    if (otherUserName != null && otherUserName!.isNotEmpty) {
      return _buildZegoCallUI(
        userID: otherUserId,
        userName: otherUserName!,
      );
    }

    // Otherwise, fetch the name from Firestore
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(otherUserId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return _buildZegoCallUI(
              userID: otherUserId,
              userName: "Unknown User",
            );
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userName = userData['name'] ?? 'Unnamed User';

          return _buildZegoCallUI(
            userID: otherUserId,
            userName: userName,
          );
        },
      ),
    );
  }

  Widget _buildZegoCallUI({
    required String userID,
    required String userName,
  }) {
    return ZegoUIKitPrebuiltCall(
      appID: CallAppInfo.appId,
      appSign: CallAppInfo.appSign,
      userID: userID,
      userName: userName,
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
    );
  }
}
