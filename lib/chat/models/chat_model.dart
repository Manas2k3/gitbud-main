import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String name;
  final String email;
  final String id;
  final List<String> participants;
  final String lastMessage;
  final Timestamp lastMessageTimestamp;

  ChatModel({
    required this.id,
    required this.email,
    required this.name,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: map['lastMessageTimestamp'] ?? Timestamp.now(), name: map['name'], email: map['email'],
    );
  }
}
