import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/custom_button.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/controllers/survey_controller.dart';
import 'package:gibud/utils/constants/animation_strings.dart';
import 'package:gibud/utils/popups/full_screen.dart';
import 'package:gibud/utils/popups/loaders.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/survey/survey_questions.dart';
import '../navigation_menu.dart';
import '../payment/payments_page.dart';
import 'model/survey_model.dart';
import 'survey_result.dart';

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final SurveyController surveyController = Get.put(SurveyController());
  Map<int, String> selectedResponses = {}; // Store selected responses
  String? gender; // Store gender info

  @override
  void initState() {
    super.initState();
    _fetchUserGender(); // Fetch gender on screen load
  }

  Future<void> _fetchUserGender() async {
    try {
      final user = FirebaseAuth.instance.currentUser ;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users') // Updated to fetch from 'Users' collection
            .doc(user.uid)
            .get();
        setState(() {
          gender = userDoc['gender'] as String?;
        });
      }
    } catch (e) {
      print("Error fetching gender: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Get.offAll(NavigationMenu());
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.green.shade100,
        body: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.green,
              child: Column(
                children: [
                  CustomAppBar(
                    actions: [
                      IconButton(
                        icon: Icon(Iconsax.logout, color: Colors.white),
                        onPressed: () {
                          Get.off(() => NavigationMenu());
                        },
                      ),
                    ],
                    title: Text(
                      'GUT HEALTH SURVEY',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "Answer each question on a scale of 0–3, where 0 refers to no issue and 3 refers to severe impact..",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: gender == null
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator while gender is being fetched
                  : ListView.builder(
                itemCount: surveyQuestions.length,
                itemBuilder: (context, index) {
                  SurveyQuestion question = surveyQuestions[index];
                  if (question.stringResourceId == 2131820790 && gender != 'Female') {
                    return SizedBox.shrink(); // Hide this question if the user is not female
                  }
                  return _buildQuestionCard(question, index);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomButton(
            buttonText: 'Submit',
            onTap: () => _submitSurvey(context),
            initialColor: Colors.green,
            pressedColor: Colors.green.shade100,
          ),
        ),
      ),
    );
  }

  int _getMarksFromResponse(String responseKey) {
    // Customize this mapping logic to suit your scoring system
    switch (responseKey) {
      case "0":
        return 0;
      case "1":
      case "1 to 2":
        return 1;
      case "3 to 5":
        return 2;
      case "6 to 10":
        return 3;
      default:
        return 0;
    }
  }


  Widget _buildQuestionCard(SurveyQuestion question, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Column(
              children: question.responses.entries.map((entry) {
                String responseKey = entry.key;
                String responseValue = entry.value;

                return RadioListTile<String>(
                  activeColor: Colors.green,
                  title: Text(responseKey),
                  value: responseKey,
                  groupValue: selectedResponses[index],
                  onChanged: (value) {
                    setState(() {
                      selectedResponses[index] = value!;
                      // Assign a score based on your own logic
                      int marks = _getMarksFromResponse(responseKey);
                      surveyController.selectAnswer(index, marks, question);
                    });
                  },
                );

              }).toList(),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _submitSurvey(BuildContext context) async {
    try {
      FullScreenLoader.openLoadingDialog(
        "Submitting your survey...",
        AnimationStrings.loadingAnimation,
      );

      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        FullScreenLoader.stopLoading();
        _showNoInternetDialog(context);
        return;
      }

      int requiredResponsesCount = surveyQuestions.where((question) {
        return !(question.stringResourceId == 2131820790 && gender != 'Female');
      }).length;

      if (selectedResponses.length == requiredResponsesCount) {
        await surveyController.submitSurvey(context);

        FullScreenLoader.stopLoading();
        Loaders.successSnackBar(
          title: 'Response Recorded',
          message: 'Your responses have been recorded successfully!',
        );

        Get.to(SurveyResultScreen(
          responses: selectedResponses,
          calculatedTotalScore: surveyController.totalScore.value,
          resultCategory: null,
        ));
      } else {
        FullScreenLoader.stopLoading();
        Loaders.warningSnackBar(
          title: 'Please answer all questions',
          message: "",
        );
      }
    } catch (e) {
      FullScreenLoader.stopLoading();
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}