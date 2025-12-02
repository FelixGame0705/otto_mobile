import 'package:flutter/material.dart';
import 'package:ottobit/utils/api_error_handler.dart';

void showErrorToast(BuildContext context, String message) {
  final raw = message.trim();
  if (raw.isEmpty) return;

  // Nếu backend trả JSON (message, errorCode, ...) thì map sang tiếng Việt thân thiện,
  // còn nếu chỉ là chuỗi thường (đã được map trước đó) thì dùng nguyên văn, tránh lặp xử lý.
  final bool looksLikeJson =
      raw.startsWith('{') && (raw.endsWith('}') || raw.endsWith('}\n'));
  final friendly =
      looksLikeJson ? ApiErrorMapper.fromBody(raw, fallback: raw) : raw;

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
              friendly,
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


