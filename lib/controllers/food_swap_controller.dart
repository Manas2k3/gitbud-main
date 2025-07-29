import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../utils/constants/animation_strings.dart';
import '../../utils/popups/full_screen.dart';
import '../features/screens/food_swap/food_swap_result_screen.dart';

class FoodSwapController extends GetxController {

  void _showLoader() {
    FullScreenLoader.openLoadingDialog(
      "Analyzing your meal...",
      AnimationStrings.loadingAnimation,
    );
  }
  static FoodSwapController get instance => Get.find();

  final Rxn<File> selectedImage = Rxn<File>();

  void setImage(File image) {
    selectedImage.value = image;
  }

  Future<void> analyzeFoodImage(BuildContext context) async {
    try {
      _showLoader();

      if (!await _isInternetConnected()) {
        _hideLoader();
        _showNoInternetDialog(context);
        return;
      }

      final image = selectedImage.value;
      if (image == null) {
        _hideLoader();
        _showSnackBar(context, "No image selected.");
        return;
      }

      final uri = Uri.parse("https://food-swap.onrender.com/predict");

      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', 'jpeg'),
        ));

      final response = await request.send();

      _hideLoader();

      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(resBody);

        Get.to(() => FoodSwapResultsPage(
          predictedFood: jsonData['predicted_food'],
          nutritionInfo: Map<String, dynamic>.from(jsonData['nutritional_info']),
          alternatives: List<dynamic>.from(jsonData['alternatives']),
          scannedImage: image,
        ));
      } else {
        _showSnackBar(context, "Upload failed");
      }
    } catch (e) {
      _hideLoader();
      _showSnackBar(context, "Error occurred: $e");
    }
  }



  void _hideLoader() {
    FullScreenLoader.stopLoading();
  }

  Future<bool> _isInternetConnected() async {
    return await InternetConnectionChecker().hasConnection;
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("No Internet"),
          content: const Text("Please check your internet connection."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
