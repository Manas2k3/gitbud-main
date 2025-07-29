  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:cloud_firestore/cloud_firestore.dart';
  import 'package:internet_connection_checker/internet_connection_checker.dart';
  import 'package:firebase_auth/firebase_auth.dart';

  import '../survey/model/response_model.dart';
  import '../survey/model/survey_model.dart';
  import '../utils/popups/full_screen.dart';
  import '../utils/constants/animation_strings.dart';
  import '../utils/popups/loaders.dart';

  class SurveyController extends GetxController {
    var questionResponses = <SurveyResponse>[].obs;
    var totalScore = 0.obs;

    // Method to select an answer and calculate the score
    void selectAnswer(int questionIndex, int marks, SurveyQuestion question) {
      SurveyResponse response = SurveyResponse(
        marks: marks,
        resultCategory: question.stringResourceId,
        stringResourceId: question.resultCategory.hashCode,
      );

      if (questionResponses.length > questionIndex) {
        questionResponses[questionIndex] = response;
      } else {
        questionResponses.add(response);
      }

      totalScore.value = questionResponses.fold(0, (sum, item) => sum + item.marks);
    }


    // Method to submit the survey
    Future<void> submitSurvey(BuildContext context) async {
      try {
        // Check Internet Connectivity
        final isConnected = await InternetConnectionChecker().hasConnection;
        if (!isConnected) {
          throw Exception("No internet connection");
        }

        // Get the authenticated user's ID
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception("User is not authenticated");
        }
        String userId = user.uid; // Get the FirebaseAuth user ID

        // Firestore document structure
        Map<String, dynamic> surveyData = {
          'createdAt': Timestamp.now(),
          'questionResponseJsonArray': questionResponses.map((e) => e.toJson()).toList(),
          'questionScore': totalScore.value,
          'userId': userId, // existing field
          'id': userId,     // 🔥 new field added to match Users collection
        };


        // Submit to Firestore
        await FirebaseFirestore.instance.collection('Surveys').add(surveyData);

        // Success: No need to stop loader here; it will be handled after navigation
        Loaders.successSnackBar(
          title: 'Success!',
          message: "Survey submitted successfully!",
        );
      } catch (e) {
        // Throw error back to UI for handling
        throw Exception("Failed to submit survey: $e");
      }
    }
  }
