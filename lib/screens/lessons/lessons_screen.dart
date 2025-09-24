import 'package:flutter/material.dart';
import 'package:otto_mobile/models/lesson_model.dart';
import 'package:otto_mobile/services/lesson_service.dart';
import 'package:otto_mobile/services/lesson_detail_service.dart';
import 'package:otto_mobile/widgets/lessons/lesson_card.dart';
import 'package:otto_mobile/widgets/lessons/lesson_search_bar.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/widgets/ui/notifications.dart';

class LessonsScreen extends StatefulWidget {
  final String courseId;
  final String? courseTitle;

  const LessonsScreen({super.key, required this.courseId, this.courseTitle});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final LessonService _lessonService = LessonService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Lesson> _lessons = [];
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
    _loadLessons();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons({bool isRefresh = false}) async {
    print('=== Loading Lessons ===');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      if (isRefresh) {
        _currentPage = 1;
        _lessons.clear();
        _hasMoreData = true;
      }
    });

    try {
      print(
        'Search term: $_searchTerm, Page: $_currentPage, CourseId: ${widget.courseId}',
      );
      final response = await _lessonService.getLessons(
        courseId: widget.courseId,
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
        pageNumber: _currentPage,
        pageSize: 10,
      );

      print('Response received: ${response.data?.items.length ?? 0} lessons');
      print('Response data: ${response.data}');

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _lessons = response.data?.items ?? [];
          } else {
            _lessons.addAll(response.data?.items ?? []);
          }
          _totalPages = response.data?.totalPages ?? 1;
          _hasMoreData = _currentPage < _totalPages;
          _isLoading = false;
        });
        print(
          'State updated with ${_lessons.length} lessons, Page: $_currentPage/$_totalPages',
        );
      }
    } catch (e) {
      print('Error loading lessons: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
        if (_errorMessage.isNotEmpty) {
          showErrorToast(context, _errorMessage);
        }
      }
    }
  }

  Future<void> _loadMoreLessons() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadLessons();

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreLessons();
    }
  }

  void _handleSearch() {
    _searchTerm = _searchController.text.trim();
    _loadLessons(isRefresh: true);
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchTerm = value.trim();
    });
  }

  void _handleClearSearch() {
    _searchController.clear();
    _searchTerm = '';
    _loadLessons(isRefresh: true);
  }

  void _handleLessonTap(Lesson lesson) {
    _openLessonDetail(lesson.id);
  }

  Future<void> _openLessonDetail(String lessonId) async {
    try {
      // Probe access by fetching detail; backend will return USER_003 if blocked
      await LessonDetailService().getLessonDetail(lessonId);
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.lessonDetail, arguments: lessonId);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Không thể mở bài học'),
          content: Text(
            message.isNotEmpty
                ? message
                : 'Có lỗi không xác định xảy ra',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseTitle ?? 'Danh sách bài học'),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () => _loadLessons(isRefresh: true),
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
        child: SafeArea(child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Search Bar
        LessonSearchBar(
          searchTerm: _searchTerm,
          onSearchChanged: _handleSearchChanged,
          onSearchPressed: _handleSearch,
          onClearPressed: _handleClearSearch,
        ),

        const SizedBox(height: 16),

        // Inline error (top area)
        InlineErrorText(message: _errorMessage),

        // Content
        Flexible(child: _buildMainContent()),
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
              'Đang tải bài học...',
              style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
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
              onPressed: () => _loadLessons(isRefresh: true),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có bài học nào',
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

    final int crossAxisCount = _calculateCrossAxisCount(
      screenWidth,
      orientation,
    );
    final double childAspectRatio = _calculateChildAspectRatio(
      screenWidth,
      orientation,
    );
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
      itemCount:
          _lessons.length +
          (_isLoadingMore ? 1 : 0) +
          (!_hasMoreData && _lessons.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading More Indicator
        if (index == _lessons.length && _isLoadingMore) {
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
        if (index == _lessons.length + (_isLoadingMore ? 1 : 0) &&
            !_hasMoreData &&
            _lessons.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Đã hiển thị tất cả bài học',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Lesson Card
        if (index < _lessons.length) {
          final lesson = _lessons[index];
          return LessonCard(
            lesson: lesson,
            onTap: () => _handleLessonTap(lesson),
          );
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
    if (width >= 1200) return 0.75;
    if (width >= 900) return 0.72;
    if (width >= 600) return 0.68;
    return orientation == Orientation.landscape ? 0.78 : 0.68;
  }
}
