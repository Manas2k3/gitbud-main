import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/survey/survey_report.dart';

import '../data/repositories/survey/survey_questions.dart';
import '../data/repositories/survey/survey_suggestions.dart';
import 'model/survey_model.dart';

int _getMarksFromResponse(SurveyQuestion question, String responseKey) {
  final keys = question.responses.keys.toList();
  final index = keys.indexOf(responseKey.trim());
  return index != -1 ? index + 1 : 0;
}

class SurveyResultScreen extends StatelessWidget {
  final Map<int, String> responses;
  final int calculatedTotalScore;
  final String? surveyCategory;
  final String? riskLevel;

  const SurveyResultScreen({
    required this.responses,
    required this.calculatedTotalScore,
    this.surveyCategory,
    this.riskLevel,
    Key? key,
    required resultCategory,
  }) : super(key: key);

  String _getSeverity(int score) {
    if (score <= 20) return "Your responses indicate that you have a Low Risk for digestive issues";
    if (score <= 35) return "Your responses indicate that you have a Moderate Risk for digestive issues";
    if (score <= 39) return "Your responses indicate that you have a High Risk for digestive issues";
    return "Your responses indicate that you have a Very High Risk for digestive issues";
  }

  Color _getSeverityColor(int score) {
    if (score <= 20) return Colors.green;
    if (score <= 35) return Colors.amber;
    if (score <= 39) return Colors.orange;
    return Colors.red;
  }

  Map<String, String> _buildRiskLevels() {
    final Map<String, String> riskLevels = {
      for (var q in surveyQuestions) q.resultCategory: "Not At Risk"
    };

    responses.forEach((index, response) {
      final question = surveyQuestions[index];
      final score = _getMarksFromResponse(question, response);

      if (score >= 1) {
        riskLevels[question.resultCategory] = switch (score) {
          1 => "Low Risk",
          2 => "Moderate Risk",
          3 => "High Risk",
          4 => "Very High Risk",
          _ => "Not At Risk",
        };
      }
    });

    return riskLevels;
  }


  @override
  Widget build(BuildContext context) {
    final calculatedTotalScore = responses.entries.fold<int>(0, (sum, entry) {
      final question = surveyQuestions[entry.key];
      final score = _getMarksFromResponse(question, entry.value);
      return sum + score;
    });

    final severity = _getSeverity(calculatedTotalScore);
    final severityColor = _getSeverityColor(calculatedTotalScore);
    final riskLevels = _buildRiskLevels();

    final questionDetails = List<Map<String, dynamic>>.generate(
      surveyQuestions.length,
          (index) {
        final question = surveyQuestions[index];
        final response = responses[index] ?? "No response";
        final score = _getMarksFromResponse(question, response);
        final risk = riskLevels[question.resultCategory] ?? "Not At Risk";

        return {
          'question': question.question,
          'response': response,
          'score': score,
          'riskLevel': risk,
        };
      },
    );

    return WillPopScope(
      onWillPop: () async {
        Get.offAll(() => const NavigationMenu());
        return false;
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
                    leadingOnPressed: () => Get.offAll(() => const NavigationMenu()),
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
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Score: $calculatedTotalScore',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Text(severity,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: severityColor,
                        )),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: surveyQuestions.length,
                        itemBuilder: (context, index) {
                          final question = surveyQuestions[index];
                          final response = responses[index] ?? "N/A";
                          final score = _getMarksFromResponse(question, response);

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
              totalScore: calculatedTotalScore,
              questionDetails: questionDetails,
            ));
          },
          label: const Text("Get a detailed report", style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.description),
          backgroundColor: Colors.greenAccent,
        ),
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
    required this.questionNumber,
    required this.question,
    required this.response,
    required this.score,
    this.riskLevel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riskDescription = riskLevel ?? "N/A";

    final List<Color> severityColors = [
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.red,
    ];

    final boxColor = (score >= 1 && score <= severityColors.length)
        ? severityColors[score - 1]
        : Colors.grey;


    final surveyQuestion = surveySuggestions[questionNumber - 1];
    final responseSuggestion = surveyQuestion['responses'].firstWhere(
          (resp) => resp['response'] == response,
      orElse: () => {'suggestion': 'No suggestion available'},
    );
    final suggestion = responseSuggestion['suggestion'];
    final showSuggestion = riskDescription != "Low Risk";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: boxColor, width: 8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q$questionNumber: $question", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Your answer: $response", style: GoogleFonts.poppins()),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  riskDescription,
                  style: TextStyle(color: boxColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
