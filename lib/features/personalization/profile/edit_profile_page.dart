import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gibud/utils/popups/loaders.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../common/widgets/appbar/appbar.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Text controllers for the fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String userId = _auth.currentUser?.uid ?? '';
    DocumentSnapshot userDoc = await _firestore.collection('Users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        nameController.text = userData['name'] ?? '';
        ageController.text = userData['age'] ?? '';
        weightController.text = userData['weight'] ?? '';
        heightController.text = userData['height'] ?? '';
      });
    }
  }

  Future<void> _updateUserData() async {
    String userId = _auth.currentUser?.uid ?? '';
    await _firestore.collection('Users').doc(userId).update({
      'name': nameController.text,
      'age': ageController.text,
      'weight': weightController.text,
      'height': heightController.text,
    });

    // Ensure the snackbar is displayed after the frame has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Loaders.successSnackBar(title: "Data has been updated successfully", message: "");
    });

    Get.back(); // Close the page after saving
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Header Section
            PrimaryHeaderContainer(
              color: Colors.redAccent,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      "Edit Profile",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.save, color: Colors.white),
                        onPressed: _updateUserData,
                      ),
                    ],
                  ),
                  SizedBox(height: 25),
                ],
              ),
            ),

            /// Body Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    decoration: InputDecoration(labelText: 'Age'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    decoration: InputDecoration(labelText: 'Weight'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: heightController,
                    decoration: InputDecoration(labelText: 'Height'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
