import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class QuestionWrapper extends StatelessWidget {
  final String title;
  final String? directions;
  final Widget child;

  const QuestionWrapper({
    required this.title,
    this.directions,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32.0),
          QuestionTitle(title: title),
          if (directions != null) ...[
            const SizedBox(height: 18.0),
            QuestionDirections(directions: directions!),
          ],
          const SizedBox(height: 18.0),
          child,
        ],
      ),
    );
  }
}

class QuestionTitle extends StatelessWidget {
  final String title;

  const QuestionTitle({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

class QuestionDirections extends StatelessWidget {
  final String directions;

  const QuestionDirections({required this.directions, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      directions,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      textAlign: TextAlign.left,
    );
  }
}
