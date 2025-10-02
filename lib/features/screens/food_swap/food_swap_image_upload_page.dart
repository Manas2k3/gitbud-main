import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../../controllers/food_swap_controller.dart';

class FoodSwapImageUploadPage extends StatefulWidget {
  const FoodSwapImageUploadPage({super.key});

  @override
  State<FoodSwapImageUploadPage> createState() =>
      _FoodSwapImageUploadPageState();
}

class _FoodSwapImageUploadPageState extends State<FoodSwapImageUploadPage> {
  final controller = Get.put(FoodSwapController());
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() => _selectedImage = file);
      controller.setImage(file); // 👈 Store in controller
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor removed — gradient does the job
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Food Swap",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Color(0xFFE8EAF6), // was: Colors.white
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,

        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 💜 Gradient background (indigo → white)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE8EAF6), // light indigo tint
                    Colors.white,      // fade to white
                  ],
                ),
              ),
            ),
          ),

          // 🔹 original content
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  "Take a photo or upload an image of your food item",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                        : const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                        color: Colors.black26,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          final file = File(pickedFile.path);
                          setState(() => _selectedImage = file);
                          controller.setImage(file);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Take a photo",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final pickedFile = await _picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (pickedFile != null) {
                          final file = File(pickedFile.path);
                          setState(() => _selectedImage = file);
                          controller.setImage(file);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3F3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Upload an image",
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        if (_selectedImage != null) {
                          await controller.analyzeFoodImage(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Please select an image first.")),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Analyze Meal",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.04,
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
