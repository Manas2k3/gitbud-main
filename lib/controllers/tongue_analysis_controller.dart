import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

import '../utils/constants/animation_strings.dart';
import '../utils/popups/full_screen.dart';

class TongueAnalysisController extends GetxController {
  var isLoading = false.obs;

  Future<void> analyzeImage(File? imageFile) async {
    if (imageFile == null) {
      Get.snackbar(
        "Image Required",
        "Please upload an image first.",
        backgroundColor: Colors.orange.shade100,
        colorText: Colors.black,
      );
      return;
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Get.snackbar("No Internet", "Please check your connection",
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
      return;
    }

    FullScreenLoader.openLoadingDialog(
      "Analysing tongue image...",
      AnimationStrings.loadingAnimation,
      onCancel: () {
        isLoading.value = false;
        Get.snackbar(
          "Cancelled",
          "Scan was cancelled by user.",
          backgroundColor: Colors.grey.shade200,
          colorText: Colors.black,
        );
      },
    );

    try {
      isLoading.value = true;

      final uri = Uri.parse("https://tongue-analysis.onrender.com/predict");
      final request = http.MultipartRequest("POST", uri);

      final mimeType = lookupMimeType(imageFile.path);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // ✅ FIXED! This now matches Postman
          imageFile.path,
          contentType: mimeType != null
              ? MediaType.parse(mimeType)
              : MediaType("image", "jpeg"),
          filename: path.basename(imageFile.path),
        ),
      );


      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      isLoading.value = false;

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final predictedClass = jsonData['predicted_class'];
        final confidence = jsonData['confidence'];

        if (predictedClass != null && confidence != null) {
          Get.toNamed(
            "/result",
            arguments: {
              "predicted_class": predictedClass,
              "confidence": confidence,
              "imageFile": imageFile,
            },
          );
        } else {
          Get.snackbar("Error", "Unexpected response from server",
              backgroundColor: Colors.red.shade100, colorText: Colors.black);
        }
      } else {
        Get.snackbar("Error", "Failed to analyze image",
            backgroundColor: Colors.red.shade100, colorText: Colors.black);
      }
    } catch (e) {
      isLoading.value = false;
      print(e);
      Get.snackbar("Error", "Something went wrong: $e",
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
    }
  }
}
