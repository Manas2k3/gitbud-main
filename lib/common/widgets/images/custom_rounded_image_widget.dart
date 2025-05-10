import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shimmer/shimmer.dart';

import '../../../articles/data/db/article.dart';
import '../../../articles/data/db/article_view.dart';

class CustomRoundedImageWidget extends StatelessWidget {
  const CustomRoundedImageWidget({
    super.key,
    required this.article,
    this.onPressed,
    required this.title,
    this.borderRadius = 16,
  });

  final Article article;
  final String title;
  final VoidCallback? onPressed;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    // Get the width of the screen
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: onPressed,
      child: InkWell(
          onTap: () {Get.to(ArticleCard(article: article,));},
        child: Container(
          height: 380,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align title to the start
              children: [
                CachedNetworkImage(
                  imageUrl: article.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Shimmer.fromColors(
                    direction: ShimmerDirection.ltr,
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.white,
                    child: Container(
                      width: double.infinity,
                      height: 200, // Set a fixed height for the placeholder
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(child: Icon(Icons.error)), // Error widget if loading fails
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0), // Add padding around the title
                  child: Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 14, fontWeight: FontWeight.bold,),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}