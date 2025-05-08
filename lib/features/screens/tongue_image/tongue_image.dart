import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/survey/survey_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/widgets/appbar/appbar.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get current user ID

class TongueImage extends StatefulWidget {
  const TongueImage({super.key});

  @override
  State<TongueImage> createState() => _TongueImageState();
}

class _TongueImageState extends State<TongueImage> {
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _capturedImage = File(image.path);
      });
    }
  }

  Future<void> _submitImage() async {
    if (_capturedImage == null) return;

    try {
      setState(() => _isSubmitting = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // Get the user's name from Firestore (to use in the file name)
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      final userName = userDoc['name'] as String;
      final safeFileName = userName.replaceAll(' ', '_');
      final fileName = '$safeFileName.jpg';

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('tongue_images/$fileName');

      await storageRef.putFile(_capturedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore User Document
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'tongueImage': downloadUrl,
      });

      setState(() {
        _capturedImage = null;
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image submitted successfully')),
      );

      // ✅ Navigate to SurveyScreen after successful upload
      Get.to(() => SurveyScreen());
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.green,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      "Capture Tongue Image",
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade200,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Please ensure good lighting and keep your tongue fully visible and extended. This helps us give you a detailed analysis in a future update.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _capturedImage == null
                      ? Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("No image captured")),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _capturedImage!,
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: _isSubmitting
                        ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    )
                        : Icon(
                      _capturedImage == null
                          ? Icons.camera_alt
                          : Icons.upload,
                      color: Colors.black,
                    ),
                    label: Text(
                      _capturedImage == null ? "Capture Tongue Image" : "Submit",
                      style: const TextStyle(color: Colors.black),
                    ),
                    onPressed: _isSubmitting
                        ? null
                        : _capturedImage == null
                        ? _captureImage
                        : _submitImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (_capturedImage != null)
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _capturedImage = null),
                      child: const Text("Retake Image",
                          style: TextStyle(color: Colors.black)),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
