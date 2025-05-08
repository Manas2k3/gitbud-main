import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Response {
  final String resultCategory;
  final int marks;

  Response(this.resultCategory, this.marks);
}

class ResponseBox extends StatelessWidget {
  final Response response;

  const ResponseBox({Key? key, required this.response}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color boxColor = response.marks > 2 ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
        color: boxColor.withOpacity(0.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            response.resultCategory,
            style: TextStyle(color: Colors.grey),
          ),
          Icon(
            response.marks > 2 ? Icons.error : Icons.check_circle,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
