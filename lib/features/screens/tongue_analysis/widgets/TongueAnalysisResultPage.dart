import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/tongue_analysis/tongue_analysis_page.dart';

class TongueAnalysisResultPage extends StatelessWidget {
  const TongueAnalysisResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};
    final String colorResult = args['color_result'] ?? "";
    final String colorDescription = args['color_description'] ?? "No description available.";

    final String predictionLabel = colorResult.split(" ").first.toLowerCase();

    final double shapeScore = (args['shape_score'] ?? 0.0).toDouble();
    final String shapeInterpretation = args['shape_interpretation'] ?? "No interpretation available.";

    final double textureScore = (args['texture_score'] ?? 0.0).toDouble();
    final String textureInterpretation = args['texture_interpretation'] ?? "No interpretation available.";

    final File? imageFile = args['imageFile'];

    // 🌸 Mapping of model output → display label
    final Map<String, String> labelToDisplay = {
      "yellow": "Yellow",
      "purple": "Purple",
      "red": "Red Tongue Stroke",
      "white": "White",
      "deep_red": "Deep Red",
      "indigo_violet": "Indigo-Violet",
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
      "white": {
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

    // 🧠 Final mapped label & detail
    final String displayLabel = labelToDisplay[predictionLabel] ?? predictionLabel.capitalizeFirst ?? "Unknown";
    final detail = diagnosisDetails[predictionLabel] ??
        {
          "description": "No information available for this condition.",
          "risk": 0,
        };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAll(const TongueAnalysisPage());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tongue Analysis"),
          leading: IconButton(
            onPressed: () {
              Get.offAll(const TongueAnalysisPage());
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
              // 🖌 Color Prediction
              Text(
                "Color: $displayLabel",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(colorDescription),
              const SizedBox(height: 16),

              // 📏 Shape Prediction
              Text(
                "Shape Analysis:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(shapeInterpretation),
              const SizedBox(height: 16),

              // 🌿 Texture Prediction
              Text(
                "Texture Analysis:",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(textureInterpretation),
              const SizedBox(height: 16),

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
            ],
          ),
        ),
      ),
    );
  }
}
