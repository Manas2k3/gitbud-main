import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CapturedImagePage extends StatefulWidget {
  final File image;

  const CapturedImagePage({super.key, required this.image});

  @override
  State<CapturedImagePage> createState() => _CapturedImagePageState();
}

class _CapturedImagePageState extends State<CapturedImagePage> {
  bool _isLoading = false;
  bool _isResultShown = false;
  String? _severityText;
  Color? _severityColor;

  final List<Map<String, dynamic>> _severities = [
    {
      'text': 'High severity \nBacterial Infection Diarrhea Positive',
      'color': Colors.red
    },
    {
      'text': 'Moderate severity \nNon Bacterial Infection Diarrhea Positive',
      'color': Colors.orange
    },
    {'text': 'No severity', 'color': Colors.green},
  ];

  void _submitImage() {
    setState(() {
      _isLoading = true;
      _isResultShown = false;
      _severityText = null;
    });

    // Simulate image submission delay
    Timer(const Duration(seconds: 2), () {
      final random = Random().nextInt(_severities.length);
      final selectedSeverity = _severities[random];

      setState(() {
        _isLoading = false;
        _isResultShown = true;
        _severityText = selectedSeverity['text'];
        _severityColor = selectedSeverity['color'];
      },);
    },);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Captured Image',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      backgroundColor: Colors.purple.shade50,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Image.file(
              widget.image,
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.5,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      _isResultShown ? 'Result' : 'Submit',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            if (_severityText != null)
              Text(
                _severityText!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _severityColor,
                ),
              ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Container(
            //     decoration: BoxDecoration(
            //         color: Colors.white60,
            //         borderRadius: BorderRadius.circular(15)),
            //     height: 50,
            //     width: double.infinity,
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //       children: [
            //         Text(
            //           'Tap here for consultation',
            //           style: GoogleFonts.poppins(
            //               color: Colors.grey.shade700, fontSize: 16),
            //         ),
            //         IconButton(
            //           onPressed: () {},
            //           icon: Icon(Icons.arrow_forward),
            //         )
            //       ],
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}
