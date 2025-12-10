import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LessonSearchBar extends StatelessWidget {
  final String searchTerm;
  final Function(String) onSearchChanged;
  final VoidCallback onSearchPressed;
  final VoidCallback onClearPressed;

  const LessonSearchBar({
    super.key,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.onSearchPressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'lessons.searchHint'.tr(),
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (searchTerm.isNotEmpty)
            IconButton(
              onPressed: onClearPressed,
              icon: Icon(
                Icons.clear,
                color: Colors.grey[600],
                size: 20,
              ),
              tooltip: 'common.clearSearch'.tr(),
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: onSearchPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            child: Text(
              'common.search'.tr(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
