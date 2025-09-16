import 'package:flutter/material.dart';
import 'package:otto_mobile/layout/app_scaffold.dart';
import 'package:otto_mobile/models/course_detail_model.dart';
import 'package:otto_mobile/services/course_detail_service.dart';
import 'package:otto_mobile/widgets/courseDetail/course_detail_header.dart';
import 'package:otto_mobile/widgets/courseDetail/course_info_section.dart';
import 'package:otto_mobile/widgets/courseDetail/course_action_buttons.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/services/enrollment_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final bool hideEnroll;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.hideEnroll = false,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseDetailService _courseDetailService = CourseDetailService();

  CourseDetail? _course;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isEnrolled = false;
  bool _isEnrolling = false;

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
  }

  Future<void> _loadCourseDetail() async {
    print('=== Loading Course Detail ===');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('Course ID: ${widget.courseId}');
      final response = await _courseDetailService.getCourseDetail(widget.courseId);

      print('Response received: ${response.data?.title ?? 'No data'}');
      print('Response data: ${response.data}');

      if (mounted) {
        setState(() {
          _course = response.data;
          _isLoading = false;
        });
        print('State updated with course: ${_course?.title}');
      }
    } catch (e) {
      print('Error loading course detail: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleEnroll() async {
    if (_course == null) return;

    setState(() {
      _isEnrolling = true;
    });

    try {
      final resp = await EnrollmentService().enroll(courseId: widget.courseId);
      if (!mounted) return;
      setState(() {
        _isEnrolled = true;
        _isEnrolling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resp.message.isNotEmpty ? resp.message : 'Đăng ký khóa học thành công!'),
          backgroundColor: const Color(0xFF48BB78),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isEnrolling = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleShare() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng chia sẻ sẽ được cập nhật sớm!'),
        backgroundColor: Color(0xFF4299E1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Chi tiết khóa học',
      showAppBar: false, // We'll use custom header
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
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
              'Đang tải thông tin khóa học...',
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Có lỗi xảy ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCourseDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_course == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy khóa học',
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

    return SingleChildScrollView(
      child: Column(
        children: [
          // Course Header
          CourseDetailHeader(course: _course!),
          
          // Course Info
          CourseInfoSection(course: _course!),
          
          // Action Buttons
          if (!widget.hideEnroll)
            CourseActionButtons(
              onEnroll: _handleEnroll,
              onShare: _handleShare,
              isEnrolled: _isEnrolled,
              isLoading: _isEnrolling,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Chia sẻ'),
                ),
              ),
            ),
          
          // Lessons Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.lessons,
                    arguments: {
                      'courseId': widget.courseId,
                      'courseTitle': _course?.title,
                    },
                  );
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Xem danh sách bài học'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF48BB78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
