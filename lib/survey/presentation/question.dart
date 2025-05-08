import 'package:flutter/material.dart';

// Response class similar to your Kotlin data class
class Response {
  final String text; // Instead of resource ID
  final int marks;
  final String resultCategory; // Instead of resource ID

  Response({required this.text, required this.marks, required this.resultCategory});
}

// Single Choice Question Widget
class SingleChoiceQuestion extends StatelessWidget {
  final String title;
  final String directions;
  final List<Response> possibleAnswers;
  final Response? selectedAnswer;
  final ValueChanged<Response> onOptionSelected;

  const SingleChoiceQuestion({
    Key? key,
    required this.title,
    required this.directions,
    required this.possibleAnswers,
    required this.selectedAnswer,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 8),
        Text(directions, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 16),
        Column(
          children: possibleAnswers.map((response) {
            return RadioButtonWithImageRow(
              text: response.text,
              selected: response == selectedAnswer,
              onOptionSelected: () => onOptionSelected(response),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// Radio Button with Image Row Widget
class RadioButtonWithImageRow extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onOptionSelected;

  const RadioButtonWithImageRow({
    Key? key,
    required this.text,
    required this.selected,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOptionSelected,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.blueAccent.withOpacity(0.2) : Colors.white,
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Uncomment and use an Image widget if needed
            // Image.asset('path_to_image', width: 56, height: 56),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (value) => onOptionSelected(),
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
