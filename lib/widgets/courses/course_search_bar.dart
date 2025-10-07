import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CourseSearchBar extends StatelessWidget {
  final String searchTerm;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchPressed;
  final VoidCallback onClearPressed;

  const CourseSearchBar({
    super.key,
    required this.searchTerm,
    required this.onSearchChanged,
    required this.onSearchPressed,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearchChanged,
        onSubmitted: (_) => onSearchPressed(),
        decoration: InputDecoration(
          hintText: 'courses.searchHint'.tr(),
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 16,
          ),
          suffixIcon: searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color(0xFFA0AEC0),
                  ),
                  onPressed: onClearPressed,
                )
              : IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFF4299E1),
                  ),
                  onPressed: onSearchPressed,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF2D3748),
        ),
      ),
    );
  }
}
