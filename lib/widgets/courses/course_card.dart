import 'package:flutter/material.dart';
import 'package:ottobit/models/course_model.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final VoidCallback? onEnroll;
  final bool isEnrolled;
  final bool isLoading;

  const CourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.onEnroll,
    this.isEnrolled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              course.description,
              style: const TextStyle(fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            // Stats
            Text(
              '${course.lessonsCount} bài học • ${course.enrollmentsCount} học viên',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 8),
            
            // Created by
            Text(
              'Tạo bởi: ${course.createdByName}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onEnroll,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Text(isEnrolled ? 'Đã đăng ký' : 'Đăng ký'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}