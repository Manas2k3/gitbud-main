import 'package:cloud_firestore/cloud_firestore.dart';
import '../chat/models/chat_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create a chat between a user and a dietician
  Future<String> getOrCreateChat(String userId, String dieticianId) async {
    final chatsRef = _firestore.collection('Chats');

    print("Checking existing chats between $userId and $dieticianId...");

    final existingChats = await chatsRef
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in existingChats.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(dieticianId)) {
        print("Existing chat found: ${doc.id}");
        return doc.id; // Return existing chat ID
      }
    }

    // Create a new chat if no existing chat is found
    print("No existing chat found. Creating a new chat...");

    final newChat = await chatsRef.add({
      'participants': [userId, dieticianId],
      'lastMessage': '',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
    });

    print("New chat created with ID: ${newChat.id}");
    return newChat.id;
  }

  /// Fetch chats for a user (Sorted by last message timestamp)
  Stream<List<DocumentSnapshot>> fetchChatsForUser(String userId) {
    print("Fetching chats for user: $userId");

    return _firestore
        .collection('Chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((query) {
      print("Chats fetched for user: ${query.docs.length}");
      return query.docs;
    });
  }

  /// Fetch chats for a dietician (Only show chats where messages exist)
  /// Fetch chats for a dietician (Show all chats, even empty ones)
  Stream<List<DocumentSnapshot>> fetchChatsForDietician(String dieticianId) {
    print("Fetching chats for dietician: $dieticianId");

    return _firestore
        .collection('Chats')
        .where('participants', arrayContains: dieticianId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((query) {
      print("Chats fetched: ${query.docs.length}");
      return query.docs; // Return ALL chats, including empty ones
    });
  }


  /// Fetch all dieticians from Firestore
  Future<List<ChatModel>> getDieticians() async {
    try {
      print("Fetching dieticians...");

      final querySnapshot = await _firestore
          .collection('Users')
          .where('selectedRole', isEqualTo: 'dietician')
          .get();

      print("Dieticians found: ${querySnapshot.docs.length}");

      return querySnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching dieticians: $e");
      throw Exception('Error fetching dieticians: $e');
    }
  }

  /// Fetch users by role (e.g., dieticians, patients, etc.)
  Future<List<ChatModel>> getUsersByRole(String role) async {
    try {
      print("Fetching users with role: $role");

      final querySnapshot = await _firestore
          .collection('Users')
          .where('selectedRole', isEqualTo: role)
          .get();

      print("Users found with role $role: ${querySnapshot.docs.length}");

      return querySnapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print("Error fetching users: $e");
      throw Exception('Error fetching users: $e');
    }
  }
}
