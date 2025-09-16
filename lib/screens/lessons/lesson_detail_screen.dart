import 'package:flutter/material.dart';
import 'package:otto_mobile/models/lesson_detail_model.dart';
import 'package:otto_mobile/services/lesson_detail_service.dart';
import 'package:otto_mobile/widgets/lessonDetail/lesson_detail_header.dart';
import 'package:otto_mobile/widgets/lessonDetail/lesson_content_section.dart';
import 'package:otto_mobile/widgets/lessonDetail/lesson_action_buttons.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final LessonDetailService _lessonDetailService = LessonDetailService();
  LessonDetail? _lessonDetail;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isStarting = false;

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
      final response = await _lessonDetailService.getLessonDetail(widget.lessonId);
      if (mounted) {
        setState(() {
          _lessonDetail = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _handleStartLesson() {
    setState(() {
      _isStarting = true;
    });
    
    // Simulate starting lesson
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bắt đầu học: ${_lessonDetail?.title}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Đang tải bài học...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF718096),
                    ),
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
                      Text('Lỗi: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLessonDetail,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _lessonDetail == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Không tìm thấy bài học',
                            style: TextStyle(
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
                            isStarting: _isStarting,
                            challengesCount: _lessonDetail!.challengesCount,
                          ),
                          
                          // Bottom padding for safe area
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
    );
  }
}
