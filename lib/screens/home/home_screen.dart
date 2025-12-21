import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
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
import 'package:ottobit/widgets/news/news_tab.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

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
  late final NotchBottomBarController _notchController;

  // Aggregates kept for potential future appbar profile usage
  // Removed unused aggregates (can be restored when appbar profile returns)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _notchController = NotchBottomBarController(index: _currentIndex);
    _loadAppBarProfile();
    _loadCartCount();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _tabLoading = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notchController.dispose();
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
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        child: SafeArea(
          bottom: false,
          child: _tabLoading
              ? _TabShimmer(index: _currentIndex)
              : (_currentIndex == 0
                  ? const _MyCoursesTab()
                  : _currentIndex == 1
                      ? const _ExploreTab()
                  : _currentIndex == 2
                      ? const _NewsTab()
                  : _currentIndex == 3
                      ? const _StoreTab()
                      : const _ProfileTab()),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: AnimatedNotchBottomBar(
          notchBottomBarController: _notchController,
          color: Colors.white,
          showLabel: true,
          notchColor: const Color.fromARGB(255, 255, 255, 255),
          bottomBarItems: [
            BottomBarItem(
              inActiveItem: const Icon(Icons.library_books, color: Color(0xFFc0c7c2)),
              activeItem: const Icon(Icons.library_books, color: Color(0xFF1aad50)),
              // itemLabel: 'home.myCourses'.tr(),
            ),
            BottomBarItem(
              inActiveItem: const Icon(Icons.explore, color: Color(0xFFc0c7c2)),
              activeItem: const Icon(Icons.explore, color: Color(0xFF1aad50)),
              // itemLabel: 'home.explore'.tr(),
            ),
            BottomBarItem(
              inActiveItem: const Icon(Icons.article, color: Color(0xFFc0c7c2)),
              activeItem: const Icon(Icons.article, color: Color(0xFF1aad50)),
              // itemLabel: 'home.news'.tr(),
            ),
            BottomBarItem(
              inActiveItem: const Icon(Icons.storefront, color: Color(0xFFc0c7c2)),
              activeItem: const Icon(Icons.storefront, color: Color(0xFF1aad50)),
              // itemLabel: 'home.store'.tr(),
            ),
            BottomBarItem(
              inActiveItem: const Icon(Icons.person, color: Color(0xFFc0c7c2)),
              activeItem: const Icon(Icons.person, color: Color(0xFF1aad50)),
              // itemLabel: 'Profile',
            ),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _notchController.index = index;
              _tabLoading = true;
            });
            _loadCartCount(); // Refresh cart count on tab change
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _tabLoading = false);
            });
          },
          kIconSize: 24.0,
          kBottomRadius: 20.0,
        ),
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
    return const SafeArea(
      child: HomeDashboard(),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: ExploreCoursesTab(),
    );
  }
}

class _NewsTab extends StatelessWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: NewsTab(),
    );
  }
}

// removed in favor of ExploreCoursesTab

class _StoreTab extends StatelessWidget {
  const _StoreTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: StoreScreen(),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: ProfileScreen(),
    );
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
        return const _NewsTabShimmer();
      case 3:
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

class _NewsTabShimmer extends StatelessWidget {
  const _NewsTabShimmer();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blog cards shimmer
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

