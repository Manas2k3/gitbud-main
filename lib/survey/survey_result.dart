import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:gibud/survey/survey_report.dart';

import '../data/repositories/survey/survey_questions.dart';
import '../data/repositories/survey/survey_suggestions.dart';
import 'model/survey_model.dart';

class SurveyResultScreen extends StatelessWidget {
  final Map<int, String> responses;
  final int totalScore;
  final String? surveyCategory;
  final String? riskLevel;

  const SurveyResultScreen({
    required this.responses,
    required this.totalScore,
    this.surveyCategory,
    this.riskLevel,
    required resultCategory,
  });

  String _getSeverity(int score) {
    if (score <= 20) {
      return "Your responses indicate that you have a Low Risk for digestive issues";
    } else if (score >= 21 && score <= 35) {
      return "Your responses indicate that you have a Moderate Risk for digestive issues";
    } else if (score >= 36 && score <= 39) {
      return "Your responses indicate that you have a High Risk for digestive issues";
    } else {
      return "Your responses indicate that you have a Very High Risk for digestive issues";
    }
  }

  Color _getSeverityColor(int score) {
    if (score <= 20) {
      return Colors.green;
    } else if (score >= 21 && score <= 35) {
      return Colors.amber;
    } else if (score >= 36 && score <= 39) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Map<String, String> _buildRiskLevels() {
    Map<String, String> riskLevels = {
      "Tobacco Use": "Not At Risk",
      "Alcohol Use": "Not At Risk",
      "Anxiety, depression": "Not At Risk",
      "Family History": "Not At Risk",
      "Bloating": "Not At Risk",
      "Constipation": "Not At Risk",
      "Physical Activity": "Not At Risk",
      "Environmental Stress": "Not At Risk",
      "Fever, nausea": "Not At Risk",
      "Stress Levels": "Not At Risk",
      "Medication Stress": "Not At Risk",
      "Digestive Issues": "Not At Risk",
    };

    responses.forEach((index, response) {
      SurveyQuestion question = surveyQuestions[index];
      int score = question.responses.indexOf(response) + 1;
      String riskLevelDescription;

      if (totalScore <= 20) {
        riskLevelDescription = "Low Risk";
      } else if (totalScore >= 21 && totalScore <= 35) {
        riskLevelDescription = "Moderate Risk";
      } else if (totalScore >= 36 && totalScore <= 39) {
        riskLevelDescription = "High Risk";
      } else {
        riskLevelDescription = "Very High Risk";
      }

      riskLevels[question.resultCategory] = riskLevelDescription;
    });

    return riskLevels;
  }

  @override
  Widget build(BuildContext context) {
    String severity = _getSeverity(totalScore);
    Color severityColor = _getSeverityColor(totalScore);
    Map<String, String> riskLevels = _buildRiskLevels();

    List<Map<String, dynamic>> questionDetails = [];
    for (var index = 0; index < surveyQuestions.length; index++) {
      SurveyQuestion question = surveyQuestions[index];
      String response = responses[index] ?? "No response";
      int score = question.responses.indexOf(response) + 1;
      String riskLevel = riskLevels[question.resultCategory] ?? "Not At Risk";
      questionDetails.add({
        'question': question.question,
        'response': response,
        'score': score,
        'riskLevel': riskLevel,
      });
    }

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
                    showBackArrow: true,
                    leadingOnPressed: () {
                      Get.offAll(NavigationMenu());
                    },
                    leadingIcon: Iconsax.arrow_left,
                    title: Text(
                      "SURVEY RESULT",
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Score: $totalScore',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      severity,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: severityColor,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: surveyQuestions.length,
                        itemBuilder: (context, index) {
                          SurveyQuestion question = surveyQuestions[index];
                          String response = responses[index] ?? "N/A";
                          int score = question.responses.indexOf(response) + 1;
      
                          return ResponseBox(
                            questionNumber: index + 1,
                            question: question.question,
                            response: response,
                            score: score,
                            riskLevel: riskLevels[question.resultCategory],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Get.to(() => SurveyReport(
                  riskLevels: riskLevels,
                  responses: responses,
                  totalScore: totalScore,
              questionDetails: questionDetails,
                ));
          },
          label: const Text(
            "Get a detailed report",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.description),
          backgroundColor: Colors.greenAccent,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

class ResponseBox extends StatelessWidget {
  final int questionNumber;
  final String question;
  final String response;
  final int score;
  final String? riskLevel;

  const ResponseBox({
    Key? key,
    required this.questionNumber,
    required this.question,
    required this.response,
    required this.score,
    this.riskLevel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color boxColor;
    String riskLevelDescription = riskLevel ?? "N/A";
    String suggestion = "No suggestion available";

    switch (score) {
      case 1:
        boxColor = Colors.green;
        riskLevelDescription = "Low Risk";
        break;
      case 2:
        boxColor = Colors.amber;
        riskLevelDescription = "Moderate Risk";
        break;
      case 3:
        boxColor = Colors.orange;
        riskLevelDescription = "High Risk";
        break;
      case 4:
        boxColor = Colors.red;
        riskLevelDescription = "Very High Risk";
        break;
      default:
        boxColor = Colors.grey;
        riskLevelDescription = "N/A";
    }

    final surveyQuestion = surveySuggestions[questionNumber - 1];
    final responseSuggestion = surveyQuestion['responses'].firstWhere(
      (resp) => resp['response'] == response,
      orElse: () => {'suggestion': 'No suggestion available'},
    );
    suggestion = responseSuggestion['suggestion'];

    bool showSuggestion = riskLevelDescription != "Low Risk";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: boxColor, width: 8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Q$questionNumber: $question",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Your answer: $response",
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  riskLevelDescription,
                  style:
                      TextStyle(color: boxColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 100),
                Visibility(
                  visible: showSuggestion,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Suggestion"),
                            content: Text(suggestion),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text("Close"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      height: 40,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: boxColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Suggestion",
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
