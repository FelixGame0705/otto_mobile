import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/models/course_model.dart';
import 'package:ottobit/services/course_service.dart';
import 'package:ottobit/screens/home/home_screen.dart';

class HomeHeroHeader extends StatefulWidget {
  final String greetingName;
  const HomeHeroHeader({super.key, required this.greetingName});

  @override
  State<HomeHeroHeader> createState() => _HomeHeroHeaderState();
}

class _HomeHeroHeaderState extends State<HomeHeroHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dx;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<Course> _results = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _dx = Tween<double>(begin: -60, end: 60).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.fromARGB(255, 0, 186, 74), Color.fromARGB(183, 21, 163, 73)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          // Centered moving robot background
          IgnorePointer(
            ignoring: true,
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _dx,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_dx.value, 0),
                    child: Align(
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          'assets/images/robot-4.png',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Foreground content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OttoBit', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Chào, ${widget.greetingName}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox.shrink(),
            ],
              ),
              const SizedBox(height: 12),
              Center(
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
                  borderRadius: BorderRadius.circular(56),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildSearchField(),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SearchResults(results: _results, onSelect: (course) {
                  Navigator.of(context).pushNamed(AppRoutes.courseDetail, arguments: {
                    'courseId': course.id,
                    'hideEnroll': false,
                  }).then((_) {
                    // Refresh cart count when returning from course detail
                    HomeScreen.refreshCartCount(context);
                  });
                }),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ChipTag(label: 'Basic'),
                  _ChipTag(label: 'Advanced'),
                  _ChipTag(label: 'Medium'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _SearchLogic on _HomeHeroHeaderState {
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocus,
      onChanged: (text) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 350), () async {
          final q = text.trim();
          if (q.length < 2) {
            if (mounted) setState(() => _results = []);
            return;
          }
          setState(() => _searching = true);
          try {
            final resp = await CourseService().getCourses(searchTerm: q, pageNumber: 1, pageSize: 5);
            if (!mounted) return;
            setState(() {
              _results = resp.data?.items ?? [];
              _searching = false;
            });
          } catch (_) {
            if (!mounted) return;
            setState(() {
              _results = [];
              _searching = false;
            });
          }
        });
      },
      decoration: InputDecoration(
        hintText: 'Nhập khóa học bạn muốn tìm',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : const Icon(Icons.search, color: Color(0xFF6B7280)),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<Course> results;
  final void Function(Course) onSelect;
  const _SearchResults({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final c = results[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.menu_book, color: Color(0xFF00BA4A)),
            title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: c.description.isNotEmpty
                ? Text(c.description, maxLines: 1, overflow: TextOverflow.ellipsis)
                : null,
            onTap: () => onSelect(c),
          );
        },
      ),
    );
  }
}

// old _SearchField removed after integrating live search

class _ChipTag extends StatelessWidget {
  final String label;
  const _ChipTag({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFF374151), fontSize: 12)),
    );
  }
}


