// lib/services/gemini_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static GenerativeModel? _modelVision;
  static GenerativeModel? _modelText;

  /// Call once (safe to call multiple times).
  static void ensureInitialized() {
    if (_modelVision != null && _modelText != null) return;

    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print("GEMINI_API_KEY missing. Falling back to no-op responses.");
      }
      return;
    }

    // 2.0 Flash for speed and low-latency UX
    _modelVision = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
    _modelText = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  // ---------------------------------------------------------------------------
  // SURVEY SUGGESTIONS
  // ---------------------------------------------------------------------------

  /// Survey → AI suggestions (plain-language, non-diagnostic).
  /// Returns a list of {item, details, how_it_helps}.
  static Future<List<Map<String, String>>> surveySuggestions({
    required String category,
    required String question,
    required String answer,
    required String riskLabel,
    String? gender,
  }) async {
    ensureInitialized();
    if (_modelText == null) {
      return _fallbackSuggestions(category, riskLabel, gender ?? "");
    }

    final g = (gender ?? "").toLowerCase();
    final prompt = """
You are a friendly wellness coach. Create actionable, non-diagnostic tips based on a user's survey response. Keep it concise, plain language, and practical.

INPUT:
- category: "$category"
- question: "$question"
- user_answer: "$answer"
- risk_level: "$riskLabel"
- gender_hint: "$g"

CONSTRAINTS:
- 2 to 4 suggestions.
- No diseases, medications, or diagnosis.
- Avoid moralizing; focus on doable steps at home (habits, hydration, food, hygiene, light activity, sleep).
- Keep each string ≤ 140 characters. No underscores. Use simple punctuation.

RETURN STRICT JSON:
{
  "suggestions": [
    {"item":"Short title","details":"What to do","how_it_helps":"Why it helps"}
  ]
}
""";

    try {
      final res = await _modelText!.generateContent([Content.text(prompt)]);
      final text = res.text ?? "{}";
      final root = jsonDecode(_extractJson(text));
      final list = _coerceSuggestions(root["suggestions"]);
      if (list.isNotEmpty) return list;
      return _fallbackSuggestions(category, riskLabel, g);
    } catch (_) {
      return _fallbackSuggestions(category, riskLabel, g);
    }
  }

  static List<Map<String, String>> _coerceSuggestions(dynamic v) {
    if (v is! List) return const <Map<String, String>>[];
    final out = <Map<String, String>>[];
    for (final e in v) {
      if (e is Map) {
        final item = (e["item"] ?? "").toString();
        final details = (e["details"] ?? "").toString();
        final helps = (e["how_it_helps"] ?? "").toString();
        if (item.trim().isEmpty && details.trim().isEmpty && helps.trim().isEmpty) continue;
        out.add({
          "item": item,
          "details": details,
          "how_it_helps": helps,
        });
      }
    }
    return out;
  }

  static List<Map<String, String>> _fallbackSuggestions(String category, String risk, String gender) {
    final low = [
      {
        "item": "Keep the good stuff",
        "details": "Stick with your current routine and small daily walks.",
        "how_it_helps": "Consistency supports steady digestion and energy."
      },
      {
        "item": "Hydration habit",
        "details": "Sip water regularly; set 3 reminder times.",
        "how_it_helps": "Better hydration keeps things moving smoothly."
      },
    ];
    final med = [
      {
        "item": "Fiber bump",
        "details": "Add a fist-size salad or fruit with lunch.",
        "how_it_helps": "Gentle fiber supports gut balance."
      },
      {
        "item": "Meal timing",
        "details": "Aim for regular meal times, avoid late-night snacking.",
        "how_it_helps": "Rhythm helps digestion and sleep."
      },
      {
        "item": "Easy movement",
        "details": "10–15 min walk after meals.",
        "how_it_helps": "Light activity aids digestion."
      },
    ];
    final high = [
      {
        "item": "Simple swaps",
        "details": "Cut one ultra-processed snack; swap with nuts or curd.",
        "how_it_helps": "Reduces heavy, hard-to-digest foods."
      },
      {
        "item": "Fluids first",
        "details": "Start mornings with warm water; keep a refillable bottle nearby.",
        "how_it_helps": "Hydration can ease discomfort and coating."
      },
      {
        "item": "Steady sleep",
        "details": "Target 7–8 hours; wind down 30 min early.",
        "how_it_helps": "Sleep supports appetite and gut rhythm."
      },
    ];
    final veryHigh = [
      {
        "item": "Gentle, bland base",
        "details": "Choose easy meals: rice, dal, steamed veg, curd.",
        "how_it_helps": "Light foods are easier on the gut."
      },
      {
        "item": "Spice dial-down",
        "details": "Reduce chilli and deep fried items for a few days.",
        "how_it_helps": "Can lower irritation and heat sensations."
      },
      {
        "item": "Routine check",
        "details": "Regular meals, water every couple of hours, short walks.",
        "how_it_helps": "Predictability calms the system."
      },
    ];

    switch (risk.toLowerCase()) {
      case "low":
        return low;
      case "moderate":
        return med;
      case "high":
        return high;
      case "very high":
      case "critical":
        return veryHigh;
      default:
        return med;
    }
  }

  // ---------------------------------------------------------------------------
  // IMAGE ANALYSIS
  // ---------------------------------------------------------------------------

  /// Analyze SHAPE & TEXTURE directly from the uploaded tongue image (client-side Gemini).
  static Future<Map<String, dynamic>> analyzeShapeTextureFromImage(File imageFile) async {
    ensureInitialized();
    if (_modelVision == null) {
      return _safeEmptyAll();
    }

    final bytes = await imageFile.readAsBytes();
    final mime = _guessMime(imageFile.path) ?? 'image/jpeg';

    // Slightly strengthened instruction so the explanations read more “clinical”
    final sys = """
You are a careful wellness assistant. Analyze the *tongue photo* to infer only **shape** and **texture**. Do **not** diagnose or mention diseases.
Write crisp, specific descriptions like a clinical note, but keep language friendly.

Output **strict JSON** with this schema:
{
  "shape": {"label":"scalloped | swollen | thin | normal | cracked | pointy | asymmetrical | other", "score":0-100},
  "texture":{"label":"smooth | rough | fissured | patchy | coated | normal | other", "score":0-100},
  "shape_ai":{
    "explanation":"1–2 sentences that describe what is visible (location/extent if relevant). No medical claims.",
    "suggestions":[{"item":"Short title","details":"What to do at home (food, habits, hygiene).","how_it_helps":"Short effect rationale."}],
    "disclaimer":"Short, non-diagnostic disclaimer."
  },
  "texture_ai":{
    "explanation":"1–2 sentences that describe what is visible (coating thickness if any, evenness). No medical claims.",
    "suggestions":[{"item":"Short title","details":"Actionable step.","how_it_helps":"Short rationale."}],
    "disclaimer":"Short, non-diagnostic disclaimer."
  },
  "combined_summary":{
    "summary":"3–5 bullet-ish sentences merged for a report section. Keep it specific to what is seen.",
    "red_flags":["optional short flags like persistent pain, bleeding, fever (max 3)"]
  }
}
Rules:
- Scores are integers 0–100 (confidence style).
- Prefer *normal* labels if unsure.
- No diseases or medications. Lifestyle wording only.
""";

    final prompt = TextPart(sys);
    final imagePart = DataPart(mime, bytes);

    GenerateContentResponse resp;
    try {
      resp = await _modelVision!.generateContent([
        Content.multi([prompt, imagePart]),
      ]);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print("Gemini image call failed: $e");
      }
      return _safeEmptyAll();
    }

    final raw = resp.text ?? "{}";
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(_extractJson(raw));
    } catch (_) {
      parsed = {};
    }

    final shape = _coerceLabelScore(parsed['shape']);
    final texture = _coerceLabelScore(parsed['texture']);
    final shapeAI = _coerceAI(parsed['shape_ai']);
    final textureAI = _coerceAI(parsed['texture_ai']);
    final combined = _coerceCombined(parsed['combined_summary']);

    return {
      "shape": {"Label": shape['label'], "Score": shape['score']},
      "texture": {"Label": texture['label'], "Score": texture['score']},
      "shape_ai": shapeAI,
      "texture_ai": textureAI,
      "combined_summary": combined,
    };
  }

  /// NEW — verify whether the provided image is a clear tongue photo.
  ///
  /// Returns:
  /// { 'isTongue': bool, 'confidence': double (0.0 - 1.0), 'detail': Map<String,dynamic> }
  ///
  /// NOTE: fallback is conservative — if Gemini isn't initialized or verification fails,
  /// this method returns isTongue: false to block analysis (safer).
  static Future<Map<String, dynamic>> verifyIsTongue(File imageFile) async {
    ensureInitialized();
    // If Gemini not initialized, return conservative fallback => block analysis.
    if (_modelVision == null) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Gemini not initialized; returning conservative non-tongue fallback.');
      }
      return {
        'isTongue': false,
        'confidence': 0.0,
        'detail': {'note': 'gemini not initialized - conservative fallback (blocks analysis)'}
      };
    }

    final bytes = await imageFile.readAsBytes();
    final mime = _guessMime(imageFile.path) ?? 'image/jpeg';

    // Prompt: ask for strict JSON with isTongue + confidence (0..1) + reason
    final promptText = """
You are a reliable vision assistant. Given the attached image, answer whether this is a clear, well-captured photo of a human tongue (showing most of the tongue surface, tip-to-root, in focus, and not obviously occluded).

RETURN STRICT JSON ONLY with this exact shape:
{
  "isTongue": true | false,
  "confidence": 0.0 - 1.0,
  "reason": "Short explanation of the main reason for the decision (lighting, angle, occlusion, not a tongue).",
  "details": { /* optional: any extra diagnostic hints for dev */ }
}

Be concise. Do not include any extra text outside the JSON object.
""";

    final prompt = TextPart(promptText);
    final imagePart = DataPart(mime, bytes);

    try {
      final resp = await _modelVision!.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      final raw = resp.text ?? "{}";
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(_extractJson(raw));
      } catch (e) {
        parsed = {};
      }

      // Coerce fields safely:
      final isTongueRaw = parsed['isTongue'];
      final confidenceRaw = parsed['confidence'];
      final reason = (parsed['reason'] ?? parsed['explanation'] ?? '').toString();
      final details = (parsed['details'] is Map) ? Map<String, dynamic>.from(parsed['details']) : {'raw': parsed};

      final bool isTongue = (isTongueRaw is bool) ? isTongueRaw : (isTongueRaw?.toString().toLowerCase() == 'true');
      double confidence = 0.0;
      if (confidenceRaw is num) {
        confidence = (confidenceRaw as num).toDouble();
      } else if (confidenceRaw is String) {
        confidence = double.tryParse(confidenceRaw) ?? 0.0;
      } else {
        // If model returned 0-100, convert to 0-1
        final possiblePct = parsed['confidence_percent'] ?? parsed['confidence_pct'] ?? parsed['confidence_score'];
        if (possiblePct is num) {
          final v = (possiblePct as num).toDouble();
          if (v > 1.0) confidence = (v / 100.0).clamp(0.0, 1.0);
        }
      }
      confidence = confidence.clamp(0.0, 1.0);

      return {
        'isTongue': isTongue ?? false,
        'confidence': confidence,
        'detail': {
          'reason': reason,
          ...details,
        }
      };
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('verifyIsTongue failed: $e');
      }
      // Conservative fallback: block analysis
      return {
        'isTongue': false,
        'confidence': 0.0,
        'detail': {'note': 'verification failed, conservative fallback blocks analysis', 'error': e.toString()}
      };
    }
  }

  /// NEW — classify color from the image using Gemini vision.
  /// Returns: { "label": String, "score": int (0-100), "raw": Map }
  static Future<Map<String, dynamic>> analyzeColorFromImage(File imageFile) async {
    ensureInitialized();
    if (_modelVision == null) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Gemini not initialized; analyzeColorFromImage returning fallback.');
      }
      return {"label": "unknown", "score": 0, "raw": {"note": "gemini not initialized"}};
    }

    final bytes = await imageFile.readAsBytes();
    final mime = _guessMime(imageFile.path) ?? 'image/jpeg';

    final prompt = """
You are a careful wellness assistant. Given the attached tongue image, identify the dominant tongue color as a short label and return a confidence score 0-100.

Return STRICT JSON only, shape:
{
  "color": { "label": "white | deep_red | purple | healthy | pale | yellow | coated | other", "score": 0-100 },
  "reason": "Short note about why (lighting, coating, hue)."
}
Be concise and return only JSON.
""";

    final textPart = TextPart(prompt);
    final imagePart = DataPart(mime, bytes);

    try {
      final resp = await _modelVision!.generateContent([
        Content.multi([textPart, imagePart]),
      ]);

      final raw = resp.text ?? "{}";
      Map<String, dynamic> parsed;
      try {
        parsed = jsonDecode(_extractJson(raw));
      } catch (_) {
        parsed = {};
      }

      final c = (parsed['color'] is Map) ? Map<String, dynamic>.from(parsed['color']) : {};
      String label = (c['label'] ?? c['Label'] ?? parsed['color']?.toString() ?? 'unknown').toString();
      int score = 0;
      final possibleScore = c['score'] ?? c['confidence'] ?? parsed['score'];
      if (possibleScore is num) score = (possibleScore as num).toInt().clamp(0, 100);
      if (possibleScore is String) score = int.tryParse(possibleScore) ?? 0;

      label = label.toLowerCase().trim();

      return {
        "label": label.isEmpty ? "unknown" : label,
        "score": score,
        "raw": parsed,
      };
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print("analyzeColorFromImage failed: $e");
      }
      return {"label": "unknown", "score": 0, "raw": {"error": e.toString()}};
    }
  }

  /// Text-only helper (kept for backwards compatibility).
  static Future<Map<String, dynamic>> shapeTextureInsights({
    required String type, // "shape" | "texture"
    required String label,
    double? score,
    String? extraContext,
  }) async {
    ensureInitialized();
    if (_modelText == null) return _safeAI();

    final safeLabel = label.isEmpty ? (type == "shape" ? "normal" : "normal") : label;
    final s = (score ?? 0.0).clamp(0, 100).toStringAsFixed(0);

    final prompt = """
You are writing a short, non-diagnostic explanation for a wellness report. Focus ONLY on $type patterns from a tongue assessment. No diseases, no meds.

Given:
- $type label: "$safeLabel"
- confidence: $s/100
${(extraContext ?? "").isNotEmpty ? "- context hint: ${extraContext!.trim()}" : ""}

Return strict JSON:
{
  "explanation":"max 2 sentences, plain language, specific to what is seen.",
  "suggestions":[{"item":"Short action","details":"How to do it at home.","how_it_helps":"One-line why it helps."}],
  "disclaimer":"One line. Not medical advice."
}
""";

    try {
      final res = await _modelText!.generateContent([Content.text(prompt)]);
      final text = res.text ?? "{}";
      return _coerceAI(jsonDecode(_extractJson(text)));
    } catch (_) {
      return _safeAI();
    }
  }

  // ---------------------------------------------------------------------------
  // ENHANCED: COLOR INSIGHTS + CLINICAL-STYLE LAYMAN REPORT
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> colorInsights({
    required String label,
    double? score,
  }) async {
    ensureInitialized();
    if (_modelText == null) {
      return {
        "definition": "",
        "meaning": "",
        "tips": const <Map<String, String>>[],
        "disclaimer": ""
      };
    }

    final s = (score ?? 0.0).clamp(0, 100).toStringAsFixed(0);

    final prompt = """
You are preparing a short wellness note about tongue COLOR for a layperson. Be specific and descriptive but non-diagnostic.

Given:
- color label: "$label"
- confidence: $s/100

Return STRICT JSON:
{
  "definition":"Describe the appearance in 1 sentence (mention intensity if relevant).",
  "meaning":"Common, non-medical explanations in 1 sentence (e.g., foods, hydration, mild irritation).",
  "tips":[{"item":"Short title","details":"Simple step to try at home."}],
  "disclaimer":"One line, non-diagnostic."
}
""";

    try {
      final res = await _modelText!.generateContent([Content.text(prompt)]);
      final text = res.text ?? "{}";
      final root = jsonDecode(_extractJson(text));
      return {
        "definition": (root["definition"] ?? "").toString(),
        "meaning": (root["meaning"] ?? "").toString(),
        "tips": ((root["tips"] as List?) ?? const [])
            .map((e) => {
          "item": (e["item"] ?? "").toString(),
          "details": (e["details"] ?? "").toString(),
        })
            .toList(),
        "disclaimer": (root["disclaimer"] ?? "").toString(),
      };
    } catch (_) {
      return {
        "definition": "",
        "meaning": "",
        "tips": const <Map<String, String>>[],
        "disclaimer": ""
      };
    }
  }

  /// ENHANCED — medical-style (but plain) report JSON.
  static Future<Map<String, dynamic>> buildLaymanReport({
    required String colorLabel,
    double? colorScore,
    required String shapeLabel,
    double? shapeScore,
    required String textureLabel,
    double? textureScore,
  }) async {
    ensureInitialized();

    final color = await colorInsights(label: colorLabel, score: colorScore);
    final shapeAI = await shapeTextureInsights(
      type: "shape",
      label: shapeLabel,
      score: shapeScore,
      extraContext: null,
    );
    final textureAI = await shapeTextureInsights(
      type: "texture",
      label: textureLabel,
      score: textureScore,
      extraContext: null,
    );

    if (_modelText == null) {
      // Local fallback composition
      return {
        "summary":
        "Clinical-style summary: findings appear within a normal-to-minor range. See structured notes below.",
        "color": {
          "label": colorLabel,
          "confidence": (colorScore ?? 0).round(),
          "definition": color["definition"] ?? "",
          "meaning": color["meaning"] ?? "",
        },
        "shape": {
          "label": shapeLabel,
          "confidence": (shapeScore ?? 0).round(),
          "explanation": (shapeAI["explanation"] ?? "").toString(),
        },
        "texture": {
          "label": textureLabel,
          "confidence": (textureScore ?? 0).round(),
          "explanation": (textureAI["explanation"] ?? "").toString(),
        },
        "tips": [
          ...((color["tips"] as List?) ?? const []),
          ...((shapeAI["suggestions"] as List?) ?? const [])
              .take(1)
              .map((e) => {
            "title": (e["item"] ?? "").toString(),
            "details": (e["details"] ?? "").toString()
          }),
          ...((textureAI["suggestions"] as List?) ?? const [])
              .take(1)
              .map((e) => {
            "title": (e["item"] ?? "").toString(),
            "details": (e["details"] ?? "").toString()
          }),
        ].take(5).toList(),
        "diet": {
          "do": [
            "Hydrate regularly",
            "Add curd/yogurt or buttermilk",
            "Include fresh fruits/veg",
            "Eat at regular times"
          ],
          "limit": [
            "Very spicy/fried foods",
            "Excess alcohol",
            "Overly hot beverages",
            "Late-night heavy meals"
          ]
        },
        "interpretation": {
          "overall": "Findings are consistent with common lifestyle factors. No diagnostic statements.",
          "gut_links": [
            "Hydration and regular meals support tongue coating balance.",
            "Spicy or very hot foods may temporarily deepen color."
          ],
          "possible_contributors": ["recent spicy foods", "mild dehydration"]
        },
        "recommendations": {
          "oral_hygiene": ["Gently brush/scrape tongue once daily using a soft tool."],
          "hydration": ["Sip water throughout the day; aim for pale urine."],
          "diet_do": ["Simple probiotic sources (curd/yogurt) 3–4×/week"],
          "diet_limit": ["Deep-fried items; extra chilli for a few days"],
          "lifestyle": ["10–15 minute post-meal walks", "7–8 hours quality sleep"]
        },
        "risk": {
          "level": "low",
          "recheck_in": "7–10 days",
          "red_flags": ["Persistent pain, bleeding, or fever"]
        },
        "disclaimer": (textureAI["disclaimer"]?.toString().isNotEmpty ?? false)
            ? textureAI["disclaimer"]
            : (shapeAI["disclaimer"]?.toString().isNotEmpty ?? false)
            ? shapeAI["disclaimer"]
            : (color["disclaimer"] ?? ""),
      };
    }

    // ——— Enhanced prompt for a clinical-style (yet plain) report ———
    final prompt = """
Create a **clinical-style but plain-language** tongue examination summary for a wellness app. 
NO diagnoses or medication names. Do not alarm the user. 
Be descriptive and specific about what is seen.

INPUT (labels + 0–100 confidence):
- color: "$colorLabel" (${(colorScore ?? 0).round()})
- shape: "$shapeLabel" (${(shapeScore ?? 0).round()})
- texture: "$textureLabel" (${(textureScore ?? 0).round()})

RETURN STRICT JSON:

{
  "summary":"1–2 sentences that headline the main visible findings.",
  "color":{"label":"...", "confidence":0, "definition":"What it looks like (mention intensity if relevant).", "meaning":"Common non-medical reasons, 1 sentence."},
  "shape":{"label":"...", "confidence":0, "explanation":"≤2 crisp sentences describing what is visible."},
  "texture":{"label":"...", "confidence":0, "explanation":"≤2 crisp sentences (note coating thin/moderate/thick if relevant)."},
  "interpretation":{
    "overall":"2–3 sentences connecting the findings to everyday factors; avoid diagnoses.",
    "gut_links":["2–4 short bullets that link habits to gut and tongue appearance"],
    "possible_contributors":["2–4 short items e.g., spicy foods, dehydration, mouth breathing"]
  },
  "recommendations":{
    "oral_hygiene":["1–3 short bullets (gentle scraping, soft brush, rinse)"],
    "hydration":["1–3 short bullets"],
    "diet_do":["3–5 short items the user can add"],
    "diet_limit":["3–5 short items to limit for a few days"],
    "lifestyle":["2–4 short items (sleep, meal timing, movement)"]
  },
  "risk":{"level":"low | moderate | high", "recheck_in":"e.g., 7–10 days", "red_flags":["0–3 short items: persistent pain, bleeding, fever"]},
  "tips":[{"title":"Short","details":"Actionable step (hydration/oral hygiene/food/sleep/mild activity)."}],
  "diet":{"do":["3–5 short items"], "limit":["3–5 short items"]},
  "disclaimer":"One short line. Not medical advice."
}

Rules:
- Keep each bullet short and concrete.
- Do not mention diseases or meds.
- Prefer neutral, reassuring tone with clear next steps.
""";

    try {
      final res = await _modelText!.generateContent([Content.text(prompt)]);
      final root = jsonDecode(_extractJson(res.text ?? "{}"));

      // Ensure compatibility keys + overwrite labels/confidence with our inputs
      root["color"] ??= {};
      root["shape"] ??= {};
      root["texture"] ??= {};
      root["color"]["label"] = colorLabel;
      root["color"]["confidence"] = (colorScore ?? 0).round();
      root["shape"]["label"] = shapeLabel;
      root["shape"]["confidence"] = (shapeScore ?? 0).round();
      root["texture"]["label"] = textureLabel;
      root["texture"]["confidence"] = (textureScore ?? 0).round();

      // Keep simple defs even if model trims them
      root["color"]["definition"] ??= color["definition"] ?? "";
      root["color"]["meaning"] ??= color["meaning"] ?? "";

      return root as Map<String, dynamic>;
    } catch (_) {
      // graceful fallback → local composition above
      return await buildLaymanReport(
        colorLabel: colorLabel,
        colorScore: colorScore,
        shapeLabel: shapeLabel,
        shapeScore: shapeScore,
        textureLabel: textureLabel,
        textureScore: textureScore,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static String? _guessMime(String path) {
    final lp = path.toLowerCase();
    if (lp.endsWith(".png")) return "image/png";
    if (lp.endsWith(".webp")) return "image/webp";
    return "image/jpeg";
  }

  static Map<String, dynamic> _coerceLabelScore(dynamic v) {
    if (v is! Map) return {"label": "normal", "score": 0};
    final lbl = (v["label"] ?? "normal").toString();
    final sc = v["score"];
    int score = 0;
    if (sc is num) score = sc.clamp(0, 100).toInt();
    if (sc is String) score = int.tryParse(sc) ?? 0;
    return {"label": lbl, "score": score};
  }

  static Map<String, dynamic> _coerceAI(dynamic v) {
    if (v is! Map) {
      return {
        "explanation": "",
        "suggestions": const <Map<String, String>>[],
        "disclaimer": ""
      };
    }
    List<Map<String, String>> sugg = [];
    try {
      final raw = (v["suggestions"] as List?) ?? const [];
      sugg = raw.map((e) => {
        "item": (e["item"] ?? "").toString(),
        "details": (e["details"] ?? "").toString(),
        "how_it_helps": (e["how_it_helps"] ?? "").toString(),
      }).toList();
    } catch (_) {}
    return {
      "explanation": (v["explanation"] ?? "").toString(),
      "suggestions": sugg,
      "disclaimer": (v["disclaimer"] ?? "").toString(),
    };
  }

  static Map<String, dynamic> _coerceCombined(dynamic v) {
    if (v is! Map) return {"summary": "", "red_flags": const <String>[]};
    final rf = ((v["red_flags"] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(growable: false);
    return {
      "summary": (v["summary"] ?? "").toString(),
      "red_flags": rf,
    };
  }

  static Map<String, dynamic> _safeAI() => {
    "explanation": "",
    "suggestions": const <Map<String, String>>[],
    "disclaimer": "",
  };

  static Map<String, dynamic> _safeEmptyAll() => {
    "shape": {"Label": "normal", "Score": 0},
    "texture": {"Label": "normal", "Score": 0},
    "shape_ai": _safeAI(),
    "texture_ai": _safeAI(),
    "combined_summary": {"summary": "", "red_flags": const <String>[]},
  };

  /// Sometimes models wrap JSON with text; try to pull the JSON block.
  static String _extractJson(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) return s.substring(start, end + 1);
    return s;
  }
}
