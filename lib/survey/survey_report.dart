import 'dart:io';

import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:get/get.dart';

import 'package:gibud/survey/survey_result.dart';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;

import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:iconsax/iconsax.dart';

import 'package:logger/logger.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../common/components/CurvedPainter.dart';

import '../common/widgets/risk_score_widget/risk_score_widget.dart';

import '../data/repositories/survey/survey_questions.dart';

import '../secrets.dart';

import 'model/survey_model.dart';

class SurveyReport extends StatefulWidget {
  final Map<int, String> responses;

  final int totalScore;

  final Map<String, String> riskLevels;

  final List<Map<String, dynamic>> questionDetails;

  const SurveyReport(
      {Key? key,
      required this.responses,
      required this.totalScore,
      required this.riskLevels,
      required this.questionDetails})
      : super(key: key);

  @override
  State<SurveyReport> createState() => _SurveyReportState();
}

class _SurveyReportState extends State<SurveyReport> {
  final _auth = FirebaseAuth.instance;

  String name = 'User';

  String gender = 'N/A';

  int age = 0;

  double height = 0.0;

  double weight = 0.0;

  double bmi = 0.0;

  String bmiCategory = 'N/A';

  double idealBMI = 0.0;

  bool isLoading = true;

  bool isLoadingAI = false;

  final Logger logger = Logger();

  Map<String, String> aiSuggestions = {};

  @override
  void initState() {
    super.initState();

    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String? userId = _auth.currentUser?.uid;

      if (userId != null && userId.isNotEmpty) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;

          setState(() {
            name = userData?['name'] ?? 'User       ';

            gender = userData?['gender'] ?? 'N/A';

            age = (userData?['age'] ?? 0) is int ? userData!['age'] : int.tryParse(userData!['age'].toString()) ?? 0;
            height = (userData['height'] ?? 0.0) is double ? userData['height'] : double.tryParse(userData!['height'].toString()) ?? 0.0;
            weight = (userData['weight'] ?? 0.0) is double ? userData['weight'] : double.tryParse(userData!['weight'].toString()) ?? 0.0;


            bmi = _calculateBMI(height, weight);

            bmiCategory = _getBMICategory(bmi);

            idealBMI = _getIdealBMI(height);

            isLoading = false;
          });
        } else {
          logger.e('User  document does not exist in Firestore.');

          setState(() => isLoading = false);
        }
      } else {
        logger.e('User  is not authenticated.');

        setState(() => isLoading = false);
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');

      setState(() => isLoading = false);
    }
  }

  double _calculateBMI(double height, double weight) {
    if (height <= 0 || weight <= 0) return 0.0;

    double heightInMeters = height / 100;

    return weight / (heightInMeters * heightInMeters);
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return 'Normal';
    } else if (bmi >= 25 && bmi < 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  double _getIdealBMI(double height) {
    double heightInMeters = height / 100;

    return 21.7 * (heightInMeters * heightInMeters);
  }

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  Future<Uint8List?> _captureScrollableWidgetAsImage() async {
    try {
      await Future.delayed(Duration(milliseconds: 500));

      RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;

      if (boundary == null) return null;

      final double pixelRatio = 3.0;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturing widget: $e');

      return null;
    }
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      );

      Uint8List? capturedImage = await _captureScrollableWidgetAsImage();

      if (capturedImage == null) {
        Navigator.pop(context);

        print('No image captured');

        return;
      }

      final pdf = pw.Document();

      final image = pw.MemoryImage(capturedImage);

      ui.decodeImageFromList(capturedImage, (ui.Image img) async {
        final double imageWidth = img.width.toDouble();

        final double imageHeight = img.height.toDouble();

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(imageWidth, imageHeight),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );

        final output = await getTemporaryDirectory();

        final file = File("${output.path}/Gut Health Score Report.pdf");

        await file.writeAsBytes(await pdf.save());

        Navigator.pop(context);

        final xfile = XFile(file.path);

        await Share.shareXFiles(
          [xfile],
          subject: 'Gut Health Score Report',
          text: 'Here is your gut health report',
        );
      });
    } catch (e) {
      Navigator.pop(context);

      print("Error generating PDF: $e");

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to generate PDF. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchAISuggestions() async {
    final prompt = generatePrompt(_buildRiskLevels());

    final response = await getGeminiResponse(prompt);

    if (response != null) {
      print('AI Response: $response');

      setState(() {
        aiSuggestions = parseAISuggestions(response);

        print('$aiSuggestions');
      });
    } else {
      logger.e("Failed to fetch AI suggestions");
    }
  }

  String generatePrompt(Map<String, String> riskLevels) {
    String prompt =
        "Provide 5 short and effective health suggestions based on different gut health risk levels, listed point-wise with numbers (1 to 5). Do not exceed 5 points. :\n";

    riskLevels.forEach((category, risk) {
      prompt += "$category: $risk\n";
    });

    prompt += "\nDetailed Risk Levels for Each Question:\n";

    for (var detail in widget.questionDetails) {
      prompt += "Question: ${detail['question']}\n";

      prompt += "Your Response: ${detail['response']}\n";

      prompt += "Score: ${detail['score']}\n";

      prompt += "Risk Level: ${detail['riskLevel']}\n\n";
    }

    prompt +=
        "List the key components that should be included in a gut health report to make it informative and appealing to customers. Use bullet points and highlight important terms in bold. Include short, effective suggestions such as natural Indian remedies to reduce alcohol or tobacco cravings. Mention essential vitamins for gut health and recommend foods that help correct these deficiencies. Ensure the content is well-structured and informative. At the end, include a short disclaimer stating the report is not a substitute for professional medical advice and that consultation with a healthcare expert is recommended.";

    return prompt;
  }

  Future<String?> getGeminiResponse(String prompt) async {
    final apiKey = GEMINI_API_KEY;

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("GEMINI_API_KEY is not set in the .env file");
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );

    final content = [Content.text(prompt)];

    final response = await model.generateContent(content);

    return response.text;
  }

  Map<String, String> parseAISuggestions(String response) {
    Map<String, String> suggestions = {};

    List<String> lines =
        response.split('\n').where((line) => line.trim().isNotEmpty).toList();

    for (String line in lines) {
      String trimmedLine = line.trim();

      suggestions[trimmedLine] = trimmedLine;
    }

    return suggestions;
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



    widget.responses.forEach((index, response) {
      int _getMarksFromResponse(SurveyQuestion question, String responseKey) {
        final keys = question.responses.keys.toList();
        final index = keys.indexOf(responseKey.trim());
        return index != -1 ? index : -1;
      }

      SurveyQuestion question = surveyQuestions[index];

      // response is the selected response string
      var score = _getMarksFromResponse(question, response);


      if (score == -1) {
        // handle response not found case
      } else {
        score = score + 1; // if you want to add 1 as before
      }

      String riskLevelDescription;

      if (widget.totalScore <= 20) {
        riskLevelDescription = "Low Risk";
      } else if (widget.totalScore >= 21 && widget.totalScore <= 35) {
        riskLevelDescription = "Moderate Risk";
      } else if (widget.totalScore >= 36 && widget.totalScore <= 39) {
        riskLevelDescription = "High Risk";
      } else if (widget.totalScore >= 40 && widget.totalScore <= 42) {
        riskLevelDescription = "Very High Risk";
      } else {
        riskLevelDescription = "Unknown";
      }

      riskLevels[question.resultCategory] = riskLevelDescription;
    });

    return riskLevels;
  }

  List<TextSpan> _getTextSpans(String text) {
    List<TextSpan> textSpans = [];

    RegExp exp = RegExp(r'(\*\*.*?\*\*|##.*?##)|([^*#]+)');

    var matches = exp.allMatches(text);

    for (var match in matches) {
      if (match.group(1) != null) {
        String boldText = match.group(1)!;

        boldText = boldText.replaceAll(RegExp(r'\*\*|##'), '');

        textSpans.add(TextSpan(
          text: boldText,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(2) != null) {
        textSpans.add(TextSpan(
          text: match.group(2),
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black,
          ),
        ));
      }
    }

    return textSpans;
  }

  @override
  Widget build(BuildContext context) {

    String getDaySuffix(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    String formatDateWithSuffix(DateTime dateTime) {
      String day = DateFormat('d').format(dateTime);
      String suffix = getDaySuffix(int.parse(day));
      String formattedDate = DateFormat('MMMM, h:mm a').format(dateTime);
      return '$day$suffix $formattedDate';
    }
    int score = widget.questionDetails[0]['score'];

    String riskLevel;

    String riskExplanation;

    if (score == 1) {
      riskLevel = "Low Risk";

      riskExplanation = "Minimal smoking impact";
    } else if (score == 2) {
      riskLevel = "Moderate Risk";

      riskExplanation = "Moderate impact on health.";
    } else if (score == 3) {
      riskLevel = "High Risk";

      riskExplanation = "Significant impact on health.";
    } else if (score == 4) {
      riskLevel = "Very High Risk";

      riskExplanation = "Critical impact on health.";
    } else {
      riskLevel = "Unknown";

      riskExplanation = "Unknown risk level. Please consult health guidance.";
    }

    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: SingleChildScrollView(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.white,
              ))
            : RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        CustomPaint(
                          painter: CurvedPainter(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40, left: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BabyCue',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "107, KIIT-TBI, Campus 11, Bhubaneswar, 751024",
                                        style: GoogleFonts.poppins(color: Colors.white),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        formatDateWithSuffix(DateTime.now()),
                                        style: GoogleFonts.poppins(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 50),
                                  Text(
                                    "Hey, $name!",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Here's a detailed Gut Health report for you.",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(
                                    indent: 1,
                                    endIndent: 40,
                                    thickness: 0.5,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 1,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(Iconsax.personalcard,
                                      color: Colors.white),
                                ),
                                Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade100,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "$gender, $age years old",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade100,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.height,
                                          color: Colors.white),
                                      const SizedBox(width: 15),
                                      Text(
                                        "Height: $height cm",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade100,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.monitor_weight_outlined,
                                          color: Colors.white),
                                      const SizedBox(width: 15),
                                      Text(
                                        "Weight: $weight kg",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey.shade100,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Container(
                            height: 60,
                            width: MediaQuery.of(context).size.width * 1,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.blue,
                                      ),
                                      child: Icon(Icons.monitor_weight_outlined,
                                          color: Colors.grey.shade200)),
                                ),
                                Text(
                                  "BMI: ${bmi.toStringAsFixed(1)}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "$bmiCategory",
                                  style: GoogleFonts.poppins(
                                    color: bmiCategory == "Normal"
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            "Your Gut Test Score",
                            style: GoogleFonts.poppins(
                              color: Colors.blue,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        height: 40,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: Colors.blue,
                                        ),
                                        child: Icon(
                                          Icons.analytics_outlined,
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Score: ${widget.totalScore} / 52",
                                          style: GoogleFonts.poppins(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          widget.totalScore <= 20
                                              ? "Low Risk"
                                              : widget.totalScore <= 35
                                                  ? "Moderate Risk"
                                                  : widget.totalScore <= 39
                                                      ? "High Risk "
                                                      : "Very High Risk",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: widget.totalScore <= 20
                                                ? Colors.green
                                                : widget.totalScore <= 35
                                                    ? Colors.amber
                                                    : widget.totalScore <= 39
                                                        ? Colors.orange
                                                        : Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: widget.totalScore / 52,
                                      color: widget.totalScore <= 20
                                          ? Colors.green
                                          : widget.totalScore <= 35
                                              ? Colors.amber
                                              : widget.totalScore <= 39
                                                  ? Colors.orange
                                                  : Colors.redAccent,
                                      backgroundColor: Colors.grey.shade300,
                                      minHeight: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: GestureDetector(
                                        onTap: () async {
                                          setState(() {
                                            isLoadingAI = true;
                                          });
                                          await fetchAISuggestions();

                                          setState(() {
                                            isLoadingAI = false;
                                          });
                                        },
                                        child: Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.06,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.8,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              color: Colors.blueAccent),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Tap here for AI generated suggestions for a Healthy Gut',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 13),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              isLoadingAI
                                  ? CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade200,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.shade300,
                                              blurRadius: 4,
                                              offset: Offset(2, 2),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.transparent),
                                            width: double.infinity,
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: aiSuggestions.entries
                                                    .map((entry) {
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blueAccent
                                                            .shade100,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors
                                                                .grey.shade300,
                                                            blurRadius: 4,
                                                            offset:
                                                                Offset(2, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: RichText(
                                                        text: TextSpan(
                                                          children:
                                                              _getTextSpans(
                                                                  entry.key),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            RiskScoreWidget(
                              score: score,
                              riskLevel: riskLevel,
                              riskExplanation: riskExplanation,
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _generateAndSharePDF(context);
        },
        label: Text(
          "Share PDF",
          style: TextStyle(fontSize: 12),
        ),
        icon: Icon(
          Icons.share,
          size: 18,
        ),
        backgroundColor: Colors.greenAccent.shade100,
        elevation: 4.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}
