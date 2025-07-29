import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RiskScoreWidget extends StatelessWidget {
  final int score;

  RiskScoreWidget({required this.score, required String riskLevel, required String riskExplanation});

  @override
  Widget build(BuildContext context) {
    // Clamp score to valid range
    final clampedScore = score.clamp(0, 4);

    Color riskColor;
    String riskLevel;
    String riskExplanation;

    if (clampedScore == 1) {
      riskColor = Colors.green;
      riskLevel = 'Low';
      riskExplanation = 'You have a low risk. Keep up the healthy habits!';
    } else if (clampedScore == 2) {
      riskColor = Colors.amber;
      riskLevel = 'Moderate';
      riskExplanation = 'Your risk is moderate. Consider mild lifestyle changes.';
    } else if (clampedScore == 3) {
      riskColor = Colors.orange;
      riskLevel = 'High';
      riskExplanation = 'High risk detected. A doctor consultation is advised.';
    } else {
      riskColor = Colors.red;
      riskLevel = 'Very High';
      riskExplanation = 'Very high risk. Seek immediate medical attention.';
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
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: 250,
            height: 250,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 4,
                  interval: 1,
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 0, endValue: 1, color: Colors.green),
                    GaugeRange(startValue: 1, endValue: 2, color: Colors.amber),
                    GaugeRange(startValue: 2, endValue: 3, color: Colors.orange),
                    GaugeRange(startValue: 3, endValue: 4, color: Colors.red),
                  ],
                  pointers: <GaugePointer>[
                    NeedlePointer(value: clampedScore.toDouble()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreColumn(Icons.speed, 'SCORE', clampedScore.toString(), riskColor),
              _buildRiskColumn(Icons.warning, riskLevel, riskExplanation, riskColor),
            ],
          ),
        ],
      ),
    );
  }

  Column _buildScoreColumn(IconData icon, String title, String value, Color color) {
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

  Column _buildRiskColumn(IconData icon, String riskLevel, String explanation, Color riskColor) {
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
      ],
    );
  }
}
