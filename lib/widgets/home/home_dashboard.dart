import 'package:flutter/material.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'package:ottobit/services/lesson_process_service.dart';
import 'package:ottobit/widgets/home/ongoing_lessons_list.dart';
import 'package:ottobit/widgets/home/ongoing_lessons_grid.dart';
import 'package:ottobit/widgets/home/completed_challenges_grid.dart';
import 'package:ottobit/widgets/home/completed_lessons_chart.dart';
import 'package:ottobit/widgets/home/home_shimmers.dart';
import 'package:ottobit/widgets/home/home_explore_grid.dart';
import 'package:ottobit/widgets/home/home_hero_header.dart';
import 'package:ottobit/widgets/home/home_stat_cards_row.dart';
import 'package:ottobit/widgets/home/learning_corner_grid.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final LessonProcessService _lessonProcessService = LessonProcessService();
  // Challenge completed API removed per requirements

  bool _loading = true;
  String? _error;
  // Enrollments removed
  List<OngoingLessonItem> _ongoingLessons = [];
  List<CompletedChallengeItem> _completedChallenges = [];

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
      // Enrollments call removed

      final lessonProgRaw = await _lessonProcessService.getMyProgress(pageSize: 10);
      final lessonItems = ((lessonProgRaw['data']?['items']) as List?) ?? [];
      _ongoingLessons = lessonItems
          .map((e) => OngoingLessonItem(
                title: (e['lessonTitle'] ?? '').toString(),
                currentChallenge: (e['currentChallengeOrder'] as int?) ?? 0,
                totalChallenges: (e['totalChallenges'] as int?) ?? 0,
                lessonId: (e['lessonId'] ?? '').toString(),
              ))
          .where((l) => l.totalChallenges == 0 || l.currentChallenge < l.totalChallenges)
          .toList();

      // Completed challenges listing via API is disabled

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

  @override
  Widget build(BuildContext context) {
    final fakeChartData = const [
      {'label': 'Mon', 'value': 1},
      {'label': 'Tue', 'value': 2},
      {'label': 'Wed', 'value': 0},
      {'label': 'Thu', 'value': 3},
      {'label': 'Fri', 'value': 2},
      {'label': 'Sat', 'value': 1},
      {'label': 'Sun', 'value': 0},
    ];

    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionShimmer(),
          SizedBox(height: 16),
          SectionShimmer(),
          SizedBox(height: 16),
          ShimmerBar(width: 160, height: 16),
          SizedBox(height: 12),
          ShimmerCard(height: 140),
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
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const HomeHeroHeader(greetingName: 'Test User'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HomeExploreGrid(),
                const SizedBox(height: 12),
                const HomeStatCardsRow(joined: 5000, quickCourseTitle: ''),
                const SizedBox(height: 16),
                _section('Bài học đang học'),
                // EnrollmentsProgressList(enrollments: _enrollments),
                OngoingLessonsGrid(lessons: _ongoingLessons),
                const SizedBox(height: 16),
                // _section('Ongoing Lessons'),
                // OngoingLessonsGrid(lessons: _ongoingLessons),
                const SizedBox(height: 16),
                _section('Completed Challenges'),
                CompletedChallengesGrid(challenges: _completedChallenges),
                const SizedBox(height: 16),
                _section('Completed Lessons Over Time'),
                CompletedLessonsChart(data: fakeChartData),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Góc vui học tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: const Text('Xem tất cả >')),
                  ],
                ),
                const LearningCornerGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}


