import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gibud/features/screens/gut_test/gut_test_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';

import '../../../articles/data/db/article.dart';
import '../../../articles/data/db/article_view.dart';
import '../../../chat/chat_list.dart';
import '../../../chat/dietician_chat_list.dart';
import '../../../common/widgets/images/custom_rounded_image_widget.dart';
import '../../../survey/model/response_model.dart';
import '../../../survey/recent_reports.dart';
import '../combinedResultPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class ArticleSearchDelegate extends SearchDelegate<String> {
  final List<Article> articles;

  ArticleSearchDelegate(this.articles);

  @override
  String get searchFieldLabel => 'Search articles...';

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => Container();

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = articles
        .where((article) =>
        article.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final article = suggestions[index];
        return ListTile(
          leading: Image.network(
            article.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(article.title),
          onTap: () {
            close(context, article.title);
            Get.to(() => ArticleCard(article: article));
          },
        );
      },
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Latest Report: smart, contextual card for the Home page
/// ─────────────────────────────────────────────────────────────────────────
class LatestReportCard extends StatelessWidget {
  final String userId;
  const LatestReportCard({required this.userId, super.key});

  // ── Severity helpers (same mapping as your RecentReports page)
  String _getSeverityStatus(int score) {
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

  // Reusable UI bits
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
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Parsing helpers copied from your RecentReports logic
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

  // Small helpers used inside build
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
    final col = FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .collection('Reports');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.orderBy('createdAt', descending: true).limit(1).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const _LatestReportSkeleton(); // shimmer

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _LatestReportEmpty(onStart: () => _goToGutTest(context));
        }

        final d = docs.first;
        final data = d.data();

        final createdAt =
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final score = (data['questionScore'] ?? 0) as int;

        const maxScore = 56.0;
        final severity = _getSeverityStatus(score);
        final color = _getSeverityColor(severity);
        final pct = ((score / maxScore) * 100.0).clamp(0, 100).toDouble();

        final ta = _asStringKeyedMap(data['tongueAnalysisResults']);
        final combined = _asStringKeyedMap(ta['combined_summary']);
        final summary = (combined['summary'] ?? '').toString();

        final chips = <String>[];
        final colorLbl = _extractLabel(_asStringKeyedMap(ta['color']));
        final shapeLbl = _extractLabel(_asStringKeyedMap(ta['shape']));
        final textureLbl = _extractLabel(_asStringKeyedMap(ta['texture']));
        if ((colorLbl ?? '').isNotEmpty) chips.add("Color: ${_titleize(colorLbl!)}");
        if ((shapeLbl ?? '').isNotEmpty) chips.add("Shape: ${_titleize(shapeLbl!)}");
        if ((textureLbl ?? '').isNotEmpty) chips.add("Texture: ${_titleize(textureLbl!)}");

        return _LatestReportUI(
          date: DateFormat("d MMM, h:mm a").format(createdAt),
          severity: severity,
          color: color,
          score: score,
          pct: pct,
          chips: chips.take(2).toList(),
          summary: _trimTo(summary, 90),
          onView: () => _openCombined(context, d.reference.path, data),
          onRetake: () => _goToGutTest(context),
          onSeeAll: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RecentReportsPage(userId: userId)),
          ),
        );
      },
    );
  }

  void _openCombined(BuildContext ctx, String path, Map<String, dynamic> data) {
    final ta = _asStringKeyedMap(data['tongueAnalysisResults']);
    final ai = data['aiSuggestions'] is Map<String, dynamic>
        ? data['aiSuggestions'] as Map<String, dynamic>
        : null;

    Get.to(() => CombinedResultsPage(
      sourceDocPath: path,
      allowMirror: false,
      tongueAnalysisResults: ta,
      tongueImageFile: null,
      surveyResponses: _parseResponses(data['questionResponseJsonArray']),
      surveyTotalScore: (data['questionScore'] ?? 0) as int,
      preloadedSuggestions: _parseAiSuggestions(ai),
    ));
  }

  void _goToGutTest(BuildContext ctx) {
    Get.to(GutTestScreen());
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// Home page state
/// ─────────────────────────────────────────────────────────────────────────
class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger();

  final PageController _cardPageController =
  PageController(viewportFraction: 0.85);
  int _currentCardIndex = 0;

  String name = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final args = Get.arguments;

      if (args != null && args is Map<String, dynamic>) {
        logger.d("User Data from arguments: $args");
        setState(() {
          name = args['name'] ?? 'User';
          isLoading = false;
        });
        return;
      }

      final userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        logger.e('User is not authenticated.');
        setState(() => isLoading = false);
        return;
      }

      final userDoc =
      await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        logger.d("User Data from Firestore: $userData");
        setState(() {
          name = userData['name'] ?? 'User';
          isLoading = false;
        });
      } else {
        logger.e('User document does not exist.');
        setState(() => isLoading = false);
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  void _handleMessageTap() async {
    try {
      final userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        Get.snackbar('Error', 'User is not authenticated.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final userDoc =
      await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      if (!userDoc.exists) {
        Get.snackbar('Error', 'User data not found.',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final selectedRole = userDoc.data()?['selectedRole'] ?? '';

      if (selectedRole == 'user') {
        final dieticianQuery = await FirebaseFirestore.instance
            .collection('Users')
            .where('selectedRole', isEqualTo: 'dietician')
            .limit(1)
            .get();

        if (dieticianQuery.docs.isNotEmpty) {
          final dieticianId = dieticianQuery.docs.first.id;
          Get.to(() =>
              ChatListPage(currentUserId: userId, dieticianId: dieticianId));
        } else {
          Get.snackbar('Error', 'No dietician is available.',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else if (selectedRole == 'dietician') {
        Get.to(() =>
            DieticianChatListPage(currentUserId: userId, dieticianId: userId));
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userIdForCard = _auth.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Color(0xFFE6F3FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          "Hey ${name.split(' ').first},",
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, size: 26, color: Colors.black87),
                onPressed: () => showSearch(
                  context: context,
                  delegate: ArticleSearchDelegate(articleList),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.message, size: 26, color: Colors.black87),
                onPressed: _handleMessageTap,
              ),
            ],
          ),
        ],
      ),
      // backgroundColor removed — gradient handles it now
      body: Stack(
        children: [
          // 🔹 Gradient background
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFE6F3FF), // soft light blue
                    Colors.white,      // fades to white
                  ],
                ),
              ),
            ),
          ),

          // 🔹 Your original content sits above the gradient
          isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.blue))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userIdForCard.isNotEmpty)
                  LatestReportCard(userId: userIdForCard),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.06,
                ),
                Text(
                  "Recommended Articles",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.04,
                ),
                SizedBox(
                  height: 260,
                  child: articleList.isNotEmpty
                      ? CarouselSlider.builder(
                    itemCount: articleList.length,
                    itemBuilder: (context, index, realIndex) {
                      final article = articleList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.65,
                          child: CustomRoundedImageWidget(
                            article: article,
                            title: article.title,
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: MediaQuery.of(context).size.height * 0.6,
                      enlargeCenterPage: true,
                      viewportFraction: 0.7,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      autoPlayAnimationDuration:
                      const Duration(milliseconds: 800),
                      enableInfiniteScroll: true,
                      scrollPhysics: const BouncingScrollPhysics(),
                    ),
                  )
                      : const Center(child: Text('No articles available')),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// ─────────────────────────────────────────────────────────────────────────
/// Support widgets for LatestReportCard
/// ─────────────────────────────────────────────────────────────────────────

class _LatestReportSkeleton extends StatelessWidget {
  const _LatestReportSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: 2),
      duration: const Duration(seconds: 2),
      builder: (context, t, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          padding: const EdgeInsets.all(16),
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
          child: ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [base, highlight, base],
              stops: [
                (t - 0.3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(rect),
            blendMode: BlendMode.srcATop,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(height: 14, width: 140, radius: 6),
                    _box(height: 22, width: 78, radius: 999),
                  ],
                ),
                const SizedBox(height: 12),
                // score line
                Row(children: [
                  _box(height: 12, width: 48, radius: 6),
                  const SizedBox(width: 8),
                  _box(height: 12, width: 120, radius: 6),
                ]),
                const SizedBox(height: 8),
                _box(height: 10, width: double.infinity, radius: 8),
                const SizedBox(height: 10),
                Row(children: [
                  _box(height: 10, width: 80, radius: 999),
                  const SizedBox(width: 8),
                  _box(height: 10, width: 90, radius: 999),
                ]),
                const SizedBox(height: 12),
                _box(height: 12, width: double.infinity, radius: 8),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _box(height: 36, width: 120, radius: 999),
                    const SizedBox(width: 8),
                    _box(height: 36, width: 110, radius: 999),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _box(
      {required double height, required double width, double radius = 12}) {
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

class _LatestReportEmpty extends StatelessWidget {
  final VoidCallback onStart;
  const _LatestReportEmpty({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Report',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            "You haven't taken a gut test yet. Start your first one to get insights.",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              minimumSize: const Size(140, 44),
            ),
            child: const Text('Start Gut Test'),
          ),
        ],
      ),
    );
  }
}

class _LatestReportUI extends StatelessWidget {
  final String date;
  final String severity;
  final Color color;
  final int score;
  final double pct;
  final List<String> chips;
  final String summary;
  final VoidCallback onView;
  final VoidCallback onRetake;
  final VoidCallback onSeeAll;

  const _LatestReportUI({
    required this.date,
    required this.severity,
    required this.color,
    required this.score,
    required this.pct,
    required this.chips,
    required this.summary,
    required this.onView,
    required this.onRetake,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ]),
              _severityChip(severity, color),
            ],
          ),
          const SizedBox(height: 12),

          // score + bar
          Row(children: [
            Text(
              "Score:",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            Text("$score / 56  (${pct.toStringAsFixed(0)}%)"),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map((c) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(.35)),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 12.5,
                  ),
                ),
              ))
                  .toList(),
            ),
          ],

          // const SizedBox(height: 10),
          // Text(summary, maxLines: 3, overflow: TextOverflow.ellipsis),

          const SizedBox(height: 12),
          Row(
            children: [
              // primary action
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.bar_chart_rounded, size: 16),
                  label: const Text(
                    'View report',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14), // softer than Stadium
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // secondary action
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.blue),
                  label: Text(
                    'Retake test',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue, width: 1.3),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // tertiary action
              TextButton(
                onPressed: onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          )


        ],
      ),
    );
  }

  Widget _severityChip(String status, Color color) {
    IconData icon = Icons.info;
    if (status == 'Low') icon = Icons.check_circle;
    if (status == 'High') icon = Icons.warning;
    if (status == 'Very High') icon = Icons.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
