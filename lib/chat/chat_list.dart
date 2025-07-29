import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  Future<String> fetchLastMessage(String currentUserId, String dieticianId) async {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          'Chat with Dieticians',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
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
                  final lastMessage = messageSnapshot.data ?? 'No messages yet';

                  return InkWell(
                    onTap: () async {
                      final chatId = await FirestoreService().getOrCreateChat(
                        currentUserId,
                        dietician.id,
                      );
                      Get.to(() => IndividualChatPage(chatId: chatId));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                              dietician.photoUrl ??
                                  'https://i.pinimg.com/474x/e6/e4/df/e6e4df26ba752161b9fc6a17321fa286.jpg',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dietician.name}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Text(
                          //   'Online', // <- Replace this with real timestamp if available
                          //   style: GoogleFonts.poppins(
                          //     fontSize: 12,
                          //     color: Colors.grey[500],
                          //   ),
                          // ),
                        ],
                      ),
                    ),
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
