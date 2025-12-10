import 'package:flutter/material.dart';

class CompletedChallengeItem {
  final String title;
  final String lessonTitle;
  final int order;
  final String completedAt;
  CompletedChallengeItem({
    required this.title,
    required this.lessonTitle,
    required this.order,
    required this.completedAt,
  });
}

class CompletedChallengesGrid extends StatelessWidget {
  final List<CompletedChallengeItem> challenges;
  const CompletedChallengesGrid({super.key, required this.challenges});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) return const Text('No completed challenges yet');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final c = challenges[index];
        return Container(
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
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text('${c.lessonTitle} • #${c.order}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text('Done: ${c.completedAt.split('T').first}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}


