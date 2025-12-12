import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/lesson_detail_model.dart';
import 'package:ottobit/services/lesson_detail_service.dart';
import 'package:ottobit/services/enrollment_service.dart';
import 'package:ottobit/widgets/lessonDetail/lesson_detail_header.dart';
import 'package:ottobit/widgets/lessonDetail/lesson_content_section.dart';
import 'package:ottobit/widgets/lessonDetail/lesson_action_buttons.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final LessonDetailService _lessonDetailService = LessonDetailService();
  final EnrollmentService _enrollmentService = EnrollmentService();
  LessonDetail? _lessonDetail;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isStarting = false;
  bool _isCheckingEnrollment = false;
  bool? _isCourseEnrolled;
  String? _enrollmentError;

  @override
  void initState() {
    super.initState();
    _loadLessonDetail();
  }

  Future<void> _loadLessonDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _lessonDetailService.getLessonDetail(
        widget.lessonId,
      );
      if (mounted) {
        setState(() {
          _lessonDetail = response.data;
          _isLoading = false;
        });
        await _checkEnrollmentStatus();
      }
    } catch (e) {
      if (mounted) {
        final isEnglish = context.locale.languageCode == 'en';
        final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        setState(() {
          _errorMessage = friendly;
          _isLoading = false;
          _isCourseEnrolled = null;
          _enrollmentError = null;
        });
      }
    }
  }

  Future<void> _checkEnrollmentStatus() async {
    final lesson = _lessonDetail;
    if (lesson == null) return;
    setState(() {
      _isCheckingEnrollment = true;
      _enrollmentError = null;
      _isCourseEnrolled = null;
    });
    try {
      final enrolled = await _enrollmentService.isEnrolledInCourse(
        courseId: lesson.courseId,
      );
      if (!mounted) return;
      setState(() {
        _isCourseEnrolled = enrolled;
        _isCheckingEnrollment = false;
      });
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      setState(() {
        _isCourseEnrolled = false;
        _isCheckingEnrollment = false;
        _enrollmentError = friendly;
      });
    }
  }

  Future<void> _handleStartLesson() async {
    final isEnrolled = _isCourseEnrolled ?? false;
    if (!isEnrolled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lesson.enrollRequired'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
    });
    try {
      final msg = await _lessonDetailService.startLesson(widget.lessonId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green),
      );
      // Reload lesson detail in case counters/status changed
      await _loadLessonDetail();
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendly),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  void _handleViewChallenges() {
    if (_lessonDetail == null) return;
    Navigator.pushNamed(
      context,
      '/challenges',
      arguments: {
        'lessonId': _lessonDetail!.id,
        'courseId': _lessonDetail!.courseId,
        'lessonTitle': _lessonDetail!.title,
        'showBestStars': true, // Always show best stars from lesson detail
      },
    );
  }

  void _handleViewTheory() {
    if (_lessonDetail == null) return;
    Navigator.pushNamed(
      context,
      '/lesson-resources',
      arguments: {
        'lessonId': _lessonDetail!.id,
        'lessonTitle': _lessonDetail!.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4299E1),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'lesson.loading'.tr(),
                    style: const TextStyle(fontSize: 16, color: Color(0xFF718096)),
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${'common.error'.tr()}: $_errorMessage'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLessonDetail,
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            )
          : _lessonDetail == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'lesson.notFound'.tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Lesson Header
                  LessonDetailHeader(lesson: _lessonDetail!),

                  // Lesson Content
                  LessonContentSection(lesson: _lessonDetail!),

                  // Action Buttons
                  LessonActionButtons(
                    onStartLesson: _handleStartLesson,
                    onViewChallenges: _handleViewChallenges,
                    onViewTheory: _handleViewTheory,
                    isStarting: _isStarting,
                    challengeCount: _lessonDetail!.challengeCount,
                    canStartLesson:
                        !_isCheckingEnrollment && (_isCourseEnrolled ?? false),
                    isCheckingEnrollment: _isCheckingEnrollment,
                    lockedMessage: _enrollmentError,
                  ),

                  // Bottom padding for safe area
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
