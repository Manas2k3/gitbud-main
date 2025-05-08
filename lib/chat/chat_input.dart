import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatInput extends StatelessWidget {
  final String chatId;

  ChatInput({required this.chatId});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    void sendMessage() {
      if (controller.text.trim().isEmpty) return;

      FirebaseFirestore.instance
          .collection('Chats')
          .doc(chatId)
          .collection('Messages')
          .add({
        'message': controller.text.trim(),
        'senderId': 'currentUserId', // Replace with actual user ID
        'timestamp': FieldValue.serverTimestamp(),
      });

      controller.clear();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }
}
