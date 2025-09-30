import 'package:flutter/material.dart';
import 'package:ottobit/models/enrollment_model.dart';

class EnrollmentsProgressList extends StatelessWidget {
  final List<Enrollment> enrollments;
  const EnrollmentsProgressList({super.key, required this.enrollments});

  @override
  Widget build(BuildContext context) {
    if (enrollments.isEmpty) {
      return const Text('No enrollments yet');
    }
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final e = enrollments[index];
          return _EnrollmentCard(enrollment: e);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemCount: enrollments.length,
      ),
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final Enrollment enrollment;
  const _EnrollmentCard({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(
          '/lessons',
          arguments: {
            'courseId': enrollment.courseId,
            'courseTitle': enrollment.courseTitle,
          },
        );
      },
      child: Container(
      width: 260,
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
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(enrollment.courseImageUrl),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  enrollment.courseTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (enrollment.progress / 100).clamp(0, 1).toDouble(),
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text('${enrollment.progress}% completed', style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/lessons',
                  arguments: {
                    'courseId': enrollment.courseId,
                    'courseTitle': enrollment.courseTitle,
                  },
                );
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    ),
    );
  }
}


