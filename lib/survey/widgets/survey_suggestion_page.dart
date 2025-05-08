import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionPage extends StatelessWidget {
  final String suggestion;
  final Color boxColor;

  const SuggestionPage({
    Key? key,
    required this.suggestion,
    required this.boxColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suggestion'),
        backgroundColor: boxColor, // Match the color to risk level
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          suggestion,
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      ),
    );
  }
}
