import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/survey/survey_screen.dart';

import '../../../utils/constants/animation_strings.dart';
import '../../../utils/popups/full_screen.dart';
import '../../../utils/popups/loaders.dart';

class AdditionalDetailsController extends GetxController {
  static AdditionalDetailsController get instance => Get.find();

  // Text controllers
  final age = TextEditingController();
  final height = TextEditingController();
  final weight = TextEditingController();
  final gender = ''.obs;

  // Form key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  /// Method to save details to Firestore
  Future<void> updateAdditionalDetails(BuildContext context) async {
    try {
      FullScreenLoader.openLoadingDialog(
        "Saving your details...",
        AnimationStrings.loadingAnimation,
      );

      // Validate form
      if (!formKey.currentState!.validate()) {
        FullScreenLoader.stopLoading();
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        FullScreenLoader.stopLoading();
        Loaders.errorSnackBar(
          title: "Error",
          message: "User not logged in.",
        );
        return;
      }

      // Update Firestore document
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
        'age': int.parse(age.text.trim()),
        'height': double.parse(height.text.trim()),
        'weight': double.parse(weight.text.trim()),
        'gender': gender.value.trim(),
        'updatedAt': DateTime.now(),
      });

      FullScreenLoader.stopLoading();
      Loaders.successSnackBar(
        title: "Success",
        message: "Details updated successfully!",
      );

      // Navigate or perform action after update
      Get.to(SurveyScreen()); // or Get.to(NextPage());
    } catch (e) {
      FullScreenLoader.stopLoading();
      print('Error updating additional details: $e');
      Loaders.errorSnackBar(
        title: "Error",
        message: "Something went wrong while saving details.",
      );
    }
  }

  /// Clean up
  @override
  void onClose() {
    age.dispose();
    height.dispose();
    weight.dispose();
    super.onClose();
  }
}
