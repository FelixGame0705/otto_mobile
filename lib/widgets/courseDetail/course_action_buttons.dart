import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CourseActionButtons extends StatelessWidget {
  final VoidCallback? onEnroll;
  final VoidCallback? onAddToCart;
  final VoidCallback? onShare;
  final bool isEnrolled;
  final bool isLoading;
  final bool isPaid;
  final bool isInCart;
  final String? price;

  const CourseActionButtons({
    super.key,
    this.onEnroll,
    this.onAddToCart,
    this.onShare,
    this.isEnrolled = false,
    this.isLoading = false,
    this.isPaid = false,
    this.isInCart = false,
    this.price,
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
          
          // Action buttons
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
                            : (isEnrolled ? 'course.enrolled'.tr() : 'course.enrollNow'.tr()),
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
      ),
    );
  }
}
