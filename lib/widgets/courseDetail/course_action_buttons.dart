import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/course_robot_model.dart';

class CourseActionButtons extends StatelessWidget {
  final VoidCallback? onEnroll;
  final VoidCallback? onAddToCart;
  final VoidCallback? onActivateRobot;
  final VoidCallback? onShare;
  final bool isEnrolled;
  final bool isLoading;
  final bool isPaid;
  final bool isInCart;
  final String? price;
  final CourseRobot? requiredRobot;
  final bool isLoadingRobot;

  const CourseActionButtons({
    super.key,
    this.onEnroll,
    this.onAddToCart,
    this.onActivateRobot,
    this.onShare,
    this.isEnrolled = false,
    this.isLoading = false,
    this.isPaid = false,
    this.isInCart = false,
    this.price,
    this.requiredRobot,
    this.isLoadingRobot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Price display for paid courses
          if (isPaid && price != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: Color(0xFF48BB78),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    price!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Required Robot Info for paid courses
          if (isPaid && requiredRobot != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0EA5E9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.smart_toy,
                        color: Color(0xFF0EA5E9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Robot cần thiết',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${requiredRobot!.robotName} (${requiredRobot!.robotBrand} - ${requiredRobot!.robotModel})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bạn cần có robot này để tham gia khóa học',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Loading robot info
          if (isPaid && isLoadingRobot) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Đang tải thông tin robot...'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Action buttons
          if (isPaid && onActivateRobot != null) ...[
            // For paid courses with robot activation
            Column(
              children: [
                // Robot Activation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onActivateRobot,
                    icon: const Icon(Icons.smart_toy, size: 18),
                    label: const Text(
                      'Kích hoạt Robot',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary buttons row
                Row(
                  children: [
                    // Share Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.share, size: 18),
                        label: Text(
                          'common.share'.tr(),
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4299E1),
                          side: const BorderSide(color: Color(0xFF4299E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add to Cart Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : onAddToCart,
                        icon: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                isInCart ? Icons.shopping_cart_checkout : Icons.shopping_cart,
                                size: 18,
                              ),
                        label: Text(
                          isLoading
                              ? 'cart.adding'.tr()
                              : isInCart ? 'cart.inCart'.tr() : 'cart.addToCart'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInCart ? const Color(0xFF48BB78) : const Color(0xFFED8936),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // For free courses or regular paid courses
            Row(
              children: [
                // Share Button
                Expanded(
                  flex: 1,
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(
                      'common.share'.tr(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4299E1),
                      side: const BorderSide(color: Color(0xFF4299E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Main Action Button (Enroll or Add to Cart)
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : (isPaid ? onAddToCart : onEnroll),
                    icon: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isPaid 
                                ? (isInCart ? Icons.shopping_cart_checkout : Icons.shopping_cart)
                                : (isEnrolled ? Icons.check : Icons.school),
                            size: 18,
                          ),
                    label: Text(
                      isLoading
                          ? (isPaid ? 'cart.adding'.tr() : 'course.enrolling'.tr())
                          : isPaid
                              ? (isInCart ? 'cart.inCart'.tr() : 'cart.addToCart'.tr())
                              : (isEnrolled ? 'course.enrolled'.tr() : 'Tham gia miễn phí'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaid
                          ? (isInCart ? const Color(0xFF48BB78) : const Color(0xFFED8936))
                          : (isEnrolled ? const Color(0xFF48BB78) : const Color(0xFF4299E1)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
