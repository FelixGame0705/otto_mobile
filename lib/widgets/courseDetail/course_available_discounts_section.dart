import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/course_available_discount_model.dart';
import 'package:ottobit/routes/app_routes.dart';

class CourseAvailableDiscountsSection extends StatelessWidget {
  final List<CourseAvailableDiscount> discounts;

  const CourseAvailableDiscountsSection({
    super.key,
    required this.discounts,
  });

  @override
  Widget build(BuildContext context) {
    if (discounts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cart.availableTitle'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'cart.availableSubtitle'.tr(),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: discounts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final discount = discounts[index];
              final alreadyOwned = discount.userOwnsRequiredCourse || discount.userEnrolledRequiredCourse;
              final inCart = discount.requiredCourseInCart;
              String statusText;
              Color statusColor;
              if (alreadyOwned) {
                statusText = 'cart.prereqOwned'.tr();
                statusColor = const Color(0xFF10B981);
              } else if (inCart) {
                statusText = 'cart.prereqInCart'.tr();
                statusColor = const Color(0xFF6366F1);
              } else {
                statusText = 'cart.prereqNotOwned'.tr();
                statusColor = Colors.orange;
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          discount.requiredCourseImageUrl,
                          width: 88,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 88,
                            height: 56,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              discount.requiredCourseTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  discount.formattedDiscountedPrice,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  discount.formattedOriginalPrice,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${'cart.discountAmount'.tr()}: -${discount.formattedDiscountAmount}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.courseDetail,
                                  arguments: {'courseId': discount.requiredCourseId},
                                );
                              },
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              label: Text('cart.viewCourse'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

