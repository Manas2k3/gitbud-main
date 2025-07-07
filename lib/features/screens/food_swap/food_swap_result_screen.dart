import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodSwapResultsPage extends StatelessWidget {
  final String predictedFood;
  final Map<String, dynamic> nutritionInfo;
  final List<dynamic> alternatives;
  final File scannedImage;

  const FoodSwapResultsPage({
    super.key,
    required this.predictedFood,
    required this.nutritionInfo,
    required this.alternatives,
    required this.scannedImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Swap Suggestions',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Scanned Meal',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildMealCard(
            title: predictedFood,
            calories: nutritionInfo['Calories'].toString(),
            scannedImage: scannedImage,
          ),
          const SizedBox(height: 24),
          Text(
            'Healthier Swaps',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...alternatives.map((alt) => _buildSwapCard(alt)).toList(),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required String calories,
    required File scannedImage,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1 serving', style: GoogleFonts.poppins(fontSize: 12)),
              const SizedBox(height: 4),
              Text(title,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('$calories calories', style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            scannedImage,
            height: 80,
            width: 180,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildSwapCard(Map<String, dynamic> swap) {
    final nutrition = swap['nutritional_info'] ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Part
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 serving', style: GoogleFonts.poppins(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  swap['name'] ?? 'Alternative Food',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text('${nutrition['Calories'] ?? 'N/A'} calories',
                    style: GoogleFonts.poppins(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  _buildDescription(nutrition),
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              swap['image'],
              height: 80,
              width: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 64,
                width: 64,
                color: Colors.grey[300],
                child: const Icon(Icons.image, color: Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildDescription(Map<String, dynamic> info) {
    final carbs = info['Carbohydrates'] ?? 'N/A';
    final protein = info['Protein'] ?? 'N/A';
    final fat = info['Fats']?['Total'] ?? 'N/A';
    final sugar = info['Sugars'] ?? 'N/A';

    return 'Carbs: $carbs, Protein: $protein, Fat: $fat, Sugar: $sugar';
  }
}
