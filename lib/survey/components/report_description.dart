import 'package:flutter/material.dart';

class ReportDescription extends StatelessWidget {
  final int score;

  const ReportDescription({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String description;
    if (score >= 1 && score <= 20) {
      description = 'Low gut health severity'; // Replace with actual string from localization
    } else if (score >= 21 && score <= 35) {
      description = 'Moderate gut health severity'; // Replace with actual string from localization
    } else {
      description = 'High gut health severity'; // Replace with actual string from localization
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        description,
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
