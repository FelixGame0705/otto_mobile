import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/widgets/courses/explore_courses_tab.dart';
import 'package:ottobit/screens/store/store_screen.dart';
import 'package:ottobit/widgets/home/home_dashboard.dart';
import 'package:ottobit/widgets/home/home_appbar_profile.dart';
import 'package:ottobit/services/enrollment_service.dart';
import 'package:ottobit/services/lesson_process_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final EnrollmentService _enrollmentService = EnrollmentService();
  final LessonProcessService _lessonService = LessonProcessService();

  String _fullName = 'Test User';
  int _totalCourses = 0;
  int _completedLessons = 0;
  int _inProgressLessons = 0;

  @override
  void initState() {
    super.initState();
    _loadAppBarProfile();
  }

  Future<void> _loadAppBarProfile() async {
    try {
      final enrolls = await _enrollmentService.getMyEnrollments(pageSize: 10);
      final progress = await _lessonService.getMyProgress(pageSize: 10);
      final items = ((progress['data']?['items']) as List?) ?? [];
      int done = 0;
      int doing = 0;
      for (final e in items) {
        final status = e['status'] as int?; // 3=completed, 2=in progress
        if (status == 3) done++;
        if (status == 2) doing++;
      }
      if (!mounted) return;
      setState(() {
        _totalCourses = enrolls.items.length;
        _completedLessons = done;
        _inProgressLessons = doing;
      });
    } catch (_) {
      // Keep silent in AppBar profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   toolbarHeight: 80,
      //   title: _currentIndex == 0
      //       ? HomeAppBarProfile(
      //           fullName: _fullName,
      //           totalCourses: _totalCourses,
      //           completedLessons: _completedLessons,
      //           inProgressLessons: _inProgressLessons,
      //         )
      //       : const Text('OttoBit'),
      //   backgroundColor: const Color(0xFF059669),
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   actions: [
      //     // IconButton(
      //     //   icon: const Icon(Icons.extension),
      //     //   tooltip: 'Blockly',
      //     //   onPressed: () => Navigator.pushNamed(context, AppRoutes.blockly),
      //     // ),
      //     // IconButton(
      //     //   icon: const Icon(Icons.videogame_asset),
      //     //   tooltip: 'Phaser',
      //     //   onPressed: () => Navigator.pushNamed(context, AppRoutes.phaser),
      //     // ),
      //     IconButton(
      //       icon: const Icon(Icons.person),
      //       onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
      //     ),
      //     IconButton(
      //       icon: const Icon(Icons.logout),
      //       onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
      //     ),
      //   ],
      // ),s
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 133, 255, 176), Color.fromARGB(255, 255, 255, 255)],
          ),
        ),
        child: SafeArea(
          child: _currentIndex == 0
              ? const _MyCoursesTab()
              : _currentIndex == 1
                  ? const _ExploreTab()
                  : const _StoreTab(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF4299E1),
        unselectedItemColor: const Color(0xFF718096),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.library_books), label: 'home.myCourses'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.explore), label: 'home.explore'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.storefront), label: 'home.store'.tr()),
        ],
      ),
    );
  }

  // removed unused _buildActionButton
}

class _MyCoursesTab extends StatelessWidget {
  const _MyCoursesTab();

  @override
  Widget build(BuildContext context) {
    return const HomeDashboard();
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return const ExploreCoursesTab();
  }
}

// removed in favor of ExploreCoursesTab

class _StoreTab extends StatelessWidget {
  const _StoreTab();

  @override
  Widget build(BuildContext context) {
    return const StoreScreen();
  }
}

