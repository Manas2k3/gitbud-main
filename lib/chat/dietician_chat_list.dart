import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'individual_chat_page.dart';
import '../services/firestore_service.dart';

class DieticianChatListPage extends StatelessWidget {
  final String dieticianId;

  const DieticianChatListPage({
    Key? key,
    required this.dieticianId, required String currentUserId,
  }) : super(key: key);

  // Fetch user name from Firestore
  Future<String> fetchUserName(String userId) async {
    try {
      print("Fetching user name for: $userId"); // Debugging

      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      if (!userDoc.exists || userDoc.data() == null) {
        print("User $userId not found in Firestore.");
        return 'Unknown User';
      }

      final name = userDoc.data()!['name'] ?? 'Unknown User';
      print("Fetched name: $name");
      return name;
    } catch (e) {
      print("Error fetching user name: $e");
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        title: Text(
          'Chats with Users',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: FirestoreService().fetchChatsForDietician(dieticianId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching chats: ${snapshot.error}");
            return const Center(child: Text('Error loading chats.'));
          }

          final chats = snapshot.data ?? [];
          print("Chats Fetched: ${chats.length}");

          if (chats.isEmpty) {
            return const Center(child: Text('No chats found.'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];

              final participants = List<String>.from(chat['participants']);
              print("Chat ID: ${chat.id}, Participants: $participants");

              // Get the other user's ID
              final otherUserId = participants.firstWhere(
                    (id) => id != dieticianId,
                orElse: () => 'NoOtherUser', // Fallback if only one participant exists
              );

              print("Other User ID: $otherUserId");

              return FutureBuilder<String>(
                future: fetchUserName(otherUserId),
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(title: Text('Loading...'));
                  }

                  final userName = nameSnapshot.data ?? 'Unknown User';

                  return ListTile(
                    title: Text(userName, style: GoogleFonts.poppins()),
                    subtitle: Text(chat['lastMessage'] ?? '', style: GoogleFonts.poppins()),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IndividualChatPage(
                            chatId: chat.id,
                          ),
                        ),
                      );
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
