import 'package:flutter/material.dart';
import 'package:otto_mobile/models/enrollment_model.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/services/enrollment_service.dart';

class MyEnrollmentsGrid extends StatefulWidget {
  const MyEnrollmentsGrid({super.key});

  @override
  State<MyEnrollmentsGrid> createState() => _MyEnrollmentsGridState();
}

class _MyEnrollmentsGridState extends State<MyEnrollmentsGrid> {
  final EnrollmentService _service = EnrollmentService();
  final ScrollController _scroll = ScrollController();
  List<Enrollment> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = '';
      if (refresh) {
        _page = 1;
        _items.clear();
        _hasMore = true;
      }
    });
    try {
      final res = await _service.getMyEnrollments(pageNumber: _page, pageSize: 10);
      setState(() {
        final list = res.items;
        if (refresh) {
          _items = list;
        } else {
          _items.addAll(list);
        }
        _totalPages = res.totalPages;
        _hasMore = _page < _totalPages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      if (!_loadingMore && _hasMore) {
        setState(() => _loadingMore = true);
        _page++;
        _load().then((_) => setState(() => _loadingMore = false));
      }
    }
  }

  int _cols(double w, Orientation o) {
    if (w >= 1200) return 5;
    if (w >= 900) return 4;
    if (w >= 600) return 3;
    return o == Orientation.landscape ? 3 : 2;
  }

  double _ratio(double w, Orientation o) {
    if (w >= 1200) return 0.8;
    if (w >= 900) return 0.76;
    if (w >= 600) return 0.7;
    return o == Orientation.landscape ? 0.82 : 0.7;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final o = mq.orientation;
    final padH = w >= 900 ? 24 : w >= 600 ? 20 : 12;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 56),
            const SizedBox(height: 8),
            Text(_error),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => _load(refresh: true), child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Bạn chưa đăng ký khóa học nào'));
    }

    return GridView.builder(
      controller: _scroll,
      padding: EdgeInsets.symmetric(horizontal: padH.toDouble(), vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _cols(w, o),
        childAspectRatio: _ratio(w, o),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length + (_loadingMore ? 1 : 0) + (!_hasMore && _items.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length && _loadingMore) {
          return const Center(child: CircularProgressIndicator());
        }
        if (index == _items.length + (_loadingMore ? 1 : 0) && !_hasMore && _items.isNotEmpty) {
          return Center(child: Text('Đã hiển thị tất cả'));
        }
        if (index < _items.length) {
          final e = _items[index];
          return _EnrollmentCard(enrollment: e);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _EnrollmentCard extends StatelessWidget {
  final Enrollment enrollment;
  const _EnrollmentCard({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.courseDetail,
            arguments: {
              'courseId': enrollment.courseId,
              'hideEnroll': true,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Image.network(
                  enrollment.courseImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.courseTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    enrollment.courseDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF718096), height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (enrollment.progress.clamp(0, 100)) / 100.0,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF4299E1),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiến độ: ${enrollment.progress}%', style: const TextStyle(fontSize: 12, color: Color(0xFF4A5568))),
                      if (enrollment.isCompleted)
                        const Icon(Icons.check_circle, color: Color(0xFF48BB78), size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


