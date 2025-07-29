import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';

class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  // Fetch list of dieticians for a normal user
  Future<List<ChatModel>> getDieticians() async {
    try {
      final querySnapshot = await _firestore
          .collection('Users')
          .where('selectedRole', isEqualTo: 'dietician')
          .get();

      print("Dieticians fetched: ${querySnapshot.docs.length}");
      return querySnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching dieticians: $e");
      throw Exception('Error fetching dieticians: $e');
    }
  }

  // Create a chat between user and dietician
  Future<String> createChat(String userId, String dieticianId) async {
    try {
      final chatsRef = _firestore.collection('Chats');

      // Check if chat already exists
      final existingChat = await chatsRef
          .where('participants', arrayContains: userId)
          .where('participants', arrayContains: dieticianId)
          .get();

      print("Existing chats: ${existingChat.docs.length}");

      if (existingChat.docs.isNotEmpty) {
        print("Returning existing chat ID: ${existingChat.docs.first.id}");
        return existingChat.docs.first.id; // Return existing chat
      }

      // Create new chat if not found
      final newChat = await chatsRef.add({
        'participants': [userId, dieticianId],
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });

      print("New chat created with ID: ${newChat.id}");
      return newChat.id;
    } catch (e) {
      print("Error creating chat: $e");
      throw Exception('Error creating chat: $e');
    }
  }

  // Fetch chats for a dietician (where user has initiated the chat)
  Stream<List<DocumentSnapshot>> fetchChatsForDietician(String dieticianId) {
    try {
      print("Fetching chats for dietician with ID: $dieticianId");

      return _firestore
          .collection('Chats')
          .where('participants', arrayContains: dieticianId)
          .snapshots()
          .map((query) {
        print("Fetched chats count: ${query.docs.length}");
        for (var doc in query.docs) {
          print("Chat document: ${doc.data()}");
        }
        return query.docs;
      });
    } catch (e) {
      print("Error fetching chats for dietician: $e");
      rethrow;
    }
  }
}
