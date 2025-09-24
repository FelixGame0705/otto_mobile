import 'package:flutter/material.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/widgets/enrolls/my_enrollments_grid.dart';
import 'package:ottobit/widgets/courses/explore_courses_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OttoBit'),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.extension),
            tooltip: 'Blockly',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.blockly),
          ),
          IconButton(
            icon: const Icon(Icons.videogame_asset),
            tooltip: 'Phaser',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.phaser),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
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
          child: _currentIndex == 0 ? const _MyCoursesTab() : const _ExploreTab(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: const Color(0xFF4299E1),
        unselectedItemColor: const Color(0xFF718096),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Khóa học của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Khám phá'),
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
    return const MyEnrollmentsGrid();
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

