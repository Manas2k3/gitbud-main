import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print("Error initializing Firebase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Screen")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Manually trigger the function when the button is tapped
                await deleteReadStatusFieldFromAllUsers();
              },
              child: Text('Delete Read Status'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteReadStatusFieldFromAllUsers() async {
    final firestore = FirebaseFirestore.instance;
    final users = await firestore.collection('Users').get();
    for (var user in users.docs) {
      await user.reference.update({
        'readStatus': FieldValue.delete(), // Deletes the readStatus field
      });
    }
  }
}
