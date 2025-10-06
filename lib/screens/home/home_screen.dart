import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/widgets/courses/explore_courses_tab.dart';
import 'package:ottobit/screens/store/store_screen.dart';
import 'package:ottobit/widgets/home/home_dashboard.dart';
import 'package:ottobit/services/enrollment_service.dart';
import 'package:ottobit/services/lesson_process_service.dart';
import 'package:ottobit/services/cart_service.dart';
import 'package:ottobit/screens/profile/profile_screen.dart';
import 'package:ottobit/screens/cart/cart_screen.dart';
import 'package:ottobit/widgets/home/home_shimmers.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static void refreshCartCount(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomeScreenState>();
    state?._loadCartCount();
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final EnrollmentService _enrollmentService = EnrollmentService();
  final LessonProcessService _lessonService = LessonProcessService();
  final CartService _cartService = CartService();
  bool _tabLoading = true;
  int _cartItemCount = 0;

  // Aggregates kept for potential future appbar profile usage
  // Removed unused aggregates (can be restored when appbar profile returns)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAppBarProfile();
    _loadCartCount();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _tabLoading = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadCartCount();
    }
  }

  Future<void> _loadAppBarProfile() async {
    try {
      await _enrollmentService.getMyEnrollments(pageSize: 10);
      await _lessonService.getMyProgress(pageSize: 10);
      if (!mounted) return;
    } catch (_) {
      // Keep silent in AppBar profile
    }
  }

  Future<void> _loadCartCount() async {
    try {
      final response = await _cartService.getCartSummary();
      if (mounted) {
        setState(() {
          _cartItemCount = response.data?.itemsCount ?? 0;
        });
      }
    } catch (_) {
      // Keep silent if cart fails to load
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
          child: _tabLoading
              ? _TabShimmer(index: _currentIndex)
              : (_currentIndex == 0
                  ? const _MyCoursesTab()
                  : _currentIndex == 1
                      ? const _ExploreTab()
              : _currentIndex == 2
                      ? const _StoreTab()
                      : const _ProfileTab()),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            _tabLoading = true;
          });
          _loadCartCount(); // Refresh cart count on tab change
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _tabLoading = false);
          });
        },
        selectedItemColor: const Color(0xFF4299E1),
        unselectedItemColor: const Color(0xFF718096),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.library_books), label: 'home.myCourses'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.explore), label: 'home.explore'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.storefront), label: 'home.store'.tr()),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _cartItemCount > 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(
                      onCartChanged: null, // Will be set by the static method
                    ),
                  ),
                ).then((_) {
                  // Refresh cart count when returning from cart
                  _loadCartCount();
                });
              },
              backgroundColor: const Color(0xFF48BB78),
              child: Stack(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  if (_cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _cartItemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
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

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

class _TabShimmer extends StatelessWidget {
  final int index;
  const _TabShimmer({required this.index});

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const Padding(
          padding: EdgeInsets.all(16),
          child: SectionShimmer(),
        );
      case 1:
        return const _ExploreTabShimmer();
      case 2:
        return const _StoreTabShimmer();
      default:
        return const _ProfileTabShimmer();
    }
  }
}

class _ExploreTabShimmer extends StatelessWidget {
  const _ExploreTabShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreTabShimmer extends StatelessWidget {
  const _StoreTabShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) => Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileTabShimmer extends StatelessWidget {
  const _ProfileTabShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }
}

