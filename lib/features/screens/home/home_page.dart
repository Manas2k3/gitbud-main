import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/gut_test/gut_test_screen.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gibud/common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:gibud/common/widgets/appbar/appbar.dart';
import 'package:gibud/utils/constants/image_strings.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../articles/data/db/article.dart';
import '../../../articles/data/db/article_view.dart'; // For ArticleViewPage
import '../../../chat/chat_list.dart';
import '../../../chat/dietician_chat_list.dart';
import '../../../chat/chat_payment.dart';
import '../../../common/components/widgets/custom_shapes/containers/circular_container.dart';
import '../../../common/widgets/images/custom_rounded_image_widget.dart';
import '../../personalization/profile/settings.dart';

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
  Widget buildResults(BuildContext context) {
    return Container(); // Not used anymore
  }

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

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final Logger logger = Logger();
  String name = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
      } else {
        String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isNotEmpty) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
            userDoc.data() as Map<String, dynamic>;
            logger.d("User Data from Firestore: $userData");
            setState(() {
              name = userData['name'] ?? 'User';
              isLoading = false;
            });
          } else {
            logger.e('User document does not exist.');
            setState(() => isLoading = false);
          }
        } else {
          logger.e('User is not authenticated.');
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      logger.e('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.blue,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Column(
                      children: [
                        Text(
                          "Hey $name,",
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade200, fontSize: 18),
                        ),
                      ],
                    ),
                    actions: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              await showSearch(
                                context: context,
                                delegate: ArticleSearchDelegate(
                                    articleList),
                              );
                            },
                            icon: const Icon(Icons.search,
                                size: 30, color: Colors.white),
                          ),
                          IconButton(
                            onPressed: () async {
                              try {
                                final userId = FirebaseAuth
                                    .instance.currentUser?.uid ??
                                    '';

                                if (userId.isEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    'User is not authenticated.',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                  return;
                                }

                                final userDoc = await FirebaseFirestore
                                    .instance
                                    .collection('Users')
                                    .doc(userId)
                                    .get();

                                if (userDoc.exists) {
                                  final userData = userDoc.data();
                                  final selectedRole =
                                      userData?['selectedRole'] ?? '';

                                  if (selectedRole == 'user') {
                                    final dieticianQuery =
                                    await FirebaseFirestore.instance
                                        .collection('Users')
                                        .where('selectedRole',
                                        isEqualTo: 'dietician')
                                        .limit(1)
                                        .get();

                                    if (dieticianQuery.docs.isNotEmpty) {
                                      final dietician =
                                          dieticianQuery.docs.first;
                                      final dieticianId = dietician.id;

                                      Get.to(() => ChatListPage(
                                        currentUserId: userId,
                                        dieticianId: dieticianId,
                                      ));
                                    } else {
                                      Get.snackbar(
                                        'Error',
                                        'No dietician is available.',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                      );
                                    }
                                  } else if (selectedRole ==
                                      'dietician') {
                                    Get.to(() => DieticianChatListPage(
                                      dieticianId: userId,
                                      currentUserId: userId,
                                    ));
                                  }

                                  // Optional: re-enable payment logic if needed
                                } else {
                                  Get.snackbar(
                                    'Error',
                                    'User data not found.',
                                    backgroundColor: Colors.red,
                                    colorText: Colors.white,
                                  );
                                }
                              } catch (e) {
                                Get.snackbar(
                                  'Error',
                                  'An error occurred: $e',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.message,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: InkWell(
                      onTap: () {
                        Get.to(() => GutTestScreen());
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.height * 0.2,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Take a quick \n Gi-Bud Gut Test!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.redAccent,
                                    fontSize: 20),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Image.asset(
                                ImageStrings.gut_test_image,
                                height:
                                MediaQuery.of(context).size.height *
                                    0.08,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 25, vertical: 25),
              child: Center(
                child: articleList.isNotEmpty
                    ? CarouselSlider.builder(
                  itemCount: articleList.length,
                  itemBuilder: (context, index, realIndex) {
                    final article = articleList[index];
                    return CustomRoundedImageWidget(
                      article: article,
                      title: article.title,
                    );
                  },
                  options: CarouselOptions(
                    height: MediaQuery.of(context).size.height*0.5,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 4),
                    enlargeCenterPage: true,
                  ),
                )
                    : const Text('No articles available'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
