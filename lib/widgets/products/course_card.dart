import 'package:flutter/material.dart';
import 'package:ottobit/models/course_robot_model.dart';

class CourseCard extends StatelessWidget {
  final CourseRobot courseRobot;
  final VoidCallback? onTap;

  const CourseCard({
    super.key,
    required this.courseRobot,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final isSmallCard = cardWidth < 200;
            final isMediumCard = cardWidth < 300;
            
            return Padding(
              padding: EdgeInsets.all(isSmallCard ? 8 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Icon
                  Container(
                    height: isSmallCard ? 32 : (isMediumCard ? 36 : 40),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school,
                        color: const Color(0xFF3B82F6),
                        size: isSmallCard ? 20 : (isMediumCard ? 22 : 24),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallCard ? 6 : 8),
                  // Course Title
                  Expanded(
                    child: Text(
                      courseRobot.courseTitle,
                      style: TextStyle(
                        fontSize: isSmallCard ? 12 : (isMediumCard ? 13 : 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: isSmallCard ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: isSmallCard ? 3 : 4),
                  // Required indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallCard ? 4 : 6, 
                      vertical: isSmallCard ? 1 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: courseRobot.isRequired 
                          ? const Color(0xFFEF4444).withOpacity(0.1)
                          : const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      courseRobot.isRequired ? 'Required' : 'Optional',
                      style: TextStyle(
                        fontSize: isSmallCard ? 9 : 10,
                        fontWeight: FontWeight.w500,
                        color: courseRobot.isRequired 
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
