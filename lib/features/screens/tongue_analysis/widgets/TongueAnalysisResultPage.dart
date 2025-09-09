import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gibud/features/screens/tongue_analysis/tongue_analysis_page.dart';

class TongueAnalysisResultPage extends StatelessWidget {
  const TongueAnalysisResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments ?? {};

    // ✅ Extract Color Prediction
    final colorPrediction = args['color_prediction'] ?? {};
    final String colorLabel = colorPrediction['Result']?['label'] ?? "Unknown";
    final double confidence = colorPrediction['Result']?['confidence_percent']?.toDouble() ?? 0.0;
    final String colorExplanation = colorPrediction['Explanation'] ?? "No description available.";
    final List colorSuggestions = colorPrediction['Suggestions'] ?? [];

    // ✅ Extract Shape Prediction
    final shapePrediction = args['shape_prediction'] ?? {};
    final double shapeScore = (shapePrediction['Score'] ?? 0.0).toDouble();
    final String shapeExplanation = shapePrediction['Explanation'] ?? "No interpretation available.";
    final List shapeSuggestions = shapePrediction['Suggestions'] ?? [];

    // ✅ Extract Texture Prediction
    final texturePrediction = args['texture_prediction'] ?? {};
    final double textureScore = (texturePrediction['Score'] ?? 0.0).toDouble();
    final String textureExplanation = texturePrediction['Explanation'] ?? "No interpretation available.";
    final List textureSuggestions = texturePrediction['Suggestions'] ?? [];

    final File? imageFile = args['imageFile'];

    final Map<String, String> labelToDisplay = {
      "yellow": "Yellow",
      "purple": "Purple",
      "red": "Red Tongue Stroke",
      "white": "White",
      "deep_red": "Deep Red",
      "indigo_violet": "Indigo-Violet",
    };
    final String displayLabel = labelToDisplay[colorLabel.toLowerCase()] ?? colorLabel.capitalizeFirst ?? "Unknown";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAll(const TongueAnalysisPage());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.red.shade50,
        appBar: AppBar(
          title: const Text(
            "Analysis Result",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.red.shade100,
          leading: IconButton(
            onPressed: () {
              Get.offAll(const TongueAnalysisPage());
            },
            icon: const Icon(Icons.arrow_back, color: Colors.redAccent),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    imageFile,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(),
              const SizedBox(height: 20),

              // 🖌 Color Prediction Card
              _buildInfoCard(
                icon: LucideIcons.droplet,
                title: "Color: $displayLabel",
                description: colorExplanation,
                suggestions: colorSuggestions,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 16),

              // 📏 Shape Prediction Card
              _buildInfoCard(
                icon: LucideIcons.crop,
                title: "Shape Analysis",
                description: shapeExplanation,
                suggestions: shapeSuggestions,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 16),

              // 🌿 Texture Prediction Card
              _buildInfoCard(
                icon: LucideIcons.layers,
                title: "Texture Analysis",
                description: textureExplanation,
                suggestions: textureSuggestions,
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required List suggestions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Row
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.shade50,
                child: Icon(icon, color: Colors.redAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(color: Colors.black87, fontSize: 15),
          ),

          // 📌 Expandable Suggestions
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
              iconColor: Colors.redAccent,
              collapsedIconColor: Colors.red.shade300,
              title: const Text(
                "View Suggestions",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              children: suggestions.map<Widget>((sugg) {
                return _buildSuggestionTile(sugg);
              }).toList(),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(Map sugg) {
    final String item = sugg['item'] ?? "Unknown";
    final String details = sugg['details'] ?? "";
    final String howItHelps = sugg['how_it_helps'] ?? "";
    final String type = sugg['type'] ?? "";

    final Map<String, IconData> typeIcons = {
      "action": LucideIcons.checkCircle,
      "food": LucideIcons.apple,
      "liquid": LucideIcons.cupSoda,
      "medication": LucideIcons.pill,
      "urgent": LucideIcons.alertTriangle,
    };

    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        leading: Icon(typeIcons[type] ?? LucideIcons.info, color: Colors.redAccent),
        title: Text(
          item,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "$details\n\nHow it helps: $howItHelps",
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ),
    );
  }
}
