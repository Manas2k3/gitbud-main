import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResultBox extends StatelessWidget {
  final String createdAt;
  final int questionScore;

  const ResultBox({Key? key, required this.createdAt, required this.questionScore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = DateTime.parse(createdAt);
    String formattedDate = DateFormat('dd-MM-yyyy hh:mm a').format(dateTime);

    return InkWell(
      onTap: () {
        // Navigate to the result screen
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formattedDate),
                Text('Gut Score: $questionScore'),
              ],
            ),
            Icon(Icons.score),
          ],
        ),
      ),
    );
  }
}
