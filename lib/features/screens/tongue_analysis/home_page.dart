import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gibud/features/screens/food_swap/food_swap_image_upload_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../articles/data/db/article.dart';
import '../../../articles/data/db/article_view.dart';
import '../../../chat/chat_list.dart';
import '../../../chat/dietician_chat_list.dart';
import '../../../common/components/widgets/custom_shapes/containers/circular_container.dart';
import '../../../common/components/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../common/widgets/images/custom_rounded_image_widget.dart';
import '../../../features/screens/gut_test/gut_test_screen.dart';
import '../../../features/screens/home/widgets/dynamic_cards.dart';
import '../../../utils/constants/image_strings.dart';
import '../../personalization/profile/settings.dart';
import '../kids/kids_section.dart';

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

class _HomePageState extends State<HomePage> {

  final List<Map<String, dynamic>> dynamicCards = [
    {
      'title': 'Take a quick \n Gi-Bud Gut Test!',
      'image': ImageStrings.gut_test_image,
      'navigateTo': GutTestScreen(),
    },
    {
      'title': 'Explore Personalized \nHealth Insights for Kids',
      'image': ImageStrings.kidImage,
      'navigateTo': KidsSection(),
    },
    {
      'title': 'Discover Personalized Nutrition \nInsights From Your Plate',
      'image': ImageStrings.foodSwapImage,
      'navigateTo': FoodSwapImageUploadPage(),
    },
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger logger = Logger();

  final PageController _cardPageController = PageController(viewportFraction: 0.85);
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

      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();

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

      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
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
          Get.to(() => ChatListPage(currentUserId: userId, dieticianId: dieticianId));
        } else {
          Get.snackbar('Error', 'No dietician is available.',
              backgroundColor: Colors.red, colorText: Colors.white);
        }
      } else if (selectedRole == 'dietician') {
        Get.to(() => DieticianChatListPage(
          currentUserId: userId,
          dieticianId: userId,
        ));
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue,))
          : SingleChildScrollView(
        child: Column(
          children: [
            PrimaryHeaderContainer(
              color: Colors.blue,
              child: Column(
                children: [
                  CustomAppBar(
                    title: Text(
                      "Hey $name,",
                      style: GoogleFonts.poppins(
                          color: Colors.grey.shade200, fontSize: 18),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search, size: 30, color: Colors.white),
                        onPressed: () => showSearch(
                          context: context,
                          delegate: ArticleSearchDelegate(articleList),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, size: 30, color: Colors.white),
                        onPressed: _handleMessageTap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Modified carousel section
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _cardPageController,
                      itemCount: dynamicCards.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentCardIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final card = dynamicCards[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: DynamicCard(
                            title: card['title'],
                            image: card['image'],
                            navigateTo: card['navigateTo'],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSmoothIndicator(
                    activeIndex: _currentCardIndex,
                    count: dynamicCards.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.white,
                      dotColor: Colors.grey.shade300,
                    ),
                    onDotClicked: (index) {
                      _cardPageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
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
                    aspectRatio: 16 / 9,
                    height: MediaQuery.of(context).size.height * 0.39,
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
