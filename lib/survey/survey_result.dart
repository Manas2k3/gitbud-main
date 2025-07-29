import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:animated_flip_counter/animated_flip_counter.dart';

import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/navigation_menu.dart';
import 'package:gibud/survey/survey_report.dart';

import '../data/repositories/survey/survey_questions.dart';
import '../data/repositories/survey/survey_suggestions.dart';
import 'model/survey_model.dart';

int getMarksFromResponse(SurveyQuestion question, String responseKey) {
  final keys = question.responses.keys.map((e) => e.trim()).toList();
  final index = keys.indexOf(responseKey.trim());
  return index != -1 ? index + 1 : 0;
}

class SurveyResultScreen extends StatefulWidget {
  final Map<int, String> responses;
  final int calculatedTotalScore;
  final List<SurveyQuestion> questions;

  const SurveyResultScreen({
    Key? key,
    required this.responses,
    required this.calculatedTotalScore,
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

  int _animatedScore = 0;

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

    // Gradual counter animation
    Future.delayed(const Duration(milliseconds: 300), () {
      int current = 0;
      final target = widget.calculatedTotalScore;
      const duration = Duration(milliseconds: 30); // speed of increment

      Timer.periodic(duration, (timer) {
        if (current >= target) {
          timer.cancel();
        } else {
          setState(() {
            current++;
            _animatedScore = current;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getSeverity(int score) {
    if (score <= 20)
      return "Your responses indicate that you have a Low Risk for digestive issues";
    if (score <= 35)
      return "Your responses indicate that you have a Moderate Risk for digestive issues";
    if (score <= 39)
      return "Your responses indicate that you have a High Risk for digestive issues";
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
      for (var q in widget.questions) q.resultCategory: "Not At Risk"
    };

    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final response = widget.responses[i];
      final score = getMarksFromResponse(question, response!);

      if (score >= 1) {
        riskLevels[question.resultCategory] = switch (score) {
          1 => "Low Risk",
          2 => "Moderate Risk",
          3 => "High Risk",
          4 => "Very High Risk",
          _ => "Not At Risk",
        };
      }
    }

    return riskLevels;
  }

  @override
  Widget build(BuildContext context) {
    final severity = _getSeverity(_animatedScore);
    final severityColor = _getSeverityColor(_animatedScore);
    final riskLevels = _buildRiskLevels();

    final questionDetails = List<Map<String, dynamic>>.generate(
      widget.questions.length,
      (index) {
        final question = widget.questions[index];
        final response = widget.responses[index];
        final score = getMarksFromResponse(question, response!);
        final risk = riskLevels[question.resultCategory] ?? "Not At Risk";

        return {
          'question': question.question,
          'response': response,
          'score': score,
          'riskLevel': risk,
        };
      },
    );

    List<Color> _getGradientColors(int score) {
      if (score <= 20) {
        return [Colors.green.shade100, Colors.green.shade700];
      } else if (score <= 35) {
        return [Colors.amber.shade100, Colors.amber.shade700];
      } else if (score <= 39) {
        return [Colors.orange.shade100, Colors.orange.shade700];
      } else {
        return [Colors.red.shade100, Colors.red.shade300];
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
            onPressed: () {
              Get.offAll(NavigationMenu());
            },
            icon: Icon(Icons.arrow_back)),
        automaticallyImplyLeading: false,
        title: Text("Survey Results",
            style:
                GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: _getGradientColors(_animatedScore),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("Total Score: ",
                                    style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600)),
                                AnimatedFlipCounter(
                                  duration: const Duration(seconds: 2),
                                  value: _animatedScore,
                                  textStyle: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              severity,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Response Summary",
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: ListView.builder(
                  itemCount: widget.questions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemBuilder: (context, index) {
                    final question = widget.questions[index];
                    final response = widget.responses[index];
                    final score = getMarksFromResponse(question, response!);
                    final risk = riskLevels[question.resultCategory];

                    return ResponseBox(
                      questionNumber: index + 1,
                      question: question.question,
                      response: response,
                      score: score,
                      riskLevel: risk,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
                  totalScore: widget.calculatedTotalScore,
                  questionDetails: questionDetails,
                ),
              );
            },
            label: const Text("View Detailed Report",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            icon: const Icon(
              Icons.description_outlined,
              color: Colors.white,
            ),
            backgroundColor: Colors.green.shade600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

    final suggestion = () {
      try {
        final surveyQuestion = surveySuggestions[questionNumber - 1];
        final responseSuggestion = surveyQuestion['responses'].firstWhere(
          (resp) => resp['response'] == response,
          orElse: () => {'suggestion': 'No suggestion available'},
        );
        return responseSuggestion['suggestion'];
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
                  style:
                      TextStyle(color: boxColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
