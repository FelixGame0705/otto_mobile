import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:ottobit/models/lesson_model.dart';
import 'package:ottobit/services/lesson_service.dart';
import 'package:ottobit/services/lesson_detail_service.dart';
import 'package:ottobit/widgets/lessons/lesson_card.dart';
import 'package:ottobit/widgets/lessons/lesson_search_bar.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/widgets/ui/notifications.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'package:ottobit/widgets/common/student_required_dialog.dart';

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
     
      // Đảm bảo _searchTerm được sync với _searchController
      final finalSearchTerm = _searchTerm.trim().isNotEmpty 
          ? _searchTerm.trim() 
          : (_searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null);
      
      
      final response = await _lessonService.getLessons(
        courseId: widget.courseId,
        searchTerm: finalSearchTerm,
        pageNumber: _currentPage,
        pageSize: 10,
      );


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
        final isEnglish = context.locale.languageCode == 'en';
        final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        setState(() {
          _errorMessage = friendly;
          _isLoading = false;
        });
        if (_isStudentMissing(_errorMessage)) {
          await StudentRequiredDialog.show(context);
        } else if (_errorMessage.isNotEmpty) {
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
    // Lấy giá trị từ _searchTerm vì nó đã được cập nhật qua onSearchChanged
    // Hoặc từ _searchController nếu _searchTerm chưa được cập nhật
    final searchValue = _searchTerm.trim().isNotEmpty 
        ? _searchTerm.trim() 
        : _searchController.text.trim();
    _searchTerm = searchValue;
    debugPrint('=== LessonsScreen: _handleSearch() ===');
    debugPrint('LessonsScreen: _searchTerm after search: "$_searchTerm"');
    debugPrint('LessonsScreen: _searchController.text: "${_searchController.text}"');
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
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      final message = friendly.isNotEmpty ? friendly : 'lesson.unknownError'.tr();

      if (_isStudentMissing(message)) {
        await StudentRequiredDialog.show(context);
        return;
      }

      // Nếu lỗi yêu cầu hoàn thành bài học trước, chỉ hiển thị toast (dùng message đã được map)
      final lowerMsg = message.toLowerCase();
      if (lowerMsg.contains('previous lessons must be completed first') ||
          lowerMsg.contains('bài học trước đó') ||
          lowerMsg.contains('hoàn thành các bài học trước')) {
        showErrorToast(context, message);
        return;
      }

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('lesson.cannotOpen'.tr()),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('common.close'.tr()),
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
        title: Text(widget.courseTitle ?? 'lessons.title'.tr()),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'lesson.refresh'.tr(),
            onPressed: () => _loadLessons(isRefresh: true),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
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
          controller: _searchController,
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
            ),
            const SizedBox(height: 16),
            Text(
              'lessons.loading'.tr(),
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
            Text('${'common.error'.tr()}: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadLessons(isRefresh: true),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'lessons.empty'.tr(),
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
                'lessons.allShown'.tr(),
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

  bool _isStudentMissing(String message) {
    final lower = message.toLowerCase();
    return lower.contains('student not found') ||
        lower.contains('no student found') ||
        lower.contains('student profile not found') ||
        lower.contains('không tìm thấy học sinh') ||
        lower.contains('chưa là học viên') ||
        lower.contains('vui lòng đăng ký học viên');
  }
}
