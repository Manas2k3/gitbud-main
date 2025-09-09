// lib/controllers/tongue_analysis_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

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

  // ---- helpers ----
  Future<Map<String, dynamic>> _postMultipartWithRetry({
    required String url,
    required File file,
    required String fieldName,
    int maxRetries = 2,
    Duration perTryTimeout = const Duration(seconds: 20),
    void Function(int attempt)? onRetry,
  }) async {
    final uri = Uri.parse(url);
    final mimeType = lookupMimeType(file.path);
    final contentType = mimeType != null ? MediaType.parse(mimeType) : MediaType("image", "jpeg");

    int attempt = 0;
    Object? lastErr;

    while (attempt <= maxRetries) {
      try {
        final request = http.MultipartRequest("POST", uri);
        request.files.add(await http.MultipartFile.fromPath(
          fieldName, file.path,
          contentType: contentType,
          filename: path.basename(file.path),
        ));

        final streamed = await request.send().timeout(perTryTimeout);
        final response = await http.Response.fromStream(streamed).timeout(perTryTimeout);

        if (response.statusCode != 200) {
          throw Exception("HTTP ${response.statusCode}: ${response.reasonPhrase}");
        }

        final body = response.body;
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);

        throw Exception("Unexpected response format");
      } catch (e) {
        lastErr = e;
        if (attempt == maxRetries) break;
        await Future.delayed(Duration(milliseconds: 600 * (attempt + 1))); // backoff
        onRetry?.call(attempt + 1);
        attempt++;
      }
    }
    throw Exception("Request failed after ${maxRetries + 1} attempts. Last error: $lastErr");
  }


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

  String _shortContext(Map<String, dynamic> data) {
    final ex = (data['Explanation'] ?? '').toString();
    if (ex.isNotEmpty && ex.length <= 140) return ex;
    return ex.isNotEmpty ? ex.substring(0, 140) : '';
  }

  Future<void> analyzeImage(File? imageFile) async {
    // ===== Guard: already running? =====
    if (isLoading.value) return;

    // --- Pre-checks ---
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

    // Open loader
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

    // Progress messages
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
      // ===== 1) Color via Cloud Run with timeout + retry =====
      FullScreenLoader.updateText("Uploading image & checking color…");
      final jsonData = await _postMultipartWithRetry(
        url: "https://tongue-api-506773688937.us-central1.run.app/predict",
        file: imageFile,
        fieldName: 'image',
        maxRetries: 2,              // 1 initial + 2 retries = 3 attempts
        perTryTimeout: const Duration(seconds: 20),
        onRetry: (attempt) {
          if (!cancelled && FullScreenLoader.isShowing) {
            FullScreenLoader.updateText("Server is waking up (try #${attempt + 1})…");
          }
        },
      );
      if (cancelled) return;

      Map<String, dynamic> predictions = {};
      try {
        if (jsonData['predictions'] is Map) {
          predictions = _asStringKeyedMap(jsonData['predictions']);
        } else {
          predictions = {
            'Color': _asStringKeyedMap(jsonData['Color Prediction']),
            'Shape': _asStringKeyedMap(jsonData['Shape Prediction']),
            'Texture': _asStringKeyedMap(jsonData['Texture Prediction']),
          };
        }
      } catch (_) {
        // fall back to empty map if the API changes shape unexpectedly
        predictions = {};
      }

      final colorRaw = _asStringKeyedMap(predictions['Color']);
      final colorLabel = (_extractLabel(colorRaw) ?? "healthy").toLowerCase();
      final colorScore = _extractScore(colorRaw) ?? 0.0;

      // ===== 2) Gemini (shape & texture) =====
      FullScreenLoader.updateText("Analyzing shape & texture with AI…");
      final gem = await GeminiService.analyzeShapeTextureFromImage(imageFile);
      if (cancelled) return;

      final gShape = _asStringKeyedMap(gem["shape"]);
      final gTexture = _asStringKeyedMap(gem["texture"]);
      final gShapeAI = _asStringKeyedMap(gem["shape_ai"]);
      final gTextureAI = _asStringKeyedMap(gem["texture_ai"]);
      final combined = _asStringKeyedMap(gem["combined_summary"]);

      final finalShapeLabel = (gShape["Label"] ?? "normal").toString();
      final finalShapeScore = (gShape["Score"] is num) ? (gShape["Score"] as num).toDouble() : 0.0;
      final finalTextureLabel = (gTexture["Label"] ?? "normal").toString();
      final finalTextureScore = (gTexture["Score"] is num) ? (gTexture["Score"] as num).toDouble() : 0.0;

      // ===== 3) Layman report =====
      FullScreenLoader.updateText("Drafting your simplified report…");
      final laymanReport = await GeminiService.buildLaymanReport(
        colorLabel: colorLabel,
        colorScore: colorScore,
        shapeLabel: finalShapeLabel,
        shapeScore: finalShapeScore,
        textureLabel: finalTextureLabel,
        textureScore: finalTextureScore,
      );
      if (cancelled) return;

      // ===== 4) Persist draft =====
      FullScreenLoader.updateText("Saving your results…");
      final ta = {
        "status": jsonData['status'],
        "color": colorRaw,
        "shape": {"Label": finalShapeLabel, "Score": finalShapeScore},
        "texture": {"Label": finalTextureLabel, "Score": finalTextureScore},
        "shape_ai": gShapeAI,
        "texture_ai": gTextureAI,
        "combined_summary": combined,
        "layman_report": laymanReport,
      };

      tongueAnalysisResults.value = _asStringKeyedMap(ta);
      analyzedImageFile.value = imageFile;

      await _persistTongueDraft(tongueAnalysisResults.value, hasImage: true);
      if (cancelled) return;

      // ===== 5) Close loader BEFORE navigating =====
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
      // Make sure we *always* close loader on error
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

        // Survey not done yet:
        'questionScore': 0,
        'questionResponseJsonArray': const <Map<String, dynamic>>[],

        // Tongue snapshot:
        'tongueAnalysisResults': _asStringKeyedMap(ta),
        'hasTongueImage': hasImage,

        // Helpful flag to distinguish drafts (optional)
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
}
