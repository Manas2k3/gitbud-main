import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:gibud/articles/data/db/article_view.dart';

import '../../../../articles/data/db/article.dart';


class SearchResultsPage extends StatelessWidget {
  final String searchQuery;

  const SearchResultsPage({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    final List<Article> results = articleList
        .where((article) =>
        article.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Search Results for "$searchQuery"'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: results.isEmpty
          ? const Center(child: Text('No results found.'))
          : ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final article = results[index];
          return ListTile(
            leading: Image.network(
              article.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(article.title),
            subtitle: Text(
              article.subTitle ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Get.to(() => ArticleCard(article: article)),
          );
        },
      ),
    );
  }
}
