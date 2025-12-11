import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:ottobit/models/course_model.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/screens/home/home_screen.dart';

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
        final minHeight = isCompact ? 180.0 : 200.0;
        final textBlockHeight = isCompact ? 90.0 : 110.0;
        final padding = EdgeInsets.all(isCompact ? 12 : 16);
        final titleStyle = TextStyle(
          fontSize: isCompact ? 18 : 20,
          fontWeight: FontWeight.bold,
        );
        final bodyStyle = TextStyle(fontSize: isCompact ? 15 : 16);
        const metaStyle = TextStyle(fontSize: 14, color: Colors.grey);

        return SizedBox(
          height: minHeight,
          child: Card(
            margin: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 16,
              vertical: isCompact ? 8 : 12,
            ),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Text content block with fixed height so bottom buttons align
                  SizedBox(
                    height: textBlockHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
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
                          'course.createdBy'
                              .tr(namedArgs: {'name': course.createdByName}),
                          style: metaStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isCompact ? 8 : 12),

                  // Bottom actions (fixed position block)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // View detail button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isCompact ? 6 : 8,
                            ),
                            foregroundColor: const Color(0xFF4299E1),
                          ),
                          child: Text(
                            'course.viewDetail'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 8),
                      // Enroll button
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
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Grid card variant for displaying courses in a grid layout
class CourseGridCard extends StatelessWidget {
  final Course course;

  const CourseGridCard({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 200;
        final padding = isNarrow ? 8.0 : 12.0;
        final titleFontSize = isNarrow ? 16.0 : 18.0;
        final descFontSize = isNarrow ? 13.0 : 14.0;
        final imageHeight = isNarrow ? 80.0 : 100.0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fixed image header
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: course.imageUrl.isNotEmpty
                      ? Image.network(
                          course.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                        )
                      : _ImagePlaceholder(),
                ),
              ),
              // Body with fixed button position
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Text + stats - use Expanded to occupy available space
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                course.title,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2D3748),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isNarrow ? 4 : 6),
                              Text(
                                course.description,
                                style: TextStyle(
                                  fontSize: descFontSize,
                                  color: const Color(0xFF718096),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isNarrow ? 6 : 8),
                              _PriceTag(price: course.price, type: course.type, isCompact: isNarrow),
                              SizedBox(height: isNarrow ? 6 : 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatChip(
                                          icon: Icons.play_lesson,
                                          text: '${course.lessonsCount}',
                                          color: const Color(0xFF48BB78),
                                          isCompact: isNarrow,
                                        ),
                                      ),
                                      SizedBox(width: isNarrow ? 2 : 4),
                                      Expanded(
                                        child: _StatChip(
                                          icon: Icons.people,
                                          text: '${course.enrollmentsCount}',
                                          color: const Color(0xFFED8936),
                                          isCompact: isNarrow,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isNarrow ? 2 : 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _StatChip(
                                          icon: Icons.star,
                                          text: course.ratingCount > 0
                                              ? course.ratingAverage.toStringAsFixed(1)
                                              : '0',
                                          color: const Color(0xFFF6AD55),
                                          isCompact: isNarrow,
                                        ),
                                      ),
                                      const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Button fixed at bottom of card body - always visible
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.courseDetail,
                              arguments: course.id,
                            ).then((_) {
                              // Refresh cart count when returning from course detail
                              HomeScreen.refreshCartCount(context);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: course.isEnrolled == true
                                ? const Color(0xFF48BB78)
                                : const Color(0xFF4299E1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isNarrow ? 6 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 1,
                          ),
                          child: Text(
                            course.isEnrolled == true
                                ? 'courses.continueLearning'.tr()
                                : 'common.viewDetails'.tr(),
                            style: TextStyle(
                              fontSize: isNarrow ? 13 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isCompact;

  const _StatChip({
    required this.icon,
    required this.text,
    required this.color,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 6,
        vertical: isCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 10 : 12, color: color),
          SizedBox(width: isCompact ? 2 : 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isCompact ? 11 : 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTag extends StatelessWidget {
  final int price;
  final int type; // 1 free, 2 paid
  final bool isCompact;

  const _PriceTag({
    required this.price,
    required this.type,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFree = price == 0 || type == 1;
    final TextStyle textStyle = TextStyle(
      fontSize: isCompact ? 13 : 14,
      fontWeight: FontWeight.w600,
      color: isFree ? const Color(0xFF48BB78) : const Color(0xFF2D3748),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isFree ? Icons.workspace_premium : Icons.attach_money,
          size: isCompact ? 12 : 14,
          color: isFree ? const Color(0xFF48BB78) : const Color(0xFF2D3748),
        ),
        SizedBox(width: isCompact ? 3 : 4),
        Flexible(
          child: Text(
            isFree ? 'common.free'.tr() : _formatVnd(price),
            style: textStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatVnd(int value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(value)} VNĐ';
  }
}