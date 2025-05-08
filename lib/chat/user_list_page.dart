import 'package:flutter/material.dart';

import '../services/firestore_service.dart';
import 'individual_chat_page.dart';
import 'models/chat_model.dart';

class UserListPage extends StatelessWidget {
  final String currentUserId;
  final String targetRole; // 'dietician' or 'user'

  const UserListPage({
    Key? key,
    required this.currentUserId,
    required this.targetRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select $targetRole')),
      body: FutureBuilder<List<ChatModel>>(
        future: FirestoreService().getUsersByRole(targetRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading users.'));
          }
          final users = snapshot.data ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name[0].toUpperCase()),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () => initiateChat(currentUserId, user.id, context),
              );
            },
          );
        },
      ),
    );
  }

  void initiateChat(String currentUserId, String selectedUserId, BuildContext context) async {
    final chatId = await FirestoreService().getOrCreateChat(currentUserId, selectedUserId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndividualChatPage(chatId: chatId),
      ),
    );
  }
}
