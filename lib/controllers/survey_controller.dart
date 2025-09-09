// lib/controllers/survey_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../features/screens/combinedResultPage.dart';
import '../survey/model/response_model.dart';
import '../survey/model/survey_model.dart';
import '../utils/popups/full_screen.dart';
import '../utils/constants/animation_strings.dart';
import '../utils/popups/loaders.dart';
import '../controllers/tongue_analysis_controller.dart';

class SurveyController extends GetxController {
  // ----------------- State -----------------
  var questionResponses = <SurveyResponse>[].obs;
  var totalScore = 0.obs;

  // --------------- Helpers -----------------

  /// Convert any map-like object to a Map<String, dynamic> safely.
  Map<String, dynamic> _asStringKeyedMap(Object? v) {
    if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return <String, dynamic>{};
  }

  /// Deterministic int hash from a string (instead of using .hashCode).
  /// Uses first 4 bytes of SHA1 so it’s stable across runs/builds.
  int _stableIdHash(String input) {
    final bytes = sha1.convert(utf8.encode(input)).bytes;
    int v = 0;
    for (int i = 0; i < 4; i++) {
      v = (v << 8) | bytes[i];
    }
    // keep it positive
    return v & 0x7fffffff;
  }

  /// Compute a dedupe key for the report (same approach you had).
  String _computeReportKey(int score, List<SurveyResponse> responses) {
    final norm = responses.asMap().entries.map((e) {
      final r = e.value;
      return {
        'i': e.key,
        'q': r.questionText,
        'a': r.selectedOption,
        'm': r.marks,
        'c': r.optionsCount,
      };
    }).toList();

    final raw = jsonEncode({'score': score, 'responses': norm});
    return sha1.convert(utf8.encode(raw)).toString();
  }

  // --------- Public API ---------

  /// Select an answer and recompute total.
  void selectAnswer(
      int questionIndex,
      int marks,
      SurveyQuestion question,
      String responseKey,
      ) {
    final optionsCount = question.responses.length;

    final response = SurveyResponse(
      marks: marks,
      resultCategory: question.stringResourceId,
      // was: question.resultCategory.hashCode (unstable)
      stringResourceId: _stableIdHash(
        '${question.stringResourceId}|${question.question}|$responseKey',
      ),
      questionText: question.question,
      selectedOption: responseKey,
      optionsCount: optionsCount,
    );

    if (questionResponses.length > questionIndex) {
      questionResponses[questionIndex] = response;
    } else {
      // Fill gaps if needed (in case answers arrive out of order)
      while (questionResponses.length < questionIndex) {
        questionResponses.add(
          SurveyResponse(
            marks: 0,
            resultCategory: question.stringResourceId,
            stringResourceId: _stableIdHash(
                '${question.stringResourceId}|$questionIndex|placeholder'),
            questionText: '',
            selectedOption: '',
            optionsCount: optionsCount,
          ),
        );
      }
      questionResponses.add(response);
    }

    totalScore.value =
        questionResponses.fold<int>(0, (sum, r) => sum + r.marks);
  }

  /// Submit survey -> write to Firestore (Users/{uid}/Reports)
  /// -> navigate to CombinedResultsPage with normalized data.
  Future<void> submitSurvey(BuildContext context) async {
    try {
      // 1) Connectivity
      final isConnected = await InternetConnectionChecker().hasConnection;
      if (!isConnected) {
        throw Exception("No internet connection");
      }

      // 2) Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User is not authenticated");
      final userId = user.uid;

      // 3) Compute report key (for idempotency)
      final reportKey = _computeReportKey(totalScore.value, questionResponses);

      // 4) Try to update the draft created by TongueAnalysisController
      String? targetDocPath;
      try {
        final t = Get.find<TongueAnalysisController>();
        targetDocPath = t.lastDraftDocPath.value;
      } catch (_) {
        targetDocPath = null;
      }

      final reportsRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .collection('Reports');

      // Payload ONLY for survey fields; don't touch tongue fields here
      final surveyPatch = <String, dynamic>{
        'questionScore': totalScore.value,
        'questionResponseJsonArray': questionResponses.map((e) => e.toJson()).toList(),
        'reportKey': reportKey,
        'isDraft': false, // mark complete
        // Keep createdAt as-is if the draft exists; otherwise set it now
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
      };

      DocumentReference<Map<String, dynamic>> reportDocRef;

      if (targetDocPath != null) {
        // Update existing draft
        reportDocRef = FirebaseFirestore.instance.doc(targetDocPath).withConverter(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (map, _) => map,
        );
        await reportDocRef.set(surveyPatch, SetOptions(merge: true));
      } else {
        // Fallback: create a new report (legacy path)
        reportDocRef = reportsRef.doc(reportKey);
        await reportDocRef.set({
          'createdAt': Timestamp.now(),
          ...surveyPatch,
        }, SetOptions(merge: true));
      }

      // 5) Toast
      Loaders.successSnackBar(
        title: 'Success!',
        message: "Survey submitted successfully!",
      );

      // 6) Collect local tongue data for navigation (no Firestore writes here)
      TongueAnalysisController? tongueController;
      try {
        tongueController = Get.find<TongueAnalysisController>();
      } catch (_) {
        tongueController = null;
      }

      final rawTA = tongueController?.tongueAnalysisResults.value;
      final Map<String, dynamic> tongueMap = _asStringKeyedMap(rawTA);
      final File? tongueFile = tongueController?.analyzedImageFile.value;
      final List<SurveyResponse> responses = questionResponses.toList();

      // 7) Navigate
      Get.to(() => CombinedResultsPage(
        sourceDocPath: reportDocRef.path,
        allowMirror: false,
        tongueAnalysisResults: tongueMap,
        tongueImageFile: tongueFile,
        surveyResponses: responses,
        surveyTotalScore: totalScore.value,
      ));
    } catch (e) {
      Loaders.errorSnackBar(
        title: 'Submit failed',
        message: e.toString(),
      );
      if (Get.isLogEnable) {
        // ignore: avoid_print
        print('Failed to submit survey: $e');
      }
    }
  }
}
