import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gibud/features/screens/kids/kids_section.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../utils/constants/image_strings.dart';
import '../../gut_test/gut_test_screen.dart';

class DynamicCard extends StatelessWidget {
  final String title;
  final String image;
  final Widget navigateTo;

  const DynamicCard({
    Key? key,
    required this.title,
    required this.image,
    required this.navigateTo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: InkWell(
        onTap: () {
          Get.to(() => navigateTo);
        },
        child: Container(
          width: screenWidth * 1.2,
          height: screenHeight * 0.2,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.redAccent,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    image,
                    height: screenHeight * 0.08,
                    fit: BoxFit.cover, // To ensure proper image scaling
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardSliderWidget extends StatefulWidget {
  const CardSliderWidget({Key? key}) : super(key: key);

  @override
  State<CardSliderWidget> createState() => _CardSliderWidgetState();
}

class _CardSliderWidgetState extends State<CardSliderWidget> {
  final PageController _pageController = PageController();
  final List<Map<String, dynamic>> dynamicCards = [
    {
      'title': 'Take a quick \n Gi-Bud Gut Test!',
      'image': ImageStrings.gut_test_image,
      'navigateTo': GutTestScreen(),
    },
    {
      'title': 'Explore Personalized \n Health Insights for Kids',
      'image': ImageStrings.gut_test_image,
      'navigateTo': KidsSection(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.23,
          child: PageView.builder(
            controller: _pageController,
            itemCount: dynamicCards.length,
            itemBuilder: (context, index) {
              return DynamicCard(
                title: dynamicCards[index]['title'],
                image: dynamicCards[index]['image'],
                navigateTo: dynamicCards[index]['navigateTo'],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SmoothPageIndicator(
          controller: _pageController,
          count: dynamicCards.length,
          effect: WormEffect(
            dotWidth: 10,
            dotHeight: 10,
            activeDotColor: Colors.redAccent,
            dotColor: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }
}
