// lib/controllers/tongue_analysis_controller.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/constants/animation_strings.dart';
import '../utils/popups/full_screen.dart';
import '../survey/survey_screen.dart';
import '../../services/gemini_service.dart';

class TongueAnalysisController extends GetxController {
  var isLoading = false.obs;

  /// Final object used by UI + stored in Firestore under 'tongueAnalysisResults'
  var tongueAnalysisResults = <String, dynamic>{}.obs;
  var analyzedImageFile = Rx<File?>(null);

  /// Path to the draft report doc created after analysis (so survey can update it)
  final lastDraftDocPath = RxnString();

  /// Optional callback to re-open the image picker in the page (set by page)
  VoidCallback? pickImageCallback;
  void registerPickImageCallback(VoidCallback cb) => pickImageCallback = cb;

  Map<String, dynamic> _asStringKeyedMap(Object? v) {
    if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return <String, dynamic>{};
  }

  String? _extractLabel(Map<String, dynamic> data) {
    final r = data['Result'];
    if (r is Map && r['label'] != null) return r['label'].toString();
    final l = data['Label'] ?? data['label'];
    return l?.toString();
  }

  double? _extractScore(Map<String, dynamic> data) {
    final r = data['Result'];
    if (r is Map) {
      final conf = r['confidence_percent'];
      if (conf is num) return conf.toDouble();
      if (conf is String) return double.tryParse(conf);
    }
    final s = data['Score'] ?? data['score'];
    if (s is num) return s.toDouble();
    if (s is String) return double.tryParse(s);
    return null;
  }

  /// NEW helper: Verify image is a tongue using GeminiService (with retries/timeouts).
  /// Returns map { 'isTongue': bool, 'confidence': double, 'raw': Map<String,dynamic> }
  Future<Map<String, dynamic>> _verifyTongueImageWithRetry(File file, {int maxRetries = 2}) async {
    int attempt = 0;
    Object? lastErr;
    while (attempt <= maxRetries) {
      try {
        final res = await GeminiService.verifyIsTongue(file).timeout(const Duration(seconds: 12));
        if (res is Map<String, dynamic>) {
          final isTongue = res['isTongue'] == true;
          final conf = (res['confidence'] is num) ? (res['confidence'] as num).toDouble() : (double.tryParse(res['confidence']?.toString() ?? '') ?? 0.0);
          return {'isTongue': isTongue, 'confidence': conf, 'raw': res};
        }
        throw Exception('Unexpected verify response shape');
      } catch (e) {
        lastErr = e;
        if (attempt == maxRetries) break;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        attempt++;
      }
    }
    throw Exception('verifyIsTongue failed after ${maxRetries + 1} attempts. Last: $lastErr');
  }

  Future<void> analyzeImage(File? imageFile) async {
    if (isLoading.value) return;

    if (imageFile == null) {
      Get.snackbar("Image Required", "Please upload an image first.",
          backgroundColor: Colors.orange.shade100, colorText: Colors.black);
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      Get.snackbar("No Internet", "Please check your connection",
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
      return;
    }

    bool cancelled = false;
    final List<Timer> hintTimers = [];
    isLoading.value = true;

    if (!FullScreenLoader.isShowing) {
      FullScreenLoader.openLoadingDialog(
        "Analysing tongue image…",
        AnimationStrings.loadingAnimation,
        onCancel: () {
          cancelled = true;
          isLoading.value = false;
          if (FullScreenLoader.isShowing) FullScreenLoader.stopLoading();
          for (final t in hintTimers) t.cancel();
          Get.snackbar("Cancelled", "Scan was cancelled by user.",
              backgroundColor: Colors.grey.shade200, colorText: Colors.black);
        },
      );
    }

    hintTimers.add(Timer(const Duration(seconds: 6), () {
      if (!cancelled && FullScreenLoader.isShowing) {
        FullScreenLoader.updateText("Hang in there… crunching the image.");
      }
    }));
    hintTimers.add(Timer(const Duration(seconds: 12), () {
      if (!cancelled && FullScreenLoader.isShowing) {
        FullScreenLoader.updateText("Almost there… preparing your mini report.");
      }
    }));
    hintTimers.add(Timer(const Duration(seconds: 18), () {
      if (!cancelled && FullScreenLoader.isShowing) {
        FullScreenLoader.updateText("Saving your results…");
      }
    }));

    try {
      // VERIFY
      FullScreenLoader.updateText("Validating image is a tongue...");
      Map<String, dynamic> verifyResult;
      try {
        verifyResult = await _verifyTongueImageWithRetry(imageFile);
      } catch (e) {
        if (FullScreenLoader.isShowing) FullScreenLoader.stopLoading();
        isLoading.value = false;
        for (final t in hintTimers) t.cancel();

        await _showVerificationFailedPopup(
          reason: "We couldn't verify the photo. Please try again with a clear tongue image.",
          details: {'error': e.toString()},
        );
        return;
      }

      if (cancelled) return;

      final bool isTongue = verifyResult['isTongue'] == true;
      final double confidence = (verifyResult['confidence'] is num) ? (verifyResult['confidence'] as num).toDouble() : 0.0;
      const double threshold = 0.60;

      if (!isTongue || confidence < threshold) {
        if (FullScreenLoader.isShowing) FullScreenLoader.stopLoading();
        isLoading.value = false;
        for (final t in hintTimers) t.cancel();

        await _showVerificationFailedPopup(
          reason:
          "The photo doesn't look like a clear tongue image (confidence ${ (confidence * 100).toStringAsFixed(0) }%). Please retry with a clear, well-lit photo showing the full tongue.",
          details: verifyResult['raw'] ?? {},
        );
        return;
      }

      // ANALYZE: color + shape/texture via GeminiService
      FullScreenLoader.updateText("Analyzing image for (color, shape, texture)...");
      final colorRes = await GeminiService.analyzeColorFromImage(imageFile);
      if (cancelled) return;

      final gem = await GeminiService.analyzeShapeTextureFromImage(imageFile);
      if (cancelled) return;

      final Map<String, dynamic> colorRaw = {
        "Label": (colorRes['label'] ?? 'unknown'),
        "Score": (colorRes['score'] is num) ? (colorRes['score'] as num).toDouble() : 0.0,
        "raw": colorRes['raw'] ?? {}
      };

      final gShape = _asStringKeyedMap(gem["shape"]);
      final gTexture = _asStringKeyedMap(gem["texture"]);
      final gShapeAI = _asStringKeyedMap(gem["shape_ai"]);
      final gTextureAI = _asStringKeyedMap(gem["texture_ai"]);
      final combined = _asStringKeyedMap(gem["combined_summary"]);

      final finalShapeLabel = (gShape["Label"] ?? "normal").toString();
      final finalShapeScore = (gShape["Score"] is num) ? (gShape["Score"] as num).toDouble() : 0.0;
      final finalTextureLabel = (gTexture["Label"] ?? "normal").toString();
      final finalTextureScore = (gTexture["Score"] is num) ? (gTexture["Score"] as num).toDouble() : 0.0;

      // LAYMAN REPORT
      FullScreenLoader.updateText("Drafting your simplified report…");
      final laymanReport = await GeminiService.buildLaymanReport(
        colorLabel: (colorRaw['Label'] ?? 'unknown').toString(),
        colorScore: (colorRaw['Score'] is num) ? (colorRaw['Score'] as num).toDouble() : 0.0,
        shapeLabel: finalShapeLabel,
        shapeScore: finalShapeScore,
        textureLabel: finalTextureLabel,
        textureScore: finalTextureScore,
      );
      if (cancelled) return;

      // PERSIST
      FullScreenLoader.updateText("Saving your results…");
      final ta = {
        "status": "ok",
        "color": colorRaw,
        "shape": {"Label": finalShapeLabel, "Score": finalShapeScore},
        "texture": {"Label": finalTextureLabel, "Score": finalTextureScore},
        "shape_ai": gShapeAI,
        "texture_ai": gTextureAI,
        "combined_summary": combined,
        "layman_report": laymanReport,
        "verification": verifyResult,
      };

      tongueAnalysisResults.value = _asStringKeyedMap(ta);
      analyzedImageFile.value = imageFile;

      await _persistTongueDraft(tongueAnalysisResults.value, hasImage: true);
      if (cancelled) return;

      if (FullScreenLoader.isShowing) FullScreenLoader.stopLoading();
      isLoading.value = false;
      for (final t in hintTimers) t.cancel();

      Get.snackbar(
        "Analysis Complete!",
        "Now please complete the survey.",
        backgroundColor: Colors.green.shade100,
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );

      Get.to(() => SurveyScreen());
    } catch (e) {
      if (FullScreenLoader.isShowing) FullScreenLoader.stopLoading();
      isLoading.value = false;
      for (final t in hintTimers) t.cancel();

      Get.snackbar("Error", "Something went wrong: $e",
          backgroundColor: Colors.red.shade100, colorText: Colors.black);
    }
  }

  Future<void> _persistTongueDraft(Map<String, dynamic> ta, {required bool hasImage}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final reportsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .collection('Reports');

      final payload = {
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'questionScore': 0,
        'questionResponseJsonArray': const <Map<String, dynamic>>[],
        'tongueAnalysisResults': _asStringKeyedMap(ta),
        'hasTongueImage': hasImage,
        'isDraft': true,
      };

      final docRef = await reportsRef.add(payload);
      lastDraftDocPath.value = docRef.path;
    } catch (e) {
      // ignore: avoid_print
      print('Failed to persist tongue draft: $e');
    }
  }

  void clearResults() {
    tongueAnalysisResults.clear();
    analyzedImageFile.value = null;
    lastDraftDocPath.value = null;
  }

  // ---------------------------------------------------------------------------
  // UI: Verification failed popup (themed) with readable debug & Retry auto-open
  // ---------------------------------------------------------------------------

  String _prettyDetailsString(Map<String, dynamic> details, {int indent = 0}) {
    final buffer = StringBuffer();
    void writeEntry(String key, dynamic val, int level) {
      final pref = ' ' * (level * 2);
      if (val is Map) {
        buffer.writeln('$pref$key:');
        val.forEach((k, v) => writeEntry(k.toString(), v, level + 1));
      } else if (val is List) {
        buffer.writeln('$pref$key: [');
        for (final e in val) {
          if (e is Map || e is List) {
            writeEntry('-', e, level + 1);
          } else {
            buffer.writeln('${' ' * ((level + 1) * 2)}- $e');
          }
        }
        buffer.writeln('$pref]');
      } else {
        buffer.writeln('$pref$key: ${val ?? ""}');
      }
    }

    details.forEach((k, v) => writeEntry(k.toString(), v, indent));
    return buffer.toString();
  }

  Future<void> _showVerificationFailedPopup({
    required String reason,
    Map<String, dynamic>? details,
  }) async {
    final tips = [
      "Use bright, even daylight. Avoid colored/LED lights.",
      "Show the whole tongue tip → root; avoid lips covering edges.",
      "Hold camera steady and focus; avoid blur.",
      "Open mouth wide, stick tongue out slightly so surface is visible.",
    ];

    final debugText = (details != null && details.isNotEmpty)
        ? "Debug:\n" + _prettyDetailsString(details, indent: 0)
        : null;

    await Get.dialog(
      WillPopScope(
        onWillPop: () async => true,
        child: AlertDialog(
          backgroundColor: Colors.redAccent.shade200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Photo not suitable",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 440),
            child: SingleChildScrollView(
              child: Builder(builder: (context) {
                // Normalize incoming 'details' shape so we can read it.
                Map<String, dynamic> norm = {};
                if (details != null && details is Map<String, dynamic>) {
                  // 'details' might already be the 'detail' object or include 'normalized'
                  norm = Map<String, dynamic>.from(details);
                  // If caller wrapped data under 'detail' key, dig it out:
                  if (norm['detail'] is Map) {
                    norm = Map<String, dynamic>.from(norm['detail'] as Map);
                  }
                  // If 'normalized' is nested, prefer that
                  if (norm['normalized'] is Map) {
                    norm = Map<String, dynamic>.from(norm['normalized'] as Map);
                  } else if (norm['raw_parsed'] is Map && norm['raw_parsed']['normalized'] is Map) {
                    norm = Map<String, dynamic>.from(norm['raw_parsed']['normalized'] as Map);
                  }
                }

                // Helpers to read bools safely
                bool _readBool(dynamic v) {
                  if (v == null) return false;
                  if (v is bool) return v;
                  final s = v.toString().toLowerCase().trim();
                  return s == 'true' || s == 'yes' || s == '1';
                }

                // Pull friendly flags
                final bool facePresent = _readBool(norm['facePresent'] ?? norm['face_present'] ?? norm['faceDetected'] ?? norm['face_detected']);
                final bool tongueVisible = _readBool(norm['tongueVisible'] ?? norm['tongue_visible'] ?? norm['tongue_in_frame']);
                final bool mouthOpen = _readBool(norm['mouthOpen'] ?? norm['mouth_open'] ?? norm['mouth_opened']);
                double confidence = 0.0;
                try {
                  final cRaw = norm['confidence_0_1'] ?? norm['confidence'] ?? norm['confidence_score'] ?? norm['confidence_percent'];
                  if (cRaw is num) {
                    confidence = (cRaw as num).toDouble();
                    if (confidence > 1.0) confidence = (confidence / 100.0).clamp(0.0, 1.0);
                  } else if (cRaw is String) {
                    final parsed = double.tryParse(cRaw) ?? 0.0;
                    confidence = parsed > 1.0 ? (parsed / 100.0).clamp(0.0, 1.0) : parsed;
                  }
                } catch (_) {
                  confidence = 0.0;
                }

                // Human-friendly reasons (try multiple keys)
                String modelReason = '';
                if (details is Map) {
                  modelReason = (details?['reason'] ?? details?['explanation'] ?? details?['detail']?['reason'] ?? '').toString();
                }

                // Short, user-focused summary lines
                final List<String> friendlyLines = [];
                if (modelReason.isNotEmpty) {
                  friendlyLines.add(modelReason);
                }
                // Prefer to surface the most important flags
                friendlyLines.add("Face in photo: ${facePresent ? "Yes — please remove your face for privacy & accuracy" : "No — good"}");
                friendlyLines.add("Tongue visible: ${tongueVisible ? "Yes — good" : "No — please stick your tongue out fully"}");
                friendlyLines.add("Mouth open / tongue out: ${mouthOpen ? "Yes" : "No — open your mouth and stick the tongue out"}");
                friendlyLines.add("Image clarity: ${(confidence * 100).toStringAsFixed(0)}% confidence");

                // Generate compact 'technical lines' but as plain English, not JSON
                final List<String> technicalLines = [];
                technicalLines.add("Model verdict: ${_readBool(details?['isTongue'] ?? norm['isTongue']) ? "Looks like a tongue" : "Not identified as tongue"}");
                technicalLines.add("Face detected (model): ${facePresent ? "Yes" : "No"}");
                technicalLines.add("Tongue visible (model): ${tongueVisible ? "Yes" : "No"}");
                technicalLines.add("Mouth open (model): ${mouthOpen ? "Yes" : "No"}");
                technicalLines.add("Model confidence: ${(confidence * 100).toStringAsFixed(0)}%");
                if (details is Map && details!.isNotEmpty) {
                  technicalLines.add("Note: more technical info is available in logs for support.");
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Plain user-facing reason
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        reason,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tips header + list (user-friendly)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Tips for a better photo",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tips.map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: Colors.white)),
                          Expanded(child: Text(t, style: const TextStyle(color: Colors.white))),
                        ],
                      ),
                    )),

                    const SizedBox(height: 12),

                    // "What we noticed" — short, plain bullets
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "What we noticed",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: friendlyLines
                            .map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "• $line",
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.25),
                          ),
                        ))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Technical details (plain-language lines, not raw JSON)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Technical details (plain)",
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: technicalLines
                            .map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: SelectableText(
                            l,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.25),
                          ),
                        ))
                            .toList(),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: [
            TextButton(
              onPressed: () {
                Get.back(); // dismiss dialog
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.redAccent.shade200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Get.back(); // close dialog
                // Auto-open the pick sheet if page registered a callback
                try {
                  if (pickImageCallback != null) {
                    pickImageCallback!();
                  } else {
                    Get.snackbar(
                      "Try again",
                      "Please retake or choose a clearer tongue photo using the Upload Image button.",
                      backgroundColor: Colors.white,
                      colorText: Colors.redAccent.shade200,
                      duration: const Duration(seconds: 4),
                    );
                  }
                } catch (_) {
                  // fallback snackbar
                  Get.snackbar(
                    "Try again",
                    "Please retake or choose a clearer tongue photo using the Upload Image button.",
                    backgroundColor: Colors.white,
                    colorText: Colors.redAccent.shade200,
                    duration: const Duration(seconds: 4),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
                child: Text("Retry"),
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: true,
    );

  }
}
