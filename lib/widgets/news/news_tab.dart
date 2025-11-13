import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/blog_model.dart';
import 'package:ottobit/services/blog_service.dart';
import 'package:ottobit/widgets/news/blog_card.dart';
import 'package:ottobit/widgets/news/blog_search_bar.dart';
import 'package:ottobit/widgets/news/blog_filter_dialog.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  final BlogService _blogService = BlogService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Blog> _blogs = [];
  List<BlogTag> _tags = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _searchTerm;
  String? _selectedTagId;
  String _sortBy = 'updatedAt';
  String _sortDirection = 'desc';

  bool get _filtersActive =>
      _selectedTagId != null ||
      _sortBy != 'updatedAt' ||
      _sortDirection != 'desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreBlogs();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      // Load tags first
      await _loadTags();
      
      // Load blogs
      await _loadBlogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('news.loadError'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTags() async {
    try {
      final response = await _blogService.getTags();
      if (mounted) {
        setState(() {
          _tags = response.data?.items ?? [];
        });
      }
    } catch (e) {
      print('Error loading tags: $e');
    }
  }

  Future<void> _loadBlogs() async {
    try {
      final response = await _blogService.getBlogs(
        searchTerm: _searchTerm,
        tagId: _selectedTagId,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
        pageNumber: _currentPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (_currentPage == 1) {
            _blogs = response.data?.items ?? [];
          } else {
            _blogs.addAll(response.data?.items ?? []);
          }
          _hasMore = _currentPage < (response.data?.totalPages ?? 0);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('news.loadError'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _loadMoreBlogs() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    await _loadBlogs();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onSearch(String searchTerm) async {
    setState(() {
      _searchTerm = searchTerm;
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadBlogs();
  }

  Future<void> _onFilter({
    String? tagId,
    String? sortBy,
    String? sortDirection,
  }) async {
    setState(() {
      _selectedTagId = tagId;
      _sortBy = sortBy ?? _sortBy;
      _sortDirection = sortDirection ?? _sortDirection;
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadBlogs();
  }

  void _onBlogTap(Blog blog) {
    Navigator.pushNamed(
      context,
      '/blog-detail',
      arguments: blog.slug,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: BlogFilterDrawer(
        tags: _tags,
        currentTagId: _selectedTagId,
        currentSortBy: _sortBy,
        currentSortDirection: _sortDirection,
        onApply: _onFilter,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                BlogSearchBar(
                  onSearch: _onSearch,
                  onFilter: _openFilterDrawer,
                  filtersActive: _filtersActive,
                ),
                const SizedBox(height: 8),
                // Tag filters
                if (_tags.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _tags.length + 1, // +1 for "All" option
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('common.all'.tr()),
                              selected: _selectedTagId == null,
                              selectedColor: const Color(0xFF17a64b).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF17a64b),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: _selectedTagId == null 
                                    ? const Color(0xFF17a64b) 
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  _onFilter(tagId: null);
                                }
                              },
                            ),
                          );
                        }
                        
                        final tag = _tags[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(tag.name),
                            selected: _selectedTagId == tag.id,
                            selectedColor: const Color(0xFF17a64b).withOpacity(0.2),
                            checkmarkColor: const Color(0xFF17a64b),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: _selectedTagId == tag.id 
                                  ? const Color(0xFF17a64b) 
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                _onFilter(tagId: tag.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          
          // Blog List
          Expanded(
            child: _blogs.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'news.empty'.tr(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'news.emptyMessage'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _blogs.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _blogs.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final blog = _blogs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BlogCard(
                            blog: blog,
                            onTap: () => _onBlogTap(blog),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openFilterDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }
}
