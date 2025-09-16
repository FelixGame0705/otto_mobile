import 'package:flutter/material.dart';
import 'package:otto_mobile/models/course_model.dart';
import 'package:otto_mobile/services/course_service.dart';
import 'package:otto_mobile/widgets/courses/course_search_bar.dart';
import 'package:otto_mobile/routes/app_routes.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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
    print('=== Loading Courses ===');
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
      print('Search term: $_searchTerm, Page: $_currentPage');
      final response = await _courseService.getCourses(
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
        pageNumber: _currentPage,
        pageSize: 10,
      );

      print('Response received: ${response.data?.items.length ?? 0} courses');
      print('Response data: ${response.data}');

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _courses = response.data?.items ?? [];
          } else {
            _courses.addAll(response.data?.items ?? []);
          }
          _totalPages = response.data?.totalPages ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });
        print('State updated with ${_courses.length} courses, Page: $_currentPage/$_totalPages');
      }
    } catch (e) {
      print('Error loading courses: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadCourses();

    setState(() {
      _isLoadingMore = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khóa học'),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => _loadCourses(isRefresh: true),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search Bar
        CourseSearchBar(
          searchTerm: _searchTerm,
          onSearchChanged: _handleSearchChanged,
          onSearchPressed: _handleSearch,
          onClearPressed: _handleClearSearch,
        ),
        
        const SizedBox(height: 16),
        
        // Content
        Flexible(
          child: _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
            ),
            SizedBox(height: 16),
            Text(
              'Đang tải khóa học...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCourses(isRefresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có khóa học nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Return GridView directly
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final orientation = mediaQuery.orientation;

    final int crossAxisCount = _calculateCrossAxisCount(screenWidth, orientation);
    final double childAspectRatio = _calculateChildAspectRatio(screenWidth, orientation);
    final EdgeInsets gridPadding = EdgeInsets.symmetric(
      horizontal: screenWidth >= 900
          ? 24
          : screenWidth >= 600
              ? 20
              : 12,
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
        // Loading More Indicator
        if (index == _courses.length && _isLoadingMore) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
              ),
            ),
          );
        }
        
        // End of List Indicator
        if (index == _courses.length + (_isLoadingMore ? 1 : 0) && !_hasMoreData && _courses.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Đã hiển thị tất cả khóa học',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        
        // Course Card
        if (index < _courses.length) {
          final course = _courses[index];
          return _buildCourseCard(course);
        }
        
        return const SizedBox.shrink();
      },
    );
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
    return orientation == Orientation.landscape ? 0.8 : 0.64;
  }

  Widget _buildCourseCard(Course course) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = MediaQuery.of(context).size.width >= 600;
        final double imageHeight = width * (isWide ? 0.6 : 0.58);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF4299E1).withOpacity(0.8),
                        const Color(0xFF667eea).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: course.imageUrl.isNotEmpty
                      ? Image.network(
                          course.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(height: imageHeight);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildPlaceholderImage(height: imageHeight);
                          },
                        )
                      : _buildPlaceholderImage(height: imageHeight),
                ),
              ),
              
              // Course Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Course Description
                    Text(
                      course.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Course Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatChip(
                            Icons.play_lesson,
                            '${course.lessonsCount}',
                            const Color(0xFF48BB78),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildStatChip(
                            Icons.people,
                            '${course.enrollmentsCount}',
                            const Color(0xFFED8936),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Enroll Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.courseDetail,
                            arguments: course.id,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4299E1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 1,
                        ),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderImage({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4299E1).withOpacity(0.8),
            const Color(0xFF667eea).withOpacity(0.8),
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 48,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Khóa học',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}