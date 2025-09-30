import 'package:flutter/material.dart';

class HomeAppBarProfile extends StatelessWidget {
  final String fullName;
  final int totalCourses;
  final int completedLessons;
  final int inProgressLessons;

  const HomeAppBarProfile({
    super.key,
    required this.fullName,
    required this.totalCourses,
    required this.completedLessons,
    required this.inProgressLessons,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Courses: $totalCourses  •  Done: $completedLessons  •  Doing: $inProgressLessons',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


