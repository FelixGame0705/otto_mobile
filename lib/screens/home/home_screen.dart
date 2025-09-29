import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/widgets/enrolls/my_enrollments_grid.dart';
import 'package:ottobit/widgets/courses/explore_courses_tab.dart';
import 'package:ottobit/screens/store/store_screen.dart';

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

class _StoreTab extends StatelessWidget {
  const _StoreTab();

  @override
  Widget build(BuildContext context) {
    return const StoreScreen();
  }
}

