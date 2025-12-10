import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BlogSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilter;
  final bool filtersActive;

  const BlogSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilter,
    this.filtersActive = false,
  });

  @override
  State<BlogSearchBar> createState() => _BlogSearchBarState();
}

class _BlogSearchBarState extends State<BlogSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Keep suffixIcon (clear button) visibility in sync with text changes
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filter button
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: widget.onFilter,
            icon: Icon(
              Icons.tune,
              color:
                  widget.filtersActive ? Colors.white : const Color(0xFF17a64b),
            ),
            label: const SizedBox.shrink(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.filtersActive ? const Color(0xFF17a64b) : Colors.white,
              elevation: widget.filtersActive ? 2 : 0,
              side: BorderSide(
                color: widget.filtersActive
                    ? const Color(0xFF17a64b)
                    : const Color(0xFFE2E8F0),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Search field
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              widget.onSearch(value.trim());
            },
            decoration: InputDecoration(
              hintText: 'news.searchHint'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF17a64b)),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
