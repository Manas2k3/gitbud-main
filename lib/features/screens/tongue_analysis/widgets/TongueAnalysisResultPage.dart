import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/tongue_analysis/tongue_analysis_page.dart';

class TongueAnalysisResultPage extends StatelessWidget {
  const TongueAnalysisResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};
    final String prediction = args['predicted_class']?.toLowerCase() ?? "unknown";
    final double confidence = args['confidence']?.toDouble() ?? 0.0;
    final File? imageFile = args['imageFile'];

    // 🌸 Mapping of model output → full condition keys
    final Map<String, String> labelToDetailKey = {
      "yellow": "yellow",
      "purple": "purple",
      "red": "red_tongue_stroke",
      "white": "white_tongue_anemia",
      "deep_red": "deep_red",
      "indigo_violet": "indigo_violet",
    };

    // 💊 Diagnosis details
    final Map<String, dynamic> diagnosisDetails = {
      "yellow": {
        "description": "Yellow tongue may be a potential indicator of diabetes. It's advised to consult your healthcare provider for further evaluation.",
        "risk": 2,
      },
      "purple": {
        "description": "Purple tongue with greasy coating may suggest underlying conditions like cancer. Please seek immediate medical attention.",
        "risk": 3,
      },
      "red_tongue_stroke": {
        "description": "An unusually shaped red tongue could signify risk of acute stroke. Prompt medical consultation is recommended.",
        "risk": 3,
      },
      "white_tongue_anemia": {
        "description": "White tongue is a possible sign of anemia. Consider checking your iron levels and improving nutritional intake.",
        "risk": 2,
      },
      "deep_red": {
        "description": "A deep-red tongue is associated with severe COVID-19 cases. It's advised to get a medical screening done immediately.",
        "risk": 3,
      },
      "indigo_violet": {
        "description": "Indigo or violet tongue may indicate vascular or gastrointestinal issues. It's best to undergo a medical check-up.",
        "risk": 2,
      },
    };

    // 🧠 Final key to use
    final String? mappedKey = labelToDetailKey[prediction];
    final detail = mappedKey != null && diagnosisDetails.containsKey(mappedKey)
        ? diagnosisDetails[mappedKey]
        : {
      "description": "No information available for this condition.",
      "risk": 0,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tongue Analysis"),
        leading: IconButton(
          onPressed: () {
            Get.offAll(TongueAnalysisPage());
          },
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏷️ Prediction Title
            Text(
              prediction.replaceAll("_", " ").capitalizeFirst ?? "Prediction",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // 📊 Confidence
            Text(
              "Confidence: ${confidence.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 16,
                color: Colors.purple.shade300,
              ),
            ),
            const SizedBox(height: 16),

            // 📷 Image
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),

            const Text(
              "Tongue Image",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Text(
              "Uploaded Image",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 🩺 Description
            Text(
              detail["description"],
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),

            // ⚠️ Risk Level
            const Text(
              "Risk Level",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (detail["risk"] as int) / 3.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text("${detail["risk"]}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
