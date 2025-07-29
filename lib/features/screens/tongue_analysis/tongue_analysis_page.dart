import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/tongue_analysis/widgets/TongueAnalysisResultPage.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/utils/constants/image_strings.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/tongue_analysis_controller.dart';

class TongueAnalysisPage extends StatefulWidget {
  const TongueAnalysisPage({super.key});

  @override
  State<TongueAnalysisPage> createState() => _TongueAnalysisPageState();
}

class _TongueAnalysisPageState extends State<TongueAnalysisPage> {
  final controller = Get.put(TongueAnalysisController());
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _openCamera() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _openGallery() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.22;
    final double imageWidth = MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(onPressed: () => Get.offAll(NavigationMenu()), icon: Icon(Icons.arrow_back)),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Tongue Health Scanner",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Capture a clear image of your tongue to assess potential health indicators",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(60),
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    "Upload Image",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Open Camera or Upload from Gallery",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _openCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Open Camera"),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: _openGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Upload from Gallery"),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedImage != null ? "Selected Image" : "Sample Image",
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _selectedImage != null
                  ? Image.file(
                _selectedImage!,
                height: imageHeight,
                width: imageWidth,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                ImageStrings.sampleTongueImage,
                height: imageHeight,
                width: imageWidth,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Ensure good lighting, neutral background",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedImage == null) {
                    Get.snackbar(
                      "Image Required",
                      "Please upload an image first.",
                      backgroundColor: Colors.orange.shade100,
                      colorText: Colors.black,
                    );
                    return;
                  }

                  controller.analyzeImage(_selectedImage);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFF7B61FF),
                ),
                child: const Text(
                  "Scan Now",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height*0.03)

          ],
        ),
      ),
    );
  }
}
