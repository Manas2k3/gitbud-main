import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../articles/data/db/article.dart';
import '../../../articles/data/db/article_view.dart';

class CustomRoundedImageWidget extends StatelessWidget {
  const CustomRoundedImageWidget({
    super.key,
    required this.article,
    this.onPressed,
    required this.title,
    this.borderRadius = 12,
  });

  final Article article;
  final String title;
  final VoidCallback? onPressed;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(ArticleCard(article: article)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: article.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Shimmer.fromColors(
                  direction: ShimmerDirection.ltr,
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.white,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                const Center(child: Icon(Icons.error)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
