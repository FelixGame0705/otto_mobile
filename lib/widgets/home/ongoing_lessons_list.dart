import 'package:flutter/material.dart';

class OngoingLessonItem {
  final String title;
  final int currentChallenge;
  final int totalChallenges;
  final String? lessonId;
  OngoingLessonItem({
    required this.title,
    required this.currentChallenge,
    required this.totalChallenges,
    this.lessonId,
  });
}

class OngoingLessonsList extends StatelessWidget {
  final List<OngoingLessonItem> lessons;
  const OngoingLessonsList({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const Text('No ongoing lessons');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lessons.take(5).map((l) => _buildItem(context, l)).toList(),
    );
  }

  Widget _buildItem(BuildContext context, OngoingLessonItem l) {
    final progress = (l.totalChallenges == 0)
        ? 0.0
        : (l.currentChallenge / l.totalChallenges).clamp(0, 1).toDouble();
    return InkWell(
      onTap: () {
        if (l.lessonId != null && l.lessonId!.isNotEmpty) {
          Navigator.of(context).pushNamed('/lesson-detail', arguments: l.lessonId);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: progress, minHeight: 8),
            const SizedBox(height: 4),
            Text('${l.currentChallenge}/${l.totalChallenges} challenges',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}


