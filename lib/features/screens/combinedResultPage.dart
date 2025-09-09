// lib/features/results/combined_results_page.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../navigation_menu.dart';
import '../../../survey/model/response_model.dart';
import '../../services/gemini_service.dart';

/// Survey suggestions + shape/texture insights
class CombinedResultsPage extends StatefulWidget {
  final Map<String, dynamic> tongueAnalysisResults;
  final File? tongueImageFile;
  final List<SurveyResponse> surveyResponses;
  final int surveyTotalScore;
  final Map<int, List<Map<String, String>>>? preloadedSuggestions;
  final String? sourceDocPath;
  final bool allowMirror;

  const CombinedResultsPage({
    Key? key,
    required this.tongueAnalysisResults,
    this.tongueImageFile,
    required this.surveyResponses,
    required this.surveyTotalScore,
    this.preloadedSuggestions,
    this.sourceDocPath,
    this.allowMirror = true,
  }) : super(key: key);

  @override
  State<CombinedResultsPage> createState() => _CombinedResultsPageState();
}

class _CombinedResultsPageState extends State<CombinedResultsPage>
    with AutomaticKeepAliveClientMixin {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userDocFuture;
  final Map<int, Future<List<Map<String, String>>>> _suggestionsFutures = {};
  final Map<int, bool> _expandedSuggestions = {};

  String? _userGender;
  String? _usersReportDocId;
  bool _usersReportWritten = false;

  final PageController _pageController = PageController();
  int currentPage = 0;

  /// Gemini futures for shape/texture — **AI ONLY**, no model text.
  Future<Map<String, dynamic>>? _shapeInsightsFuture;
  Future<Map<String, dynamic>>? _textureInsightsFuture;

  @override
  bool get wantKeepAlive => true;

  // -------- SAFE NORMALIZATION HELPERS --------
  Map<String, dynamic> asStringKeyedMap(Object? v) {
    if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return <String, dynamic>{};
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _userDocFuture =
        FirebaseFirestore.instance.collection('Users').doc(uid).get();
    _prefetchUserGender();
    _mirrorReportToUsers();

    // Model outputs (only used to seed label/score; NEVER show their text)
    final shapeMap = asStringKeyedMap(widget.tongueAnalysisResults['shape']);
    final textureMap = asStringKeyedMap(widget.tongueAnalysisResults['texture']);

    // If controller already injected AI copies, prefer them
    final preShapeAI =
    asStringKeyedMap(widget.tongueAnalysisResults['shape_ai']);
    final preTextureAI =
    asStringKeyedMap(widget.tongueAnalysisResults['texture_ai']);

    if (preShapeAI.isNotEmpty &&
        (preShapeAI['explanation'] ?? '').toString().trim().isNotEmpty) {
      _shapeInsightsFuture = Future.value(preShapeAI);
    } else {
      final shapeLabel = _extractLabel(shapeMap) ?? "shape_pattern";
      final shapeScore = _extractConfidence(shapeMap);
      // IMPORTANT: do NOT pass model Explanation/context to Gemini
      _shapeInsightsFuture = GeminiService.shapeTextureInsights(
        type: "shape",
        label: shapeLabel,
        score: shapeScore,
        extraContext: null,
      );
    }

    if (preTextureAI.isNotEmpty &&
        (preTextureAI['explanation'] ?? '').toString().trim().isNotEmpty) {
      _textureInsightsFuture = Future.value(preTextureAI);
    } else {
      final textureLabel = _extractLabel(textureMap) ?? "texture_pattern";
      final textureScore = _extractConfidence(textureMap);
      // IMPORTANT: do NOT pass model Explanation/context to Gemini
      _textureInsightsFuture = GeminiService.shapeTextureInsights(
        type: "texture",
        label: textureLabel,
        score: textureScore,
        extraContext: null, // <-- prevents model phrasing leak-through
      );
    }
  }

  Future<void> _prefetchUserGender() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snap =
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (snap.exists) {
        setState(() => _userGender = (snap.data()?['gender'] ?? '').toString());
      }
    } catch (_) {}
  }

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

  Future<void> _mirrorReportToUsers() async {
    if (_usersReportWritten || widget.allowMirror != true || widget.sourceDocPath != null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String reportKey =
    _computeReportKey(widget.surveyTotalScore, widget.surveyResponses);

    final userReports = FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .collection('Reports');

    final existing =
    await userReports.where('reportKey', isEqualTo: reportKey).limit(1).get();
    if (existing.docs.isNotEmpty) {
      _usersReportDocId = existing.docs.first.reference.id;
      _usersReportWritten = true;
      return;
    }

    final aiSuggestions =
    (widget.preloadedSuggestions ?? {}).map((k, v) => MapEntry(k.toString(), v));

    final payload = {
      'createdAt': Timestamp.now(),
      'userId': user.uid,
      'questionScore': widget.surveyTotalScore,
      'questionResponseJsonArray':
      widget.surveyResponses.map((e) => e.toJson()).toList(),
      'aiSuggestions': aiSuggestions,
      'tongueAnalysisResults': widget.tongueAnalysisResults,
      'hasTongueImage': widget.tongueImageFile != null,
      'reportKey': reportKey,
    };

    final docRef = await userReports.add(payload);
    _usersReportDocId = docRef.id;
    _usersReportWritten = true;
  }

  // ---------- helpers ----------
  String? _extractLabel(Map<String, dynamic> data) {
    final r = data['Result'];
    if (r is Map) {
      final lbl = (r as Map)['label'];
      if (lbl != null) return lbl.toString();
    }
    final lbl = data['Label'] ?? data['label'];
    return lbl?.toString();
  }

  double? _extractConfidence(Map<String, dynamic> data) {
    final r = data['Result'];
    if (r is Map) {
      final conf = (r as Map)['confidence_percent'];
      if (conf is num) return conf.toDouble();
      if (conf is String) return double.tryParse(conf);
    }
    final s = data['Score'] ?? data['score'];
    if (s is num) return s.toDouble();
    if (s is String) return double.tryParse(s);
    return null;
  }

  String _titleize(String s) {
    final clean = s.replaceAll("_", " ").trim();
    return clean.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return "";
      final lower = w.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(" ");
  }

  // Converts *emphasis* → bold and strips underscores
  Widget _boldifyText(
      String text, {
        TextStyle? baseStyle,
        TextStyle? boldStyle,
        TextAlign align = TextAlign.left,
      }) {
    final cleaned = text.replaceAll("_", " ");
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*(.*?)\*');
    int start = 0;
    for (final m in regex.allMatches(cleaned)) {
      if (m.start > start) {
        spans.add(TextSpan(text: cleaned.substring(start, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1) ?? "",
        style: boldStyle ?? const TextStyle(fontWeight: FontWeight.w700),
      ));
      start = m.end;
    }
    if (start < cleaned.length) {
      spans.add(TextSpan(text: cleaned.substring(start)));
    }
    return Text.rich(
      TextSpan(
        children: spans,
        style: baseStyle ??
            GoogleFonts.poppins(fontSize: 14.5, color: Colors.black87),
      ),
      textAlign: align,
    );
  }

  // Local (on-device) color advice (used as fallback if no layman_report)
  Map<String, dynamic> _colorAdvice(Map<String, dynamic> colorRaw) {
    final label = (_extractLabel(colorRaw) ?? 'healthy').toLowerCase();
    final confidence = _extractConfidence(colorRaw) ?? 0.0;

    final Map<String, Map<String, dynamic>> advice = {
      'healthy': {
        'explanation':
        "Tongue color looks *healthy* overall. Keep your routine steady—hydration, balanced meals, and regular sleep.",
        'suggestions': [
          {
            'item': 'Stay Consistent',
            'details': 'Maintain regular water intake and balanced meals.',
            'how_it_helps': 'Consistency supports stable oral and gut environment.',
          }
        ],
        'disclaimer': "General wellness guidance; this isn’t a medical diagnosis.",
      },
      'white': {
        'explanation':
        "A *whitish* tongue coat can appear after sleep or with mild dehydration.",
        'suggestions': [
          {
            'item': 'Hydrate Regularly',
            'details': 'Sip water through the day; prefer plain/unsweetened fluids.',
            'how_it_helps': 'Hydration can reduce temporary coating.',
          },
          {
            'item': 'Rinse After Meals',
            'details': 'Swish water after eating; brush tongue gently.',
            'how_it_helps': 'Helps clear food residue that looks like coat.',
          },
        ],
        'disclaimer':
        "Lifestyle tips only; see a professional if persistent or symptomatic.",
      },
      'deep_red': {
        'explanation':
        "A *deep red* appearance can follow spicy foods or minor irritation.",
        'suggestions': [
          {
            'item': 'Cool It A Bit',
            'details': 'Balance spice with curd, cucumber, or buttermilk.',
            'how_it_helps': 'May reduce heat sensation/redness.',
          },
          {
            'item': 'Gentle Oral Care',
            'details': 'Use a soft brush; avoid harsh mouthwashes.',
            'how_it_helps': 'Prevents further irritation.',
          },
        ],
        'disclaimer': "General advice only; persistent discomfort warrants a check-up.",
      },
      'purple': {
        'explanation':
        "A *purplish* hue can show up in cooler weather or after certain foods.",
        'suggestions': [
          {
            'item': 'Warm Beverages',
            'details': 'Try warm water or mild herbal teas.',
            'how_it_helps': 'Gentle warmth can improve comfort.',
          },
          {
            'item': 'Light Movement',
            'details': 'Short walks after meals.',
            'how_it_helps': 'Aids circulation and digestion.',
          },
        ],
        'disclaimer': "Wellness-oriented guidance; not diagnostic.",
      },
    };

    final picked = advice[label] ?? advice['healthy']!;
    return {
      'label': label,
      'confidence': confidence,
      'explanation': picked['explanation'],
      'suggestions': picked['suggestions'],
      'disclaimer': picked['disclaimer'],
    };
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAll(NavigationMenu());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Get.offAll(NavigationMenu()),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text(
            "Gut Health Analysis Results",
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Page Indicator + Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 2,
                    effect: WormEffect(
                      dotColor: Colors.grey.shade300,
                      activeDotColor: Colors.redAccent,
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentPage == 0
                        ? "Tongue Analysis Results"
                        : "Survey Results",
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => currentPage = index),
                children: [
                  _buildTongueSummaryPage(), // clinical layman report
                  _buildSurveyResultsPage(),
                ],
              ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentPage > 0)
                    ElevatedButton.icon(
                      onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text("Previous",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600),
                    )
                  else
                    const SizedBox.shrink(),
                  if (currentPage < 1)
                    ElevatedButton.icon(
                      onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      label:
                      const Text("Next", style: TextStyle(color: Colors.white)),
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => Get.offAll(NavigationMenu()),
                      icon: const Icon(Icons.home, color: Colors.white),
                      label:
                      const Text("Done", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------ Tongue Summary (clinical layman report) ------------------
  Widget _buildTongueSummaryPage() {
    if (widget.tongueAnalysisResults.isEmpty) {
      return const Center(
        child: Text("No tongue analysis data available",
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }

    final ta = asStringKeyedMap(widget.tongueAnalysisResults);
    final layman = asStringKeyedMap(ta['layman_report']);

    // If we have the new Gemini layman report, render it; else fallback to prior AI-only blocks
    if (layman.isNotEmpty) {
      final color = asStringKeyedMap(layman['color']);
      final shape = asStringKeyedMap(layman['shape']);
      final texture = asStringKeyedMap(layman['texture']);
      final interpretation = asStringKeyedMap(layman['interpretation']);
      final recommendations = asStringKeyedMap(layman['recommendations']);
      final risk = asStringKeyedMap(layman['risk']);

      final summary = (layman['summary'] ?? "").toString();

      final tips = ((layman['tips'] as List?) ?? const [])
          .map((e) => (e as Map).map((k, v) => MapEntry(k.toString(), v.toString())))
          .toList();

      final diet = asStringKeyedMap(layman['diet']);
      final dietDo =
      ((diet['do'] as List?) ?? const []).map((e) => e.toString()).toList();
      final dietLimit =
      ((diet['limit'] as List?) ?? const []).map((e) => e.toString()).toList();

      String disclaimer = (layman['disclaimer'] ?? '').toString().trim();
      if (disclaimer.isEmpty) {
        // small fallback: reuse your AI disclaimers if present
        final shapeAI = asStringKeyedMap(ta['shape_ai']);
        final textureAI = asStringKeyedMap(ta['texture_ai']);
        disclaimer =
            (shapeAI['disclaimer'] ?? textureAI['disclaimer'] ?? '').toString();
      }

      String chipText(String label, int conf) {
        final l = label.replaceAll("_", " ").trim();
        final nice = l.isEmpty ? "Normal" : (l[0].toUpperCase() + l.substring(1));
        return "$nice • ${conf.clamp(0, 100)}%";
      }

      Widget chip(String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.withOpacity(0.4), width: 1),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: c)),
      );

      // helpers to render lists from interpretation/recommendations/risk
      List<String> _asStrList(dynamic v) =>
          ((v as List?) ?? const []).map((e) => e.toString()).toList();

      final gutLinks = _asStrList(interpretation['gut_links']);
      final possibleContributors = _asStrList(interpretation['possible_contributors']);

      final recOral = _asStrList(recommendations['oral_hygiene']);
      final recHydration = _asStrList(recommendations['hydration']);
      final recDietDo = _asStrList(recommendations['diet_do']);
      final recDietLimit = _asStrList(recommendations['diet_limit']);
      final recLifestyle = _asStrList(recommendations['lifestyle']);

      final riskLevel = (risk['level'] ?? '').toString();
      final riskRecheck = (risk['recheck_in'] ?? '').toString();
      final riskFlags = _asStrList(risk['red_flags']);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.tongueImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.tongueImageFile!,
                  height: MediaQuery.of(context).size.height * 0.40,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ).animate().fadeIn(duration: 420.ms).scale(),
            const SizedBox(height: 16),

            /// Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.red.shade100, width: 1.2),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.red.shade50,
                        child:
                        const Icon(LucideIcons.activity, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Tongue Analysis",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // // Chips row (Color → Shape → Texture)
                  // Wrap(
                  //   spacing: 8,
                  //   runSpacing: 8,
                  //   children: [
                  //     chip(
                  //       chipText(
                  //         (color['label'] ?? 'healthy').toString(),
                  //         (color['confidence'] ?? 0) is num
                  //             ? (color['confidence'] as num).toInt()
                  //             : int.tryParse(color['confidence']?.toString() ?? "0") ??
                  //             0,
                  //       ),
                  //       Colors.redAccent,
                  //     ),
                  //     chip(
                  //       chipText(
                  //         (shape['label'] ?? 'normal').toString(),
                  //         (shape['confidence'] ?? 0) is num
                  //             ? (shape['confidence'] as num).toInt()
                  //             : int.tryParse(shape['confidence']?.toString() ?? "0") ??
                  //             0,
                  //       ),
                  //       Colors.orange,
                  //     ),
                  //     chip(
                  //       chipText(
                  //         (texture['label'] ?? 'normal').toString(),
                  //         (texture['confidence'] ?? 0) is num
                  //             ? (texture['confidence'] as num).toInt()
                  //             : int.tryParse(
                  //             texture['confidence']?.toString() ?? "0") ??
                  //             0,
                  //       ),
                  //       Colors.red,
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 12),

                  // 1–2 line headline summary
                  if (summary.trim().isNotEmpty)
                    _boldifyText(
                      summary,
                      baseStyle: GoogleFonts.poppins(
                          fontSize: 14.5, color: Colors.black87),
                      boldStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),

                  const SizedBox(height: 12),

                  // Findings section
                  _sectionTitle("Objective findings"),
                  const SizedBox(height: 6),
                  _bullet("Color: ${(color['definition'] ?? '').toString()}"),
                  if ((color['meaning'] ?? '').toString().trim().isNotEmpty)
                    _bullet("Common reasons: ${(color['meaning']).toString()}"),
                  if ((shape['explanation'] ?? '').toString().trim().isNotEmpty)
                    _bullet("Shape: ${(shape['explanation']).toString()}"),
                  if ((texture['explanation'] ?? '').toString().trim().isNotEmpty)
                    _bullet("Texture: ${(texture['explanation']).toString()}"),

                  const SizedBox(height: 12),

                  // Interpretation
                  if (interpretation.isNotEmpty) ...[
                    _sectionTitle("Interpretation"),
                    const SizedBox(height: 6),
                    if ((interpretation['overall'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      _boldifyText(
                        interpretation['overall'].toString(),
                        baseStyle: GoogleFonts.poppins(
                            fontSize: 13.8, color: Colors.black87),
                      ),
                    if (gutLinks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text("Links to gut habits:",
                          style: GoogleFonts.poppins(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      ...gutLinks.map((s) => _bullet(s)),
                    ],
                    if (possibleContributors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text("Possible contributors:",
                          style: GoogleFonts.poppins(
                              fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      ...possibleContributors.map((s) => _bullet(s)),
                    ],
                    const SizedBox(height: 10),
                  ],

                  // Recommendations (structured)
                  if (recommendations.isNotEmpty) ...[
                    _sectionTitle("Recommendations"),
                    const SizedBox(height: 8),
                    if (recOral.isNotEmpty)
                      _recBlock("Oral hygiene", recOral, Icons.clean_hands),
                    if (recHydration.isNotEmpty)
                      _recBlock("Hydration", recHydration, Icons.local_drink),
                    if (recDietDo.isNotEmpty || recDietLimit.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _dietCard(
                              title: "Diet — Add",
                              items: recDietDo,
                              accent: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dietCard(
                              title: "Diet — Limit",
                              items: recDietLimit,
                              accent: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 15),
                    if (recLifestyle.isNotEmpty)
                      _recBlock("Lifestyle", recLifestyle, Icons.self_improvement),
                    const SizedBox(height: 8),
                  ],

                  // Tips (max 4)
                  if (tips.isNotEmpty) ...[
                    _sectionTitle("Quick suggestions"),
                    const SizedBox(height: 6),
                    ...tips.take(4).map((t) =>
                        _suggestionTile(title: (t['title'] ?? '').toString(), details: (t['details'] ?? '').toString())),
                    const SizedBox(height: 6),
                  ],

                  // Diet pointers (compat with previous layout)
                  if (dietDo.isNotEmpty || dietLimit.isNotEmpty) ...[
                    _sectionTitle("Diet pointers"),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _dietCard(
                            title: "Do",
                            items: dietDo,
                            accent: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dietCard(
                            title: "Limit",
                            items: dietLimit,
                            accent: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Risk box
                  if (risk.isNotEmpty &&
                      (riskLevel.isNotEmpty ||
                          riskRecheck.isNotEmpty ||
                          riskFlags.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    _riskCard(level: riskLevel, recheckIn: riskRecheck, flags: riskFlags),
                  ],

                  // Disclaimer
                  if (disclaimer.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: _boldifyText(
                        disclaimer,
                        baseStyle: GoogleFonts.poppins(
                            fontSize: 12.5, color: Colors.red.shade700),
                        boldStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.12, duration: 300.ms),
          ],
        ),
      );
    }

    // ---------- Fallback: previous AI-only path ----------
    final colorMap = asStringKeyedMap(widget.tongueAnalysisResults['color']);

    // Prefer AI blocks computed at upload time by the controller
    final preShapeAI = asStringKeyedMap(widget.tongueAnalysisResults['shape_ai']);
    final preTextureAI = asStringKeyedMap(widget.tongueAnalysisResults['texture_ai']);

    // Also pick final labels/scores (from Gemini image pass in controller)
    final shapeMap = asStringKeyedMap(widget.tongueAnalysisResults['shape']);
    final textureMap = asStringKeyedMap(widget.tongueAnalysisResults['texture']);

    final shapeLabel = _extractLabel(shapeMap) ?? "normal";
    final shapeScore = (_extractConfidence(shapeMap) ?? 0.0).toInt();
    final textureLabel = _extractLabel(textureMap) ?? "normal";
    final textureScore = (_extractConfidence(textureMap) ?? 0.0).toInt();

    // Combined layman summary from Gemini (if provided by controller)
    final combined =
    asStringKeyedMap(widget.tongueAnalysisResults['combined_summary']);
    final combinedSummary = (combined['summary'] ?? '').toString().trim();
    final redFlags = ((combined['red_flags'] as List?) ?? const <String>[])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);

    // Color stays local (model-based)
    final colorInfo = _colorAdvice(colorMap);
    final colorExp = (colorInfo['explanation'] ?? "").toString();

    // Helper to render the single compact card (shared by both paths below)
    Widget buildSummaryCard({
      required Map<String, dynamic> shapeAI,
      required Map<String, dynamic> textureAI,
    }) {
      final shapeExp = (shapeAI['explanation'] ?? "").toString();
      final textureExp = (textureAI['explanation'] ?? "").toString();

      // Merge top suggestions (max 3 total): color (local) + AI(shape) + AI(texture)
      final List<Map<String, String>> colorSug =
          (colorInfo['suggestions'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map((e) => e.map((k, v) => MapEntry(k, v.toString())))
              .toList()
              .cast<Map<String, String>>() ??
              [];

      List<Map<String, String>> _norm(List? raw) {
        if (raw == null) return const [];
        return raw.cast<Map>().map((e) {
          final m =
          (e as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
          return {
            "item": m["item"] ?? "",
            "details": m["details"] ?? "",
            "how_it_helps": m["how_it_helps"] ?? "",
          };
        }).toList().cast<Map<String, String>>();
      }

      final shapeSug = _norm(shapeAI['suggestions'] as List?);
      final textureSug = _norm(textureAI['suggestions'] as List?);

      final combinedSuggestions = <Map<String, String>>[];
      void addIfNotEmpty(Map<String, String> s) {
        if (s.values.any((v) => (v).trim().isNotEmpty)) {
          combinedSuggestions.add(s);
        }
      }

      for (final s in [...colorSug, ...shapeSug, ...textureSug]) {
        if (combinedSuggestions.length >= 3) break;
        addIfNotEmpty(s);
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.red.shade100, width: 1.2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.red.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.red.shade50,
                        child:
                        const Icon(LucideIcons.activity, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Tongue Summary",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Combined layman summary (if present)
            if (combinedSummary.isNotEmpty) ...[
              _boldifyText(
                combinedSummary,
                baseStyle: GoogleFonts.poppins(
                    fontSize: 14.5, color: Colors.black87),
                boldStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
            ],

            // Concise merged explanation (bold via parser, underscores removed)
            _boldifyText("• ${_trimTo(colorExp, 140)}"),
            if (shapeExp.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _boldifyText("• ${_trimTo(shapeExp, 120)}"),
            ],
            if (textureExp.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _boldifyText("• ${_trimTo(textureExp, 120)}"),
            ],

            if (redFlags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.flag, size: 18, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Text("When to check in",
                      style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                ],
              ),
              const SizedBox(height: 6),
              ...redFlags.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _boldifyText("• $f",
                    baseStyle: GoogleFonts.poppins(
                        fontSize: 13.5, color: Colors.black87)),
              )),
            ],

            if (combinedSuggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.lightbulb, size: 18, color: Colors.redAccent),
                  SizedBox(width: 6),
                  Text("Top Suggestions",
                      style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                ],
              ),
              const SizedBox(height: 8),
              ...combinedSuggestions.map((s) {
                final item = _titleize(
                    (s['item'] ?? '').replaceAll("*", "").trim());
                final details = (s['details'] ?? '').replaceAll("_", " ");
                final helps = (s['how_it_helps'] ?? '').replaceAll("_", " ");
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.isNotEmpty)
                        Text(item,
                            style: GoogleFonts.poppins(
                                fontSize: 14.5, fontWeight: FontWeight.w600)),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _boldifyText(details,
                            baseStyle: GoogleFonts.poppins(
                                fontSize: 13.5, color: Colors.black87)),
                      ],
                      if (helps.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _boldifyText("How it helps: $helps",
                            baseStyle: GoogleFonts.poppins(
                                fontSize: 12.5, color: Colors.black54),
                            boldStyle:
                            const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                );
              }),
            ],

            // Disclaimer — prefer AI (shape/texture) then color
            finalDisclaimer(preShapeAI, preTextureAI, colorInfo),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.15, duration: 320.ms);
    }

    // If the controller already provided AI, render immediately (no spinner)
    if (preShapeAI.isNotEmpty || preTextureAI.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (widget.tongueImageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.tongueImageFile!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ).animate().fadeIn(duration: 500.ms).scale(),
            const SizedBox(height: 16),
            buildSummaryCard(shapeAI: preShapeAI, textureAI: preTextureAI),
          ],
        ),
      );
    }

    // Otherwise, call Gemini now (still AI-only path)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (widget.tongueImageFile != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                widget.tongueImageFile!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ).animate().fadeIn(duration: 500.ms).scale(),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: Future.wait([
              _shapeInsightsFuture ??
                  Future.value({
                    "explanation": "",
                    "suggestions": [],
                    "disclaimer": ""
                  }),
              _textureInsightsFuture ??
                  Future.value({
                    "explanation": "",
                    "suggestions": [],
                    "disclaimer": ""
                  }),
            ]),
            builder: (context, snap) {
              final shape = (snap.data != null && snap.data!.isNotEmpty)
                  ? snap.data![0]
                  : {
                "explanation": "",
                "suggestions": [],
                "disclaimer": ""
              };
              final texture = (snap.data != null && snap.data!.length > 1)
                  ? snap.data![1]
                  : {
                "explanation": "",
                "suggestions": [],
                "disclaimer": ""
              };
              return buildSummaryCard(shapeAI: shape, textureAI: texture);
            },
          ),
        ],
      ),
    );
  }

  Widget _recBlock(String title, List<String> items, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: Colors.black54),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 13.8, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          ...items.map((s) => _boldifyText("• ${s.replaceAll('_', ' ')}",
              baseStyle:
              GoogleFonts.poppins(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _riskCard({
    required String level,
    required String recheckIn,
    required List<String> flags,
  }) {
    final Color c = (level.toLowerCase() == "high")
        ? Colors.red
        : (level.toLowerCase() == "moderate")
        ? Colors.orange
        : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.withOpacity(0.07),
        border: Border.all(color: c.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.security, size: 16, color: c),
          const SizedBox(width: 6),
          Text("Risk", style: GoogleFonts.poppins(
              fontSize: 13.8, fontWeight: FontWeight.w700, color: c)),
        ]),
        const SizedBox(height: 6),
        if (level.isNotEmpty)
          _boldifyText("Level: ${_titleize(level)}",
              baseStyle: GoogleFonts.poppins(fontSize: 13)),
        if (recheckIn.isNotEmpty)
          _boldifyText("Recheck in: $recheckIn",
              baseStyle: GoogleFonts.poppins(fontSize: 13)),
        if (flags.isNotEmpty) ...[
          const SizedBox(height: 4),
          _boldifyText("Red flags:", baseStyle: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...flags.map((f) => _boldifyText("• $f",
              baseStyle: GoogleFonts.poppins(fontSize: 13)))
        ],
      ]),
    );
  }

  Widget finalDisclaimer(Map<String, dynamic> shape,
      Map<String, dynamic> texture, Map<String, dynamic> colorInfo) {
    String disc = (shape['disclaimer'] ?? "").toString().trim();
    if (disc.isEmpty) {
      disc = (texture['disclaimer'] ?? "").toString().trim();
    }
    if (disc.isEmpty) {
      disc = (colorInfo['disclaimer'] ?? "").toString().trim();
    }
    if (disc.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: _boldifyText(
            disc,
            baseStyle: GoogleFonts.poppins(
                fontSize: 12.5, color: Colors.red.shade700),
            boldStyle:
            TextStyle(fontWeight: FontWeight.w700, color: Colors.red.shade700),
          ),
        ),
      ],
    );
  }

  String _trimTo(String text, int max) {
    final t = text.trim();
    if (t.length <= max) return t;
    final cut = t.substring(0, max);
    final lastDot = cut.lastIndexOf('.');
    if (lastDot > 40) return cut.substring(0, lastDot + 1);
    final lastSpace = cut.lastIndexOf(' ');
    return (lastSpace > 40 ? cut.substring(0, lastSpace) : cut) + '…';
  }

  Widget _chipSmall(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
            fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.redAccent),
      ),
    );
  }

  // ---- Small helpers for the red/white UI ----
  Widget _sectionTitle(String s) => Row(
    children: [
      const Icon(Icons.segment, size: 16, color: Colors.redAccent),
      const SizedBox(width: 6),
      Text(s,
          style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Colors.black87)),
    ],
  );

  Widget _bullet(String s) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(fontSize: 16, height: 1.2)),
        Expanded(
          child: _boldifyText(
            s,
            baseStyle: GoogleFonts.poppins(
                fontSize: 13.8, color: Colors.black87),
            boldStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _suggestionTile({required String title, required String details}) {
    final cleanTitle = title.replaceAll("*", "").trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cleanTitle.isNotEmpty)
            Text(cleanTitle,
                style:
                GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600)),
          if (details.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            _boldifyText(details,
                baseStyle:
                GoogleFonts.poppins(fontSize: 13.2, color: Colors.black87)),
          ],
        ],
      ),
    );
  }

  Widget _dietCard(
      {required String title,
        required List<String> items,
        required Color accent}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14.5, fontWeight: FontWeight.w700, color: accent)),
        const SizedBox(height: 6),
        ...items.take(6).map((e) => _boldifyText("• ${e.replaceAll('_', ' ')}",
            baseStyle:
            GoogleFonts.poppins(fontSize: 13, color: Colors.black87))),
      ]),
    );
  }

  // ------------------ Survey Results (unchanged behavior) ------------------
  Widget _buildSurveyResultsPage() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userDocFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.redAccent));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("User data not found"));
        }

        final userData = snapshot.data!.data()!;
        final gender = userData['gender']?.toString().toLowerCase();

        final double maxScore = (gender == "male") ? 56.0 : 56.0;
        final double percentageScore =
            (widget.surveyTotalScore / maxScore) * 100.0;
        final Color riskColor = _getRiskColor(percentageScore);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.surveyResponses.isNotEmpty) ...[
                Text("Your Responses",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.surveyResponses.length,
                  itemBuilder: (context, index) {
                    final resp = widget.surveyResponses[index];
                    final qText = resp.questionText.isNotEmpty
                        ? resp.questionText
                        : "Question ${index + 1}";
                    final aText = resp.selectedOption.isNotEmpty
                        ? resp.selectedOption
                        : "—";
                    final rank = _zeroBasedRiskRank(resp);
                    final riskLabel = _riskLabelByRank(rank);
                    final rowColor = _riskColorByRank(rank);
                    final bg = rowColor.withOpacity(0.08);
                    final border = rowColor.withOpacity(0.7);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(left: BorderSide(color: border, width: 6)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: rowColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    rank <= 0
                                        ? Icons.check_circle
                                        : (rank == 1
                                        ? Icons.info
                                        : (rank == 2
                                        ? Icons.warning
                                        : Icons.error)),
                                    color: rowColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Q${index + 1}: $qText",
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                      const SizedBox(height: 6),
                                      Text("Your Answer: $aText",
                                          style: GoogleFonts.poppins(fontSize: 14)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: rowColor.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                              color: rowColor.withOpacity(0.6)),
                                        ),
                                        child: Text("Risk: $riskLabel",
                                            style: GoogleFonts.poppins(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: rowColor)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (rank >= 1) ...[
                              const SizedBox(height: 12),
                              _buildSuggestionSection(
                                index: index,
                                riskColor: rowColor,
                                label: riskLabel,
                                questionText: qText,
                                answerText: aText,
                                category: resp.resultCategory.toString(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              Row(children: [
                Expanded(
                  child: _buildStatCard("Questions Answered",
                      "${widget.surveyResponses.length}", LucideIcons.helpCircle, Colors.blue),
                ),
              ]),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [riskColor.withOpacity(0.2), riskColor]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text("Gut Health Score: ",
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      Text("${percentageScore.toInt()}%",
                          style: GoogleFonts.poppins(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (percentageScore.clamp(0, 100)) / 100,
                      minHeight: 12,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          riskColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 12),
                    Text(_getHealthMessage(percentageScore),
                        style: GoogleFonts.poppins(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text("Risk Level: ${_getRiskLevel(percentageScore)}",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // suggestions section (unchanged)
  Widget _buildSuggestionSection({
    required int index,
    required Color riskColor,
    required String label,
    required String questionText,
    required String answerText,
    required String category,
  }) {
    final expanded = _expandedSuggestions[index] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () =>
              setState(() => _expandedSuggestions[index] = !expanded),
          child: Row(
            children: [
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  size: 22, color: riskColor),
              const SizedBox(width: 6),
              Text(expanded ? "Hide Suggestions" : "Show Suggestions",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: riskColor)),
              const SizedBox(width: 8),
              if ((widget.preloadedSuggestions?[index]?.isNotEmpty ?? false))
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: riskColor.withOpacity(0.35)),
                  ),
                  child: Text(
                    "${widget.preloadedSuggestions![index]!.length}",
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: riskColor),
                  ),
                ),
            ],
          ),
        ),
        if (expanded) ...[
          const SizedBox(height: 8),
          _buildSuggestionBody(
            index: index,
            riskColor: riskColor,
            questionText: questionText,
            answerText: answerText,
            category: category,
            riskLabel: label,
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionBody({
    required int index,
    required Color riskColor,
    required String questionText,
    required String answerText,
    required String category,
    required String riskLabel,
  }) {
    final preloaded = widget.preloadedSuggestions?[index];
    if (preloaded != null && preloaded.isNotEmpty) {
      return _renderSuggestionList(preloaded, riskColor);
    }

    final future = _suggestionsFutures.putIfAbsent(
      index,
          () => GeminiService.surveySuggestions(
        category: category,
        question: questionText,
        answer: answerText,
        riskLabel: riskLabel,
        gender: _userGender ?? "",
      ),
    );

    return FutureBuilder<List<Map<String, String>>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Row(children: const [
            SizedBox(width: 6),
            SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text("Fetching suggestions...", style: TextStyle(fontSize: 12)),
          ]);
        }
        if (snap.hasError) {
          return Text("Couldn't load suggestions.",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54));
        }
        final list = snap.data ?? const [];
        if (list.isEmpty) {
          return Text("No suggestions for this response.",
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54));
        }
        return _renderSuggestionList(list, riskColor);
      },
    );
  }

  Widget _renderSuggestionList(
      List<Map<String, String>> list, Color riskColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.lightbulb, size: 18, color: riskColor),
          const SizedBox(width: 6),
          Text("Suggestions",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
        const SizedBox(height: 6),
        ...list.map((s) {
          final title =
          _titleize((s['item'] ?? '').replaceAll("*", "").trim());
          final details = (s['details'] ?? '').replaceAll("_", " ");
          final helps = (s['how_it_helps'] ?? '').replaceAll("_", " ");
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style:
                      GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _boldifyText(details,
                      baseStyle: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.black87)),
                ],
                if (helps.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _boldifyText("How it helps: $helps",
                      baseStyle: GoogleFonts.poppins(
                          fontSize: 12.5, color: Colors.black54)),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  // --------- Stats + Risk helpers ---------
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  int _zeroBasedRiskRank(SurveyResponse r) {
    final opts = (r.optionsCount <= 0) ? 4 : r.optionsCount;
    final rank = opts - r.marks; // 0 Low, 1 Moderate, 2 High, 3+ Very High
    return rank < 0 ? 0 : rank;
  }

  String _riskLabelByRank(int rank) {
    if (rank <= 0) return "Low";
    if (rank == 1) return "Moderate";
    if (rank == 2) return "High";
    return "Very High";
  }

  Color _riskColorByRank(int rank) {
    if (rank <= 0) return Colors.green;
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.orange;
    return Colors.red;
  }

  String _getHealthMessage(double riskPercent) {
    if (riskPercent >= 75) return "Your health looks excellent!";
    if (riskPercent >= 50) {
      return "You’re in good health — consider some subtle changes to keep improving.";
    }
    if (riskPercent >= 25) return "Your health needs attention.";
    return "Your health is at high risk. Consider lifestyle changes.";
  }

  String _getRiskLevel(double riskPercent) {
    if (riskPercent >= 75) return "Low";
    if (riskPercent >= 50) return "Moderate";
    if (riskPercent >= 25) return "High";
    return "Critical";
  }

  Color _getRiskColor(double riskPercent) {
    if (riskPercent >= 75) return Colors.green;
    if (riskPercent >= 50) return Colors.amber;
    if (riskPercent >= 25) return Colors.orange;
    return Colors.red;
  }
}
