import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../navigation_menu.dart';
import 'chat_list.dart';
import 'dietician_chat_list.dart';

class ChatPage extends StatelessWidget {
  final String currentUserId;
  final String dieticianId;
  final String userRole; // Pass 'user' or 'dietician'

  const ChatPage({
    Key? key,
    required this.currentUserId,
    required this.userRole,
    required this.dieticianId
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(NavigationMenu());
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
          centerTitle: true,
        ),
        body: userRole == 'user'
            ? ChatListPage(currentUserId: currentUserId, dieticianId: dieticianId,) // Show dieticians
            : DieticianChatListPage(dieticianId: currentUserId, currentUserId: currentUserId,), // Show chats initiated by users
      ),
    );
  }
}
