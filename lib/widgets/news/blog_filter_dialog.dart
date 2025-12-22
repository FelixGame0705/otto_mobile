import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/blog_model.dart';

class BlogFilterDrawer extends StatefulWidget {
  final List<BlogTag> tags;
  final List<String>? currentTagIds;
  final String currentSortBy;
  final String currentSortDirection;
  final void Function({
    List<String>? tagIds,
    String? sortBy,
    String? sortDirection,
  }) onApply;

  const BlogFilterDrawer({
    super.key,
    required this.tags,
    required this.currentTagIds,
    required this.currentSortBy,
    required this.currentSortDirection,
    required this.onApply,
  });

  @override
  State<BlogFilterDrawer> createState() => _BlogFilterDrawerState();
}

class _BlogFilterDrawerState extends State<BlogFilterDrawer> {
  Set<String> _selectedTagIds = {};
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
    _selectedTagIds = widget.currentTagIds != null ? Set<String>.from(widget.currentTagIds!) : {};
    _sortBy = widget.currentSortBy;
    _sortDirection = widget.currentSortDirection;
  }

  void _resetFilters() {
    setState(() {
      _selectedTagIds.clear();
      _sortBy = 'updatedAt';
      _sortDirection = 'desc';
    });
  }

  void _applyFilters() {
    widget.onApply(
      tagIds: _selectedTagIds.isNotEmpty ? _selectedTagIds.toList() : null,
      sortBy: _sortBy,
      sortDirection: _sortDirection,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF17a64b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, color: Color(0xFF17a64b)),
                    const SizedBox(width: 8),
                    Text(
                      'news.filter'.tr(),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF166534),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'news.filterByTag'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text('common.all'.tr()),
                    selected: _selectedTagIds.isEmpty,
                    onSelected: (_) => setState(() => _selectedTagIds.clear()),
                    selectedColor: const Color(0xFF17a64b).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _selectedTagIds.isEmpty
                          ? const Color(0xFF17a64b)
                          : const Color(0xFF2D3748),
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  ...widget.tags.map(
                    (tag) => ChoiceChip(
                      label: Text(tag.name),
                      selected: _selectedTagIds.contains(tag.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTagIds.add(tag.id);
                          } else {
                            _selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                      selectedColor: const Color(0xFF17a64b).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedTagIds.contains(tag.id)
                            ? const Color(0xFF17a64b)
                            : const Color(0xFF2D3748),
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'news.sortBy'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                value: _sortBy,
                items: _sortOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option['value'],
                        child: Text(option['label']!.tr()),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sortBy = value);
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF17a64b)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'news.sortDirection'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  RadioListTile<String>(
                    value: 'asc',
                    groupValue: _sortDirection,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortDirection = value);
                      }
                    },
                    title: Text('news.ascending'.tr()),
                    activeColor: const Color(0xFF17a64b),
                  ),
                  RadioListTile<String>(
                    value: 'desc',
                    groupValue: _sortDirection,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortDirection = value);
                      }
                    },
                    title: Text('news.descending'.tr()),
                    activeColor: const Color(0xFF17a64b),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetFilters,
                          icon: const Icon(Icons.refresh),
                          label: Text('store.reset'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF17a64b),
                            side: const BorderSide(color: Color(0xFF17a64b)),
                          ),
                        ),
                      ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.check),
                      label: Text('store.apply'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17a64b),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
