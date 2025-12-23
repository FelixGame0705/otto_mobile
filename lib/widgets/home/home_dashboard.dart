import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'package:ottobit/widgets/home/home_shimmers.dart';
import 'package:ottobit/services/lesson_process_service.dart';
import 'package:ottobit/services/learning_path_controller.dart';
import 'package:ottobit/widgets/home/course_selector.dart';
import 'package:ottobit/widgets/home/learning_path.dart';
import 'package:ottobit/screens/support/ai_support_screen.dart';
import 'package:ottobit/services/enrollment_service.dart';
import 'package:ottobit/models/enrollment_model.dart';
import 'package:ottobit/models/lesson_model.dart';
import 'package:ottobit/models/lesson_resource_model.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _loading = true;
  String? _error;

  // Learning path state
  final EnrollmentService _enrollmentService = EnrollmentService();
  final LearningPathController _pathController = LearningPathController();
  List<Enrollment> _enrollments = [];
  String? _selectedCourseId;
  List<Lesson> _lessons = [];
  final Map<String, List<LessonResourceItem>> _lessonIdToResources = {};
  // Progress for locking
  final Set<String> _completedLessonIds = <String>{};
  int? _currentLessonOrder;

  // Filter state: only show in-progress enrollments (IsCompleted = false)
  bool _inProgressOnly = false;

  // Draggable button position
  double _buttonX = 16.0;
  double _buttonY = 96.0; // Initial position above bottom bar (80px bar + 16px padding)

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Load enrollments for course selector
      try {
        final enrollRes = await _enrollmentService.getMyEnrollments(
          pageSize: 20,
          isCompleted: _inProgressOnly ? false : null,
        );
        _enrollments = enrollRes.items;
        if (_enrollments.isNotEmpty) {
          _selectedCourseId ??= _enrollments.first.courseId;
        }
      } catch (e) {
        // If enrollment API fails, continue with other sections
        _enrollments = [];
      }

      // Load learning path data for selected course
      if (_selectedCourseId != null && _selectedCourseId!.isNotEmpty) {
        _lessons = await _pathController.loadLessons(_selectedCourseId!);
        _lessonIdToResources.clear();
        for (final l in _lessons) {
          try {
            final res = await _pathController.loadLessonResourcesPreview(l.id, limit: 3);
            _lessonIdToResources[l.id] = res;
          } catch (_) {
            _lessonIdToResources[l.id] = const <LessonResourceItem>[];
          }
        }

        // Load progress to determine locking
        _completedLessonIds.clear();
        _currentLessonOrder = null;
        try {
          final lessonProgRaw = await LessonProcessService().getMyProgress(pageSize: 100, courseId: _selectedCourseId);
          final lessonItems = ((lessonProgRaw['data']?['items']) as List?) ?? [];
          // Compute completed from API status/ratio
          final Set<String> seenLessonIds = {};
          for (final e in lessonItems) {
            final String lessonId = (e['lessonId'] ?? '').toString();
            final int current = (e['currentChallengeOrder'] as int?) ?? 0;
            final int total = (e['totalChallenges'] as int?) ?? 0;
            seenLessonIds.add(lessonId);
            if (lessonId.isNotEmpty && total > 0 && current >= total) {
              _completedLessonIds.add(lessonId);
            }
          }

          // Determine current: the first lesson in this course that is not completed
          final sorted = [..._lessons]..sort((a, b) => a.order.compareTo(b.order));
          _currentLessonOrder = null;
          for (final l in sorted) {
            if (!_completedLessonIds.contains(l.id)) {
              _currentLessonOrder = l.order;
              break;
            }
          }
          // If API only returns available lessons, ensure lock for not-seen lessons beyond available
          if (_currentLessonOrder == null && sorted.isNotEmpty) {
            _currentLessonOrder = sorted.first.order;
          }
        } catch (_) {
          // ignore progress errors; default mapping applies in widget
        }
      } else {
        _lessons = [];
        _lessonIdToResources.clear();
        _completedLessonIds.clear();
        _currentLessonOrder = null;
      }

      // Completed challenges section removed per new UX

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiErrorMapper.toFriendlyMessage(null, fallback: e.toString());
        _loading = false;
      });
    }
  }

  Future<void> _onSelectCourse(String courseId) async {
    setState(() => _selectedCourseId = courseId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionShimmer(),
        ],
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: Text('common.retry'.tr())),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'home.learningPath'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  FilterChip(
                    label: Text('common.inProgress'.tr()),
                    selected: _inProgressOnly,
                    onSelected: (value) {
                      setState(() {
                        _inProgressOnly = value;
                        // Reset selected course when filter changes to avoid pointing to non-existing course
                        _selectedCourseId = null;
                      });
                      _load();
                    },
                    selectedColor: const Color(0xFF17a64b).withOpacity(0.15),
                    checkmarkColor: const Color(0xFF17a64b),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CourseSelector(
                enrollments: _enrollments,
                selectedCourseId: _selectedCourseId,
                onSelect: (e) => _onSelectCourse(e.courseId),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(148, 76, 175, 79).withOpacity(0.06),
                      const Color.fromARGB(134, 105, 240, 175).withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.15)),
                ),
                child: _selectedCourseId == null || _selectedCourseId!.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Text('home.selectCourseMessage'.tr()),
                          const SizedBox(height: 8),
                        ],
                      )
                    : LearningPath(
                        lessons: _lessons,
                        lessonResources: _lessonIdToResources,
                        courseId: _selectedCourseId!,
                        completedLessonIds: _completedLessonIds,
                        currentLessonOrder: _currentLessonOrder,
                      ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: _buttonY,
          left: _buttonX,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final screenWidth = MediaQuery.of(context).size.width;
                final buttonWidth = 150.0; // Approximate width of extended FAB
                final bottomBarHeight = 10.0; // Height of bottom navigation bar
                
                // Update position
                _buttonX += details.delta.dx;
                _buttonY -= details.delta.dy; // Subtract because bottom positioning is inverted
                
                // Constrain to screen bounds
                // For X: keep button within screen width
                _buttonX = _buttonX.clamp(0.0, screenWidth - buttonWidth);
                // For Y: keep button above bottom bar (min) and below top safe area (max)
                // bottom: 0 = at bottom, larger value = higher up
                _buttonY = _buttonY.clamp(bottomBarHeight + 16, double.infinity);
              });
            },
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiSupportScreen()),
                );
              },
              icon: const Icon(Icons.smart_toy, color: Colors.white),
              label: Text('home.aiSupport'.tr(), style: const TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF17a64b),
            ),
          ),
        ),
      ],
    );
  }
}


