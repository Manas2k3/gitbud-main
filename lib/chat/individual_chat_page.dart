  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:get/get.dart';
  import 'package:get/get_core/src/get_main.dart';
import 'package:gibud/call/constants/calling_page.dart';
  import 'package:onesignal_flutter/onesignal_flutter.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:intl/intl.dart';
  import 'package:logger/logger.dart';
  import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../secrets.dart';

  final logger = Logger();

  class AppNavigatorObserver extends NavigatorObserver {
    static String? currentRoute;

    @override
    void didPush(Route route, Route? previousRoute) {
      super.didPush(route, previousRoute);
      currentRoute = route.settings.name;
      logger.i('💡 Pushed route: $currentRoute');
    }

    @override
    void didPop(Route route, Route? previousRoute) {
      super.didPop(route, previousRoute);
      currentRoute = previousRoute?.settings.name;
      logger.i('💡 Popped to route: $currentRoute');
    }

    @override
    void didReplace({Route? newRoute, Route? oldRoute}) {
      super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
      currentRoute = newRoute?.settings.name;
      logger.i('💡 Replaced route: $currentRoute');
    }
  }


  class IndividualChatPage extends StatelessWidget {

    final _callIdController = TextEditingController();
    final String chatId;
    final Logger logger = Logger();

    IndividualChatPage({
      Key? key,
      required this.chatId,
    }) : super(key: key);

    Future<Map<String, String>> getCurrentUserInfo() async {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('No user is logged in');
      }

      final senderId = currentUser.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(senderId)
          .get();

      final senderName = userDoc.exists &&
              userDoc.data() != null &&
              userDoc.data()!['name'] is String
          ? userDoc.data()!['name'] as String
          : 'Anonymous';

      return {
        'senderId': senderId,
        'senderName': senderName,
      };
    }

    Future<void> sendOneSignalNotification(
        String playerId, String message, String senderName) async {
      String? oneSignalAppId = ONESIGNAL_INITIALISE_ID;
      String? oneSignalApiKey =
          ONESIGNAL_API_KEY;

      final url = 'https://onesignal.com/api/v1/notifications';

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Basic $oneSignalApiKey',
      };

      final notificationPayload = {
        'app_id': oneSignalAppId,
        'include_player_ids': [playerId],
        'headings': {'en': senderName},
        'contents': {'en': message},
        'data': {
          'message': message,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(notificationPayload),
        );

        if (response.statusCode == 200) {
          logger.i('Notification sent successfully: ${response.body}');
        } else {
          logger.e(
              'Failed to send notification: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        logger.e('Error sending OneSignal notification: $e');
      }
    }

    Future<void> _showTextInputDialog(BuildContext context, String otherUserId) async {
      _callIdController.clear(); // Clear the text field when the dialog is opened
      return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: TextFormField(
              controller: _callIdController,
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: "Enter Call ID to start/join call",
                hintStyle: GoogleFonts.poppins(fontSize: 12)
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Call ID is required';
                } else if (value.length != 4) {
                  return 'Call ID must be exactly 4 digits';
                } else if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                  return 'Only digits allowed';
                }
                return null;
              },
            ),

            actions: <Widget>[
              TextButton(
                child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.black),),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK', style: GoogleFonts.poppins(color: Colors.black),),
                onPressed: () {
                  String callId = _callIdController.text;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CallingPage(
                      callID: callId,
                      otherUserId: otherUserId,
                    ),
                  ));
                },
              ),
            ],
          );
        },
      );
    }

    @override
    Widget build(BuildContext context) {
      final messagesRef = FirebaseFirestore.instance
          .collection('Chats')
          .doc(chatId)
          .collection('Messages');

      final messageController = TextEditingController();
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Chats').doc(chatId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.grey.shade100,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: Colors.white,)),
                backgroundColor: Colors.green,
                title: Text('Loading...',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              backgroundColor: Colors.grey.shade100,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: Colors.white,)),
                backgroundColor: Colors.green,
                title: Text('Error',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
              body: const Center(child: Text('Error loading chat.')),
            );
          }

          final chatData = snapshot.data!.data() as Map<String, dynamic>;
          final participants = List<String>.from(chatData['participants']);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

          final otherUserId =
              participants.firstWhere((id) => id != currentUserId);

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Users')
                .doc(otherUserId)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: Colors.grey.shade100,
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: Colors.white,)),
                    backgroundColor: Colors.green,
                    title: Text('Loading user...',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                  body: const Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError ||
                  !userSnapshot.hasData ||
                  !userSnapshot.data!.exists) {
                return Scaffold(
                  backgroundColor: Colors.grey.shade100,
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: Colors.white,)),
                    backgroundColor: Colors.green,
                    title: Text('Error',
                        style: GoogleFonts.poppins(color: Colors.white)),
                  ),
                  body: const Center(child: Text('Error loading user info.')),
                );
              }

              final userData = userSnapshot.data!.data() as Map<String, dynamic>;
              final otherUserName = userData['name'] ?? 'Unknown User';
              final otherUserPlayerId = userData['onesignalPlayerId'];

              return Scaffold(
                backgroundColor: Colors.grey.shade100,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back, color: Colors.white,)),
                  backgroundColor: Colors.green,
                  title: Text(
                    otherUserName,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  actions: [
                    // IconButton(
                    //   onPressed: () {
                    //   },
                    //   icon: Icon(Icons.call, color: Colors.white),
                    // ),
                    IconButton(
                      onPressed: () {
                        _showTextInputDialog(context, otherUserId);
                      },
                      icon: Icon(Icons.video_call, color: Colors.white),
                    ),
                  ],

                ),
                body: Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: messagesRef
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(
                                child: Text('Error loading messages.'));
                          }
                          final messages = snapshot.data?.docs ?? [];
                          return ListView.builder(
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final timestamp =
                                  message['timestamp'] as Timestamp?;
                              final dateTime = timestamp?.toDate();
                              final formattedTime = dateTime != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a')
                                      .format(dateTime)
                                  : 'No timestamp';
                              final isCurrentUser =
                                  message['senderId'] == currentUserId;

                              return Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4.0, horizontal: 8.0),
                                  padding: const EdgeInsets.all(12.0),
                                  decoration: BoxDecoration(
                                    color: isCurrentUser
                                        ? Colors.green.shade100
                                        : Colors.blue.shade100,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(12.0),
                                      topRight: const Radius.circular(12.0),
                                      bottomLeft: isCurrentUser
                                          ? const Radius.circular(12.0)
                                          : const Radius.circular(0),
                                      bottomRight: isCurrentUser
                                          ? const Radius.circular(0)
                                          : const Radius.circular(12.0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(message['text'],
                                          style:
                                              GoogleFonts.poppins(fontSize: 15)),
                                      const SizedBox(height: 4.0),
                                      Text(formattedTime,
                                          style:
                                              GoogleFonts.poppins(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: Colors.grey, width: 1.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: const BorderSide(
                                      color: Colors.grey, width: 2.0),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              final message = messageController.text.trim();
                              if (message.isEmpty) return;

                              try {
                                final currentUserInfo = await getCurrentUserInfo();
                                final senderId = currentUserInfo['senderId']!;
                                final senderName = currentUserInfo['senderName']!;

                                // Add the message to the Messages collection
                                await messagesRef.add({
                                  'senderId': senderId,
                                  'text': message,
                                  'timestamp': FieldValue.serverTimestamp(),
                                });

                                // Update the lastMessage and lastMessageTimestamp in the Chats document
                                await FirebaseFirestore.instance.collection('Chats').doc(chatId).update({
                                  'lastMessage': message,
                                  'lastMessageTimestamp': FieldValue.serverTimestamp(),
                                });

                                if (otherUserPlayerId != null) {
                                  await sendOneSignalNotification(
                                    otherUserPlayerId,
                                    message,
                                    senderName,
                                  );
                                } else {
                                  logger.w('Other user has no OneSignal Player ID.');
                                }
                              } catch (e) {
                                logger.e('Error sending message: $e');
                              } finally {
                                messageController.clear();
                              }
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }
