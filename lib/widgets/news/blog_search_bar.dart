import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BlogSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilter;

  const BlogSearchBar({
    super.key,
    required this.onSearch,
    required this.onFilter,
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
        
        const SizedBox(width: 12),
        
        // Filter button
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF17a64b)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: IconButton(
            onPressed: widget.onFilter,
            icon: const Icon(Icons.filter_list, color: Color(0xFF17a64b)),
            tooltip: 'news.filter'.tr(),
          ),
        ),
      ],
    );
  }
}
