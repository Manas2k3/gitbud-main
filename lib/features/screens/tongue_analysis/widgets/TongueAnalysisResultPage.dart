import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/tongue_analysis/tongue_analysis_page.dart';

class TongueAnalysisResultPage extends StatelessWidget {
  const TongueAnalysisResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};
    final String prediction = args['predicted_class'] ?? "Unknown";
    final double confidence = args['confidence']?.toDouble() ?? 0.0;
    final File? imageFile = args['imageFile'];

    final Map<String, dynamic> diagnosisDetails = {
      "mild_anemia": {
        "description":
        "Your tongue shows signs that may be associated with mild anemia. Stay hydrated and consult a physician.",
        "risk": 1,
      },
      "white_tongue_anemia": {
        "description":
        "This may be a sign of white tongue condition associated with anemia. Maintain good oral hygiene and check your iron levels.",
        "risk": 2,
      },
      "red_tongue_stroke": {
        "description":
        "This may indicate high temperature or stroke risk. Seek medical attention if symptoms persist.",
        "risk": 3,
      },
      "purple": {
        "description":
        "This tongue appearance might suggest poor circulation or underlying health issues. Please consult your doctor for further evaluation.",
        "risk": 2,
      },
    };

    final detail = diagnosisDetails[prediction.toLowerCase()] ??
        {
          "description": "No information available for this condition.",
          "risk": 0,
        };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tongue Analysis"),
        leading: IconButton(onPressed: () {Get.offAll(TongueAnalysisPage());}, icon: Icon(Icons.arrow_back)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prediction
            Text(
              prediction.replaceAll("_", " ").capitalizeFirst ?? "Prediction",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),

            // Confidence
            Text(
              "Confidence: ${confidence.toStringAsFixed(1)}%",
              style: TextStyle(
                fontSize: 16,
                color: Colors.purple.shade300,
              ),
            ),
            const SizedBox(height: 16),

            // Image
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

            // Description
            Text(
              detail["description"],
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),

            // Risk Level
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
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text("${detail["risk"]}"),
              ],
            )
          ],
        ),
      ),
    );
  }
}
