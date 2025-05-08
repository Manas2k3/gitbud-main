import 'package:flutter/material.dart';

class SeverityBar extends StatelessWidget {
  final int score;

  const SeverityBar({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String indicator = 'You are here'; // Change based on your logic
    Color color = Colors.blue; // Change based on your logic

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(indicator),
              Icon(Icons.arrow_drop_down),
            ],
          ),
          Container(
            width: double.infinity,
            height: 10,
            color: color,
          ),
        ],
      ),
    );
  }
}
