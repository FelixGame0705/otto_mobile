import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final padding = EdgeInsets.all(isCompact ? 12 : 16);
        final titleStyle = TextStyle(
          fontSize: isCompact ? 16 : 18,
          fontWeight: FontWeight.bold,
        );
        final bodyStyle = TextStyle(fontSize: isCompact ? 13 : 14);
        const metaStyle = TextStyle(fontSize: 12, color: Colors.grey);

        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 16,
            vertical: isCompact ? 8 : 12,
          ),
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  course.title,
                  style: titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                SizedBox(height: isCompact ? 6 : 8),

                // Description
                Text(
                  course.description,
                  style: bodyStyle,
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isCompact ? 6 : 8),

                // Stats
                Text(
                  '${course.lessonsCount} ${'course.lessonsUnit'.tr()} • ${course.enrollmentsCount} ${'course.peopleUnit'.tr()}',
                  style: metaStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                SizedBox(height: isCompact ? 4 : 6),

                // Created by
                Text(
                  'course.createdBy'.tr(namedArgs: {'name': course.createdByName}),
                  style: metaStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
                SizedBox(height: isCompact ? 10 : 16),

                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onEnroll,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 10 : 14,
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: isCompact ? 16 : 20,
                            height: isCompact ? 16 : 20,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEnrolled
                                ? 'course.enrolled'.tr()
                                : 'course.enrollNow'.tr(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}