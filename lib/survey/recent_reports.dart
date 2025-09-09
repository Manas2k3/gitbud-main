// lib/features/results/recent_reports_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../survey/model/response_model.dart';
import '../features/screens/combinedResultPage.dart';

class _RecentReportsSkeleton extends StatelessWidget {
  final int count;
  const _RecentReportsSkeleton({this.count = 6});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween(begin: -1, end: 2),
      onEnd: () {},
      builder: (context, value, child) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ShimmerCard(progress: value),
        );
      },
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  final double progress; // -1..2
  const _ShimmerCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: ShaderMask(
        shaderCallback: (rect) => LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [base, highlight, base],
          stops: [
            (progress - 0.3).clamp(0.0, 1.0),
            progress.clamp(0.0, 1.0),
            (progress + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(rect),
        blendMode: BlendMode.srcATop,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _skeletonBox(height: 14, width: 180, radius: 8),
              _skeletonBox(height: 24, width: 80, radius: 999),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _skeletonBox(height: 14, width: 50, radius: 6),
              const SizedBox(width: 8),
              _skeletonBox(height: 14, width: 120, radius: 6),
            ]),
            const SizedBox(height: 10),
            _skeletonBox(height: 10, width: double.infinity, radius: 8),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [_SkeletonChip(), _SkeletonChip(), _SkeletonChip()],
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonBox({
    required double height,
    required double width,
    double radius = 12,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonChip extends StatelessWidget {
  const _SkeletonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }
}

class RecentReportsPage extends StatelessWidget {
  final String userId;
  RecentReportsPage({required this.userId});

  static const double _MAX_SCORE = 56.0;

  // ---------- SAFE HELPERS ----------
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
    if (r is Map) {
      final lbl = (r as Map)['label'];
      if (lbl != null) return lbl.toString();
    }
    final lbl = data['Label'] ?? data['label'];
    return lbl?.toString();
  }

  String _titleize(String s) {
    final clean = s.replaceAll("_", " ").trim();
    return clean.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return "";
      final lower = w.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(" ");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recent Reports')),
      body: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: _watchReportsOnly(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final count = (snapshot.data?.length ?? 3).clamp(1, 6);
            return _RecentReportsSkeleton(count: count);
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data!;
          if (docs.isEmpty) {
            return const Center(child: Text('No recent reports found.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();

              final createdAt =
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
              final score = (data['questionScore'] ?? 0) as int;

              final severity = _getSeverityStatus(score);
              final color = _getSeverityColor(severity);

              final pct = ((score / _MAX_SCORE) * 100.0).clamp(0, 100);
              final shortMonthDate =
              DateFormat("d MMM yyyy, h:mm a").format(createdAt);

              // ---- NEW: tongue snapshot bits ----
              final ta = _asStringKeyedMap(data['tongueAnalysisResults']);
              final colorMap = _asStringKeyedMap(ta['color']);
              final shapeMap = _asStringKeyedMap(ta['shape']);
              final textureMap = _asStringKeyedMap(ta['texture']);
              final combined = _asStringKeyedMap(ta['combined_summary']);

              final colorLbl   = _extractLabel(colorMap);
              final shapeLbl   = _extractLabel(shapeMap);
              final textureLbl = _extractLabel(textureMap);

              final combinedSummary =
              (combined['summary'] ?? '').toString().trim();

              final chips = <String>[];
              if ((colorLbl ?? '').isNotEmpty)   chips.add("Color: ${_titleize(colorLbl!)}");
              if ((shapeLbl ?? '').isNotEmpty)   chips.add("Shape: ${_titleize(shapeLbl!)}");
              if ((textureLbl ?? '').isNotEmpty) chips.add("Texture: ${_titleize(textureLbl!)}");

              // ---- Suggestions preview (existing) ----
              final Map<String, dynamic>? aiSuggRaw =
              data['aiSuggestions'] is Map<String, dynamic>
                  ? data['aiSuggestions'] as Map<String, dynamic>
                  : null;

              final previewChips = <String>[];
              if (aiSuggRaw != null) {
                for (final entry in aiSuggRaw.entries) {
                  final list = entry.value;
                  if (list is List && list.isNotEmpty) {
                    for (final s in list) {
                      if (previewChips.length >= 2) break;
                      if (s is Map &&
                          (s['item'] ?? '').toString().trim().isNotEmpty) {
                        previewChips.add(s['item'].toString());
                      }
                    }
                  }
                  if (previewChips.length >= 2) break;
                }
              }

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final responses = _parseResponses(data['questionResponseJsonArray']);
                  final preloaded = _parseAiSuggestions(aiSuggRaw);

                  Get.to(() => CombinedResultsPage(
                    sourceDocPath: d.reference.path, // from history
                    allowMirror: false, // DO NOT mirror again
                    tongueAnalysisResults: ta, // normalized
                    tongueImageFile: null as File?, // not stored here
                    surveyResponses: responses,
                    surveyTotalScore: score,
                    preloadedSuggestions: preloaded,
                  ));
                },
                child: _buildReportTile(
                  formattedDateTime: shortMonthDate,
                  color: color,
                  severity: severity,
                  score: score,
                  pct: pct.toDouble(),
                  previewChips: previewChips,
                  tongueChips: chips,
                  combinedSummary: combinedSummary,
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ---------- REAL-TIME: REPORTS-ONLY ----------
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _watchReportsOnly(String uid) {
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('Reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }


  /// Build the same SHA-1 key used elsewhere (kept for completeness)
  String _computeReportKeyFromDoc(Map<String, dynamic> m) {
    final score = (m['questionScore'] ?? 0) as int;
    final rawList = (m['questionResponseJsonArray'] as List?) ?? const [];
    final norm = <Map<String, dynamic>>[];
    for (int i = 0; i < rawList.length; i++) {
      final e = (rawList[i] as Map?)?.cast<String, dynamic>() ?? const {};
      norm.add({
        'i': i,
        'q': (e['questionText'] ?? '').toString(),
        'a': (e['selectedOption'] ?? '').toString(),
        'm': (e['marks'] ?? 0) as int,
        'c': (e['optionsCount'] ?? 4) is int ? e['optionsCount'] : 4,
      });
    }
    final raw = jsonEncode({'score': score, 'responses': norm});
    return sha1.convert(utf8.encode(raw)).toString();
  }



  // ---------- UI HELPERS ----------
  Widget _buildReportTile({
    required String formattedDateTime,
    required Color color,
    required String severity,
    required int score,
    required double pct, // 0..100
    required List<String> previewChips,
    required List<String> tongueChips,
    required String combinedSummary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(LucideIcons.calendar, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  formattedDateTime,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ]),
              _severityChip(severity, color),
            ],
          ),
          const SizedBox(height: 12),

          // Score row + bar
          Row(children: [
            Text("Score:",
                style: GoogleFonts.poppins(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(
              "$score / ${_MAX_SCORE.toInt()}  (${pct.toStringAsFixed(0)}%)",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),



          // Suggestions preview (existing)
          if (previewChips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              Icon(LucideIcons.sparkles, size: 18, color: color),
              const SizedBox(width: 6),
              Text("Suggestions (saved)",
                  style: GoogleFonts.poppins(
                      fontSize: 13.5, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: previewChips
                  .map((txt) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Text(
                  txt,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _getSeverityStatus(int score) {
    // Keeping your mapping (low score => higher severity)
    if (score <= 14) return 'Very High';
    if (score <= 28) return 'High';
    if (score <= 42) return 'Moderate';
    return 'Low';
  }

  Color _getSeverityColor(String status) {
    switch (status) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.amber;
      case 'High':
        return Colors.orange;
      case 'Very High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _severityChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            status == 'Low'
                ? Icons.check_circle
                : (status == 'Moderate'
                ? Icons.info
                : (status == 'High' ? Icons.warning : Icons.error)),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(status,
              style: GoogleFonts.poppins(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  List<SurveyResponse> _parseResponses(dynamic raw) {
    final List<SurveyResponse> out = [];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          try {
            out.add(SurveyResponse.fromJson(e));
          } catch (_) {
            out.add(SurveyResponse(
              marks: (e['marks'] ?? 0) as int,
              resultCategory: (e['resultCategory'] ?? 0) as int,
              stringResourceId: (e['stringResourceId'] ?? 0) as int,
              questionText: (e['questionText'] ?? '').toString(),
              selectedOption: (e['selectedOption'] ?? '').toString(),
              optionsCount:
              (e['optionsCount'] ?? 4) is int ? e['optionsCount'] as int : 4,
            ));
          }
        } else if (e is Map) {
          // defensive normalization
          out.add(SurveyResponse(
            marks: (e['marks'] ?? 0) as int,
            resultCategory: (e['resultCategory'] ?? 0) as int,
            stringResourceId: (e['stringResourceId'] ?? 0) as int,
            questionText: (e['questionText'] ?? '').toString(),
            selectedOption: (e['selectedOption'] ?? '').toString(),
            optionsCount:
            (e['optionsCount'] ?? 4) is int ? e['optionsCount'] as int : 4,
          ));
        }
      }
    }
    return out;
  }

  Map<int, List<Map<String, String>>>? _parseAiSuggestions(
      Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final Map<int, List<Map<String, String>>> out = {};
    for (final entry in raw.entries) {
      final idx = int.tryParse(entry.key);
      if (idx == null) continue;
      final val = entry.value;
      if (val is List) {
        final list = <Map<String, String>>[];
        for (final s in val) {
          if (s is Map) {
            list.add({
              'item': (s['item'] ?? '').toString(),
              'details': (s['details'] ?? '').toString(),
              'how_it_helps': (s['how_it_helps'] ?? '').toString(),
            });
          }
        }
        if (list.isNotEmpty) out[idx] = list;
      }
    }
    return out.isEmpty ? null : out;
  }
}
