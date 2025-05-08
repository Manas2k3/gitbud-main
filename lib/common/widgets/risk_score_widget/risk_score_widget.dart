import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RiskScoreWidget extends StatelessWidget {
  final int score;
  final String riskLevel;
  final String riskExplanation;

  RiskScoreWidget({
    required this.score,
    required this.riskLevel,
    required this.riskExplanation,
  });

  @override
  Widget build(BuildContext context) {
    Color riskColor;

    // Set color based on score ranges
    if (score == 1) {
      riskColor = Colors.green;
    } else if (score == 2) {
      riskColor = Colors.amber;
    } else if (score == 3) {
      riskColor = Colors.orange;
    } else {
      riskColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Text(
            "Lung Health Risk Score",
            style: GoogleFonts.poppins(
                color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(
            width: 250, // Adjust the width as needed
            height: 250, // Adjust the height as needed
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 4,
                  // Set maximum score to 4
                  interval: 1,
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 0, endValue: 1, color: Colors.green),
                    GaugeRange(startValue: 1, endValue: 2, color: Colors.amber),
                    GaugeRange(
                        startValue: 2, endValue: 3, color: Colors.orange),
                    GaugeRange(startValue: 3, endValue: 4, color: Colors.red),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(value: score.toDouble()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Score Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreColumn(
                  Icons.speed, 'SCORE', score.toString(), riskColor),
              _buildRiskColumn(
                  Icons.warning, riskLevel, riskExplanation, riskColor),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build the score column
  Column _buildScoreColumn(
      IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: Icon(icon, size: 50, color: color),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build the risk column
  Column _buildRiskColumn(
      IconData icon, String riskLevel, String explanation, Color riskColor) {
    return Column(
      children: [
        Icon(icon, size: 50, color: riskColor),
        const SizedBox(height: 8),
        Text(
          'RISK',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Text(
          riskLevel,
          style: GoogleFonts.poppins(
            fontSize: 20,
            color: riskColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          explanation,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
