import 'package:flutter/material.dart';
import 'package:ottobit/widgets/home/ongoing_lessons_list.dart';

class OngoingLessonsGrid extends StatelessWidget {
  final List<OngoingLessonItem> lessons;
  const OngoingLessonsGrid({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const Text('No ongoing lessons');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final l = lessons[index];
        final progress = (l.totalChallenges == 0)
            ? 0.0
            : (l.currentChallenge / l.totalChallenges).clamp(0, 1).toDouble();
        return InkWell(
          onTap: () {
            if (l.lessonId != null && l.lessonId!.isNotEmpty) {
              Navigator.of(context).pushNamed('/lesson-detail', arguments: l.lessonId);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                LinearProgressIndicator(value: progress, minHeight: 8),
                const SizedBox(height: 4),
                Text('${l.currentChallenge}/${l.totalChallenges} challenges', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}


