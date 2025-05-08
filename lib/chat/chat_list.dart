import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import 'individual_chat_page.dart';
import 'models/chat_model.dart';

class ChatListPage extends StatelessWidget {
  final String currentUserId;

  const ChatListPage({
    Key? key,
    required this.currentUserId,
    required String dieticianId,
  }) : super(key: key);

  Future<String> fetchLastMessage(
      String currentUserId, String dieticianId) async {
    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('Chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in chatQuery.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(dieticianId)) {
          return doc.data()['lastMessage'] ?? 'No messages yet';
        }
      }
      return 'No messages yet';
    } catch (e) {
      print('Error fetching last message: $e');
      return 'Error loading message';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: Colors.white,)),
        backgroundColor: Colors.green,
        title: Text(
          'Chat with Dieticians',
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<ChatModel>>(
        future: FirestoreService().getDieticians(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading dieticians.'));
          }

          final dieticians = snapshot.data ?? [];
          return ListView.builder(
            itemCount: dieticians.length,
            itemBuilder: (context, index) {
              final dietician = dieticians[index];
              return FutureBuilder<String>(
                future: fetchLastMessage(currentUserId, dietician.id),
                builder: (context, messageSnapshot) {
                  if (messageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text(
                        'Loading...',
                        style: GoogleFonts.poppins(),
                      ),
                      subtitle: Text('Fetching last message...',
                          style: GoogleFonts.poppins()),
                    );
                  }

                  final lastMessage = messageSnapshot.data ?? 'No messages yet';

                  return ListTile(
                    title: Text(
                      dietician.name,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: GoogleFonts.poppins(),
                    ),
                    onTap: () async {
                      // Create or fetch a chat with the selected dietician
                      final chatId = await FirestoreService().getOrCreateChat(
                        currentUserId,
                        dietician.id,
                      );
                      // Navigate to the chat page
                      Get.to(() => IndividualChatPage(chatId: chatId));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
