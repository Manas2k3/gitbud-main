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
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Captured Image',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.image,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.4,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _isResultShown ? 'View Result Again' : 'Submit for Analysis',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_severityText != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _severityColor!.withOpacity(0.1),
                    border: Border.all(color: _severityColor!, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        _severityText!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _severityColor!,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // TODO: Add your consultation logic here
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap here for consultation',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

}
