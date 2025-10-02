// lib/features/tongue_analysis/tongueAnalysisPage.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/utils/constants/image_strings.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../controllers/tongue_analysis_controller.dart';

class TongueAnalysisPage extends StatefulWidget {
  const TongueAnalysisPage({super.key});

  @override
  State<TongueAnalysisPage> createState() => _TongueAnalysisPageState();
}

class _TongueAnalysisPageState extends State<TongueAnalysisPage> {
  final controller = Get.isRegistered<TongueAnalysisController>()
      ? Get.find<TongueAnalysisController>()
      : Get.put(TongueAnalysisController());
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Register the pick-sheet callback so controller can auto-open it on Retry
    controller.registerPickImageCallback(_showPickSheet);
  }

  Future<File?> _cropImage(XFile picked) async {
    try {
      final CroppedFile? cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust crop',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF7B61FF),
            lockAspectRatio: false,
            hideBottomControls: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
            initAspectRatio: CropAspectRatioPreset.square,
            cropStyle: CropStyle.rectangle,
          ),
          IOSUiSettings(
            title: 'Adjust crop',
            aspectRatioPickerButtonHidden: false,
            resetAspectRatioEnabled: true,
            aspectRatioLockEnabled: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.original,
            ],
            cropStyle: CropStyle.rectangle,
          ),
        ],
      );

      if (cropped == null) {
        return null;
      }
      return File(cropped.path);
    } catch (e, st) {
      // louder logging
      // ignore: avoid_print
      print('[Cropper v9.1.0] ERROR: $e\n$st');
      return null;
    }
  }

  Future<void> _pickFrom(ImageSource source, {CameraDevice cameraDevice = CameraDevice.rear}) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      preferredCameraDevice: cameraDevice,
    );
    if (image == null) return;

    final File? cropped = await _cropImage(image);
    if (cropped != null) {
      setState(() => _selectedImage = cropped);
    }
  }


  Future<void> _recropCurrent() async {
    if (_selectedImage == null) return;
    final XFile x = XFile(_selectedImage!.path);
    final File? cropped = await _cropImage(x);
    if (cropped != null) setState(() => _selectedImage = cropped);
  }

  Future<void> _showPickSheet() async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text("Capture with Camera"),
              subtitle: const Text("Open camera and take a new photo"),
              onTap: () {
                Navigator.pop(context);
                _pickFrom(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text("Choose from Gallery"),
              subtitle: const Text("Pick an existing photo"),
              onTap: () {
                Navigator.pop(context);
                _pickFrom(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.crop_rounded),
                title: const Text("Re-crop current image"),
                onTap: () {
                  Navigator.pop(context);
                  _recropCurrent();
                },
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double imageHeight = MediaQuery.of(context).size.height * 0.40;
    final double imageWidth = MediaQuery.of(context).size.width * 0.9;

    return PopScope(
      canPop: !controller.isLoading.value,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && controller.isLoading.value) {
          Get.snackbar(
            "Please wait",
            "Analysis is still in progress…",
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.black,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Get.offAll(NavigationMenu()),
            icon: const Icon(Icons.arrow_back),
          ),
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

              // Unified Upload Block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
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
                      "Tap below to capture from camera or choose from gallery",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _showPickSheet,
                        icon: const Icon(Icons.upload_rounded),
                        label: const Text("Upload Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _recropCurrent,
                            icon: const Icon(Icons.crop_rounded),
                            label: const Text("Re-crop"),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _selectedImage = null),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Remove"),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Preview
              Text(
                _selectedImage != null ? "Selected Image" : "Sample Image",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 12),
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

              const SizedBox(height: 14),

              // Guidance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Best Results: How to take the photo",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          _TipBullet(
                              "Use bright, even lighting (daylight or a well-lit room). Avoid colored lights or strong shadows."),
                          _TipBullet(
                              "Keep the whole tongue visible (tip to root) and in focus."),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              // Scan CTA
              Obx(() {
                final busy = controller.isLoading.value;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: busy
                        ? null
                        : () {
                      if (_selectedImage == null) {
                        Get.snackbar(
                          "Image Required",
                          "Please upload an image first.",
                          backgroundColor: Colors.orange.shade100,
                          colorText: Colors.black,
                        );
                        return;
                      }
                      controller.analyzeImage(_selectedImage); // File?
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: const Color(0xFF7B61FF),
                    ),
                    child: busy
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.black)),
                    )
                        : const Text(
                      "Scan Now",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny bullet widget for tips (keeps build clean)
class _TipBullet extends StatelessWidget {
  final String text;

  const _TipBullet(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• "),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }
}
