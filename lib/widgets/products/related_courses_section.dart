import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/course_robot_model.dart';
import 'package:ottobit/widgets/products/course_card.dart';

class RelatedCoursesSection extends StatelessWidget {
  final List<CourseRobot> relatedCourses;
  final bool isLoadingCourses;
  final Function(String courseId) onCourseTap;

  const RelatedCoursesSection({
    super.key,
    required this.relatedCourses,
    required this.isLoadingCourses,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.relatedCourses'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoadingCourses)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (relatedCourses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.school, color: Color(0xFF9CA3AF), size: 48),
                const SizedBox(height: 12),
                Text(
                  'product.noCourses'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive card width based on screen size
              final screenWidth = constraints.maxWidth;
              final cardWidth = screenWidth > 600 
                  ? (screenWidth - 48) / 3  // 3 cards on tablet/desktop
                  : screenWidth > 400 
                      ? (screenWidth - 36) / 2  // 2 cards on larger phones
                      : screenWidth - 32;  // 1 card on smaller phones
              
              return SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: relatedCourses.length,
                  itemBuilder: (context, index) {
                    final courseRobot = relatedCourses[index];
                    return Container(
                      width: cardWidth,
                      margin: const EdgeInsets.only(right: 12),
                      child: CourseCard(
                        courseRobot: courseRobot,
                        onTap: () => onCourseTap(courseRobot.courseId),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
