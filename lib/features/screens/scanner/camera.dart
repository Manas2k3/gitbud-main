import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'captured_image_page.dart';

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with TickerProviderStateMixin {
  final ImagePickerService _imagePickerService = ImagePickerService();
  File? _previewImage;
  bool _isLoading = false;

  late AnimationController _iconPulseController;

  @override
  void initState() {
    super.initState();
    _iconPulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    super.dispose();
  }

  Future<void> _handleImagePick(Future<File?> Function() pickerFn) async {
    setState(() => _isLoading = true);

    final pickedImage = await pickerFn();
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _previewImage = pickedImage;
      _isLoading = false;
    });

    if (pickedImage != null) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(pickedImage, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text("Preview", style: GoogleFonts.poppins(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CapturedImagePage(image: pickedImage),
                    ),
                  );
                },
                child: const Text("Continue"),
              )
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Scanner",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildScannerCard(
                    title: "Capture Image of the Kit",
                    icon: Iconsax.camera,
                    iconBackgroundColor: Colors.orange.shade100,
                    buttonText: "Capture",
                    onTap: () => _handleImagePick(_imagePickerService.captureImageFromCamera),
                  ),
                  const SizedBox(height: 20),
                  _buildScannerCard(
                    title: "Pick Image from Gallery",
                    icon: Iconsax.gallery,
                    iconBackgroundColor: Colors.teal.shade100,
                    buttonText: "Pick",
                    onTap: () => _handleImagePick(_imagePickerService.pickImageFromGallery),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Text(
                "This feature is under development and will be available soon.",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCard({
    required String title,
    required IconData icon,
    required Color iconBackgroundColor,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    icon: const Icon(Iconsax.image),
                    label: Text(
                      buttonText,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(
                  parent: _iconPulseController,
                  curve: Curves.easeInOut,
                )),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<File?> captureImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}