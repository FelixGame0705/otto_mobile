import 'package:flutter/material.dart';

class CourseActionButtons extends StatelessWidget {
  final VoidCallback? onEnroll;
  final VoidCallback? onShare;
  final bool isEnrolled;
  final bool isLoading;

  const CourseActionButtons({
    super.key,
    this.onEnroll,
    this.onShare,
    this.isEnrolled = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Share Button
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, size: 18),
              label: const Text(
                'Chia sẻ',
                style: TextStyle(fontSize: 14),
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
          
          // Enroll Button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onEnroll,
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
                      isEnrolled ? Icons.check : Icons.school,
                      size: 18,
                    ),
              label: Text(
                isLoading
                    ? 'Đang xử lý...'
                    : isEnrolled
                        ? 'Đã đăng ký'
                        : 'Đăng ký ngay',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnrolled
                    ? const Color(0xFF48BB78)
                    : const Color(0xFF4299E1),
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
    );
  }
}
