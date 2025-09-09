import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:gibud/navigation_menu.dart';
import 'package:gibud/survey/survey_report.dart';

import '../data/repositories/survey/survey_suggestions.dart';
import 'model/survey_model.dart';

/// Reversed scoring: Option 1 = 4 (highest risk) ... Option 4 = 1 (lowest risk)
int getMarksFromResponse(SurveyQuestion question, String responseKey) {
  final keys = question.responses.keys.map((e) => e.trim()).toList();
  final index = keys.indexOf(responseKey.trim());
  return index != -1 ? (keys.length - index) : 0; // 🔄 reverse scoring
}

class SurveyResultScreen extends StatefulWidget {
  final Map<int, String> responses;
  final int calculatedTotalScore;   // kept for internal/dev reference
  final double percentageScore;     // what we display to the user
  final List<SurveyQuestion> questions;

  const SurveyResultScreen({
    Key? key,
    required this.responses,
    required this.calculatedTotalScore,
    required this.percentageScore,
    required this.questions,
  }) : super(key: key);

  @override
  State<SurveyResultScreen> createState() => _SurveyResultScreenState();
}

class _SurveyResultScreenState extends State<SurveyResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  double _animatedPercent = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Animate percentage display
    Future.delayed(const Duration(milliseconds: 300), () {
      double current = 0;
      const duration = Duration(milliseconds: 20);
      Timer.periodic(duration, (timer) {
        if (current >= widget.percentageScore) {
          setState(() => _animatedPercent = widget.percentageScore);
          timer.cancel();
        } else {
          setState(() {
            current += 1;
            _animatedPercent = current;
          });
        }
      });
    });
  }

  /// Percentage-based severity (display only)
  // String _getSeverity(double percent) {
  //   if (percent <= 25) return "Your responses indicate a Very High Risk for digestive issues";
  //   if (percent <= 50) return "Your responseYour responses indicate a High Risk for digestive issues";
  //   if (percent <= 75) return "Your responses indicate a Moderate Risk for digestive issues";
  //   return "Your responses indicate a Low Risk for digestive issues";
  // }

  Color _getSeverityColor(double percent) {
    if (percent <= 25) return Colors.red;
    if (percent <= 50) return Colors.orange;
    if (percent <= 75) return Colors.amber;
    return Colors.green;
  }

  /// Per-question risk labels based on the (reversed) option score:
  /// 1 => Low, 2 => Moderate, 3 => High, 4 => Very High
  Map<String, String> _buildRiskLevels() {
    final Map<String, String> riskLevels = {
      for (var q in widget.questions) q.resultCategory: "Not At Risk"
    };

    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final response = widget.responses[i];
      if (response == null) continue;

      final score = getMarksFromResponse(question, response);

      if (score >= 1) {
        riskLevels[question.resultCategory] = switch (score) {
          1 => "Very High Risk",
          2 => "High Risk",
          3 => "Moderate Risk",
          4 => "Low Risk",
          _ => "Not At Risk",
        };
      }
    }
    return riskLevels;
  }

  @override
  Widget build(BuildContext context) {
    // final severity = _getSeverity(widget.percentageScore);
    final severityColor = _getSeverityColor(widget.percentageScore);
    final riskLevels = _buildRiskLevels();

    // For the detailed report screen
    final questionDetails = List<Map<String, dynamic>>.generate(
      widget.questions.length,
          (index) {
        final question = widget.questions[index];
        final response = widget.responses[index];
        final score = response == null ? 0 : getMarksFromResponse(question, response);
        final risk = riskLevels[question.resultCategory] ?? "Not At Risk";
        return {
          'question': question.question,
          'response': response ?? "",
          'score': score,
          'riskLevel': risk,
        };
      },
    );

    String _getHealthMessage(double riskPercent) {
      final healthScore = (riskPercent).clamp(0, 100);
      if (healthScore >= 75) return "Your health looks excellent!";
      if (healthScore >= 50) return "Your health is in a good state";
      if (healthScore >= 25) return "Your health needs attention.";
      return "Your health is at high risk. Consider lifestyle changes.";
    }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.offAll(NavigationMenu()),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          "Survey Results",
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card with animated percentage + severity line
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [severityColor.withOpacity(0.2), severityColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Health Score: ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                AnimatedFlipCounter(
                                  duration: const Duration(seconds: 2),
                                  value: _animatedPercent.toInt(),
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  "%",
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getHealthMessage(widget.percentageScore),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 8),
                            // Text(
                            //   severity,
                            //   style: GoogleFonts.poppins(
                            //     fontSize: 16,
                            //     fontWeight: FontWeight.w500,
                            //     color: Colors.black,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Response Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Per-question summary list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: ListView.builder(
                  itemCount: widget.questions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    final question = widget.questions[index];
                    final response = widget.responses[index];
                    final score = response == null
                        ? 0
                        : getMarksFromResponse(question, response);
                    final risk = riskLevels[question.resultCategory];

                    return ResponseBox(
                      questionNumber: index + 1,
                      question: question.question,
                      response: response ?? "",
                      score: score,                 // reversed scoring already applied
                      riskLevel: risk,              // "Low/Moderate/High/Very High"
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // Keep existing FAB behavior (navigates to detailed report)
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () {
              Get.to(
                    () => SurveyReport(
                  riskLevels: riskLevels,
                  responses: widget.responses,
                  totalScore: widget.calculatedTotalScore, // kept for dev reference
                  questionDetails: questionDetails,
                ),
              );
            },
            label: const Text(
              "View Detailed Report",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            icon: const Icon(Icons.description_outlined, color: Colors.white),
            backgroundColor: Colors.green.shade600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Same look & feel as before; only logic behind colors/labels is aligned to reversed scoring.
class ResponseBox extends StatelessWidget {
  final int questionNumber;
  final String question;
  final String response;
  final int score;          // 1..4 after reversal
  final String? riskLevel;  // "Low Risk" ... "Very High Risk"

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

    // 1=>green, 2=>amber, 3=>orange, 4=>red (matches old UI vibe)
    final List<Color> severityColors = [
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
    ];

    final boxColor = (score >= 1 && score <= severityColors.length)
        ? severityColors[score - 1]
        : Colors.grey;

    // Keep suggestions logic intact (UI unchanged: not shown when Low Risk)
    final suggestion = () {
      try {
        final surveyQuestion = surveySuggestions[questionNumber - 1];
        final responseSuggestion = (surveyQuestion['responses'] as List).firstWhere(
              (resp) => resp['response'] == response,
          orElse: () => {'suggestion': 'No suggestion available'},
        );
        return responseSuggestion['suggestion'] as String;
      } catch (_) {
        return 'No suggestion available';
      }
    }();

    final showSuggestion = riskDescription != "Low Risk";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Q$questionNumber: $question",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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

            // Keep UI unchanged — but if you ever want to show suggestions again,
            // just uncomment this block ⤵
            /*
            if (showSuggestion) ...[
              const SizedBox(height: 8),
              Text(
                "Suggestion: $suggestion",
                style: GoogleFonts.poppins(fontStyle: FontStyle.italic),
              ),
            ],
            */
          ],
        ),
      ),
    );
  }
}
