import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String name;
  final String email;
  final String id;
  final String photoUrl; // ✅ NEW
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatModel({
    required this.id,
    required this.email,
    required this.name,
    required this.photoUrl, // ✅ NEW
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Unknown',
      photoUrl: map['photoUrl'] ?? 'https://i.pinimg.com/474x/e6/e4/df/e6e4df26ba752161b9fc6a17321fa286.jpg', // ✅ fallback
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: map['lastMessageTimestamp'] ?? Timestamp.now(),
    );
  }
}
