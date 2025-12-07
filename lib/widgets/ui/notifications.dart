import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/utils/api_error_handler.dart';

void showErrorToast(BuildContext context, String message) {
  final raw = message.trim();
  if (raw.isEmpty) return;

  // Detect current locale
  final isEnglish = context.locale.languageCode == 'en';
  
  // Kiểm tra xem message đã được xử lý chưa (không phải Exception object)
  // Nếu message không chứa "Exception:" và không phải JSON, thì đã được xử lý rồi
  String friendly;
  if (!raw.contains('Exception:') && !raw.startsWith('{')) {
    // Message đã được xử lý, chỉ cần loại bỏ duplicate nếu có
    friendly = raw;
  } else {
    // Message chưa được xử lý, xử lý qua fromException
    friendly = ApiErrorMapper.fromException(
      raw,
      isEnglish: isEnglish,
      fallback: raw,
    );
  }
  
  // Loại bỏ duplicate messages nếu có (tiếng Việt và tiếng Anh cùng lúc)
  final cleaned = _removeDuplicateMessages(friendly, isEnglish);

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade50,
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cleaned,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showSuccessToast(BuildContext context, String message) {
  if (message.trim().isEmpty) return;
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

class InlineErrorText extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry? padding;
  const InlineErrorText({super.key, required this.message, this.padding});

  @override
  Widget build(BuildContext context) {
    if (message.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to remove duplicate messages (Vietnamese and English together)
String _removeDuplicateMessages(String message, bool isEnglish) {
  // Nếu message chứa cả tiếng Việt và tiếng Anh, chỉ lấy phần phù hợp với locale
  if (message.contains('Đã xảy ra lỗi') && message.contains('An error occurred')) {
    if (isEnglish) {
      // Lấy phần tiếng Anh (từ "An error occurred" đến trước "Đã xảy ra lỗi")
      final englishStart = message.indexOf('An error occurred');
      final vietnameseStart = message.indexOf('Đã xảy ra lỗi', englishStart);
      if (englishStart >= 0) {
        if (vietnameseStart > englishStart) {
          return message.substring(englishStart, vietnameseStart).trim();
        }
        return message.substring(englishStart).trim();
      }
    } else {
      // Lấy phần tiếng Việt (từ "Đã xảy ra lỗi" đến trước "An error occurred")
      final vietnameseStart = message.indexOf('Đã xảy ra lỗi');
      final englishStart = message.indexOf('An error occurred', vietnameseStart);
      if (vietnameseStart >= 0) {
        if (englishStart > vietnameseStart) {
          return message.substring(vietnameseStart, englishStart).trim();
        }
        return message.substring(vietnameseStart).trim();
      }
    }
  }
  
  return message;
}


