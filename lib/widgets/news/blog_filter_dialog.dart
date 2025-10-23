import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/blog_model.dart';

class BlogFilterDialog extends StatefulWidget {
  final List<BlogTag> tags;
  final String currentSortBy;
  final String currentSortDirection;
  final Function({
    String? tagId,
    String? sortBy,
    String? sortDirection,
  }) onApply;

  const BlogFilterDialog({
    super.key,
    required this.tags,
    required this.currentSortBy,
    required this.currentSortDirection,
    required this.onApply,
  });

  @override
  State<BlogFilterDialog> createState() => _BlogFilterDialogState();
}

class _BlogFilterDialogState extends State<BlogFilterDialog> {
  String? _selectedTagId;
  String _sortBy = 'updatedAt';
  String _sortDirection = 'desc';

  final List<Map<String, String>> _sortOptions = [
    {'value': 'updatedAt', 'label': 'news.sortByUpdated'},
    {'value': 'createdAt', 'label': 'news.sortByCreated'},
    {'value': 'title', 'label': 'news.sortByTitle'},
    {'value': 'viewCount', 'label': 'news.sortByViews'},
    {'value': 'readingTime', 'label': 'news.sortByReadingTime'},
  ];

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSortBy;
    _sortDirection = widget.currentSortDirection;
  }

  void _applyFilters() {
    widget.onApply(
      tagId: _selectedTagId,
      sortBy: _sortBy,
      sortDirection: _sortDirection,
    );
    Navigator.of(context).pop();
  }

  void _resetFilters() {
    setState(() {
      _selectedTagId = null;
      _sortBy = 'updatedAt';
      _sortDirection = 'desc';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('news.filter'.tr()),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag filter
            Text(
              'news.filterByTag'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // All tags option
            RadioListTile<String?>(
              title: Text('common.all'.tr()),
              value: null,
              groupValue: _selectedTagId,
              activeColor: const Color(0xFF17a64b),
              onChanged: (value) {
                setState(() {
                  _selectedTagId = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Individual tags
            ...widget.tags.map((tag) => RadioListTile<String?>(
              title: Text(tag.name),
              value: tag.id,
              groupValue: _selectedTagId,
              activeColor: const Color(0xFF17a64b),
              onChanged: (value) {
                setState(() {
                  _selectedTagId = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            )),
            
            const SizedBox(height: 16),
            
            // Sort by
            Text(
              'news.sortBy'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF17a64b)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF17a64b)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF17a64b)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _sortOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!.tr()),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Sort direction
            Text(
              'news.sortDirection'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('news.ascending'.tr()),
                    value: 'asc',
                    groupValue: _sortDirection,
                    activeColor: const Color(0xFF17a64b),
                    onChanged: (value) {
                      setState(() {
                        _sortDirection = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('news.descending'.tr()),
                    value: 'desc',
                    groupValue: _sortDirection,
                    activeColor: const Color(0xFF17a64b),
                    onChanged: (value) {
                      setState(() {
                        _sortDirection = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetFilters,
          child: Text('store.reset'.tr(), style: const TextStyle(color: Color(0xFF17a64b))),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _applyFilters,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF17a64b)),
          child: Text('store.apply'.tr(), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
