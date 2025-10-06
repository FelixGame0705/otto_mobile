import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/course_model.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/course_service.dart';
import 'package:ottobit/widgets/courses/course_search_bar.dart';
import 'package:ottobit/screens/home/home_screen.dart';

class ExploreCoursesTab extends StatefulWidget {
  const ExploreCoursesTab({super.key});

  @override
  State<ExploreCoursesTab> createState() => _ExploreCoursesTabState();
}

class _ExploreCoursesTabState extends State<ExploreCoursesTab> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Course> _courses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  String _searchTerm = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses({bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (isRefresh) {
        _currentPage = 1;
        _courses.clear();
        _hasMoreData = true;
      }
    });

    try {
      final response = await _courseService.getCourses(
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
        pageNumber: _currentPage,
        pageSize: 10,
      );

      if (!mounted) return;
      setState(() {
        final items = response.data?.items ?? [];
        if (isRefresh) {
          _courses = items;
        } else {
          _courses.addAll(items);
        }
        _totalPages = response.data?.totalPages ?? 1;
        _hasMoreData = _currentPage < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadCourses();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCourses();
    }
  }

  void _handleSearch() {
    _searchTerm = _searchController.text.trim();
    _loadCourses(isRefresh: true);
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchTerm = value.trim();
    });
  }

  void _handleClearSearch() {
    _searchController.clear();
    _searchTerm = '';
    _loadCourses(isRefresh: true);
  }

  int _calculateCrossAxisCount(double width, Orientation orientation) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return orientation == Orientation.landscape ? 3 : 2;
  }

  double _calculateChildAspectRatio(double width, Orientation orientation) {
    if (width >= 1200) return 0.8;
    if (width >= 900) return 0.72;
    if (width >= 600) return 0.78;
    return orientation == Orientation.landscape ? 0.7 : 0.54;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseSearchBar(
          searchTerm: _searchTerm,
          onSearchChanged: _handleSearchChanged,
          onSearchPressed: _handleSearch,
          onClearPressed: _handleClearSearch,
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('${'common.error'.tr()}: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCourses(isRefresh: true),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('common.notFound'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final orientation = mediaQuery.orientation;
    final int crossAxisCount = _calculateCrossAxisCount(screenWidth, orientation);
    final double childAspectRatio = _calculateChildAspectRatio(screenWidth, orientation);
    final EdgeInsets gridPadding = EdgeInsets.symmetric(
      horizontal: screenWidth >= 900 ? 24 : screenWidth >= 600 ? 20 : 12,
    );

    return GridView.builder(
      controller: _scrollController,
      padding: gridPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _courses.length + (_isLoadingMore ? 1 : 0) + (!_hasMoreData && _courses.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _courses.length && _isLoadingMore) {
          return const Center(child: CircularProgressIndicator());
        }
        if (index == _courses.length + (_isLoadingMore ? 1 : 0) && !_hasMoreData && _courses.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('courses.allShown'.tr(), style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
            ),
          );
        }
        if (index < _courses.length) {
          final course = _courses[index];
          return _CourseCard(course: course);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: course.imageUrl.isNotEmpty
                  ? Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text(course.description, style: const TextStyle(fontSize: 12, color: Color(0xFF718096), height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStatChip(Icons.play_lesson, '${course.lessonsCount}', const Color(0xFF48BB78))),
                    const SizedBox(width: 4),
                    Expanded(child: _buildStatChip(Icons.people, '${course.enrollmentsCount}', const Color(0xFFED8936))),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.courseDetail, arguments: course.id).then((_) {
                        // Refresh cart count when returning from course detail
                        HomeScreen.refreshCartCount(context);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4299E1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 1,
                    ),
                    child: Text('common.viewDetails'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _placeholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.image_not_supported)),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}


