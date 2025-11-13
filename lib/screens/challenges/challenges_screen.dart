import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/challenge_model.dart';
import 'package:ottobit/services/challenge_service.dart';
// Removed ChallengeProcessService in favor of server-side best submissions API
import 'package:ottobit/screens/blockly/blockly_editor_screen.dart';
import 'package:ottobit/services/submission_service.dart';
import 'package:ottobit/widgets/ui/notifications.dart';

class ChallengesScreen extends StatefulWidget {
  final String lessonId;
  final String? courseId;
  final String? lessonTitle;
  final bool showBestStars; // Add flag to show best stars

  const ChallengesScreen({
    super.key,
    required this.lessonId,
    this.courseId,
    this.lessonTitle,
    this.showBestStars = false, // Default to false
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ChallengeService _service = ChallengeService();
  final SubmissionService _submissionService = SubmissionService();
  final ScrollController _scroll = ScrollController();

  List<Challenge> _items = [];
  Map<String, int> _challengeBestStars = {}; // Map challenge ID to best star
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
        _challengeBestStars.clear();
        _hasMore = true;
      }
    });
    try {
      // Load challenges
      final res = await _service.getChallenges(
        lessonId: widget.lessonId,
        courseId: widget.courseId,
        searchTerm: null,
        pageNumber: _page,
        pageSize: 10,
      );
      
      // Load best submissions by lesson (server-calculated best stars)
      Map<String, int> bestStars = {};
      try {
        final bestRes = await _submissionService.getBestSubmissionsByLesson(lessonId: widget.lessonId);
        for (final sub in bestRes.data) {
          bestStars[sub.challengeId] = sub.star;
        }
      } catch (e) {
        // Silent fail; keep UI working even if best submissions not available
        print('Failed to load best submissions: $e');
      }
      
      setState(() {
        final list = res.data?.items ?? [];
        if (refresh) {
          _items = list;
          _challengeBestStars = bestStars;
        } else {
          _items.addAll(list);
          _challengeBestStars.addAll(bestStars);
        }
        _totalPages = res.data?.totalPages ?? 1;
        _hasMore = _page < _totalPages;
        _loading = false;
      });
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _error = msg;
        _loading = false;
      });
      if (msg.isNotEmpty) {
        showErrorToast(context, msg);
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Không thể tải thử thách'),
          content: Text(
            msg.isNotEmpty ? msg : 'Đã xảy ra lỗi khi tải danh sách thử thách.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _page++;
    await _load();
    setState(() => _loadingMore = false);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
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
    final padH = w >= 900
        ? 24
        : w >= 600
        ? 20
        : 12;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.lessonTitle ?? 'challenges.title'.tr()),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _load(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.03),
              Colors.greenAccent.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.12)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: _loading
                    ? _ChallengesGridShimmer(cols: _cols(w, o), ratio: _ratio(w, o))
                    : _error.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 56),
                                const SizedBox(height: 12),
                                Text(_error, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _load(refresh: true),
                                  child: Text('common.retry'.tr()),
                                ),
                              ],
                            ),
                          )
        : _items.isEmpty
                            ? Center(child: Text('common.notFound'.tr()))
                            : ListView.separated(
                                controller: _scroll,
                                padding: EdgeInsets.symmetric(horizontal: padH.toDouble(), vertical: 8),
                                itemCount: _items.length + (_loadingMore ? 1 : 0) + (!_hasMore && _items.isNotEmpty ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  if (index == _items.length && _loadingMore) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (index == _items.length + (_loadingMore ? 1 : 0) && !_hasMore && _items.isNotEmpty) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Text('challenges.allShown'.tr(), style: TextStyle(color: Colors.grey[600])),
                                      ),
                                    );
                                  }
                                  if (index < _items.length) {
                                    final c = _items[index];
                                    final int? bestStar = _challengeBestStars[c.id];
                                    return _GameChallengeTile(
                                      challenge: c,
                                      bestStar: bestStar,
                                      onTap: () async {
                                        try {
                                          final detail = await _service.getChallengeDetail(c.id);
                                          if (!mounted) return;
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => BlocklyEditorScreen(
                                                initialMapJson: detail.mapJson,
                                                initialChallengeJson: {
                                                  ...?detail.challengeJson,
                                                  'id': detail.id,
                                                  'lessonId': detail.lessonId,
                                                  'order': detail.order,
                                                  // Prefer top-level API field; fallback to embedded JSON
                                                  'challengeMode': detail.challengeMode ?? (detail.challengeJson != null
                                                      ? (detail.challengeJson!['challengeMode'] ?? detail.challengeJson!['mode'] ?? 0)
                                                      : 0),
                                                },
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!mounted) return;
                                          final msg = e.toString().replaceFirst('Exception: ', '');
                                          showErrorToast(context, msg.isNotEmpty ? msg : 'Đã xảy ra lỗi khi mở thử thách.');
                                        }
                                      },
                                      index: index,
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengesGridShimmer extends StatelessWidget {
  final int cols;
  final double ratio;
  const _ChallengesGridShimmer({required this.cols, required this.ratio});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemBuilder: (context, index) => Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: 6,
    );
  }
}

class _GameChallengeTile extends StatelessWidget {
  final Challenge challenge;
  final int? bestStar;
  final VoidCallback onTap;
  final int index;
  const _GameChallengeTile({required this.challenge, required this.bestStar, required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    final Color accent = _palette(index);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.12), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            _BadgeSphere(color: accent, label: challenge.order.toString()),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ),
                      if (bestStar != null) _StarRow(stars: bestStar!.clamp(0, 3)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Pill(icon: Icons.speed, text: 'Lv ${challenge.difficulty}'),
                      const SizedBox(width: 8),
                      _Pill(icon: Icons.access_time, text: '${(challenge.order + 1) * 2}p'),
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

  Color _palette(int i) {
    const colors = [Color(0xFF58CC02), Color(0xFF1CB0F6), Color(0xFFFF4B4B), Color(0xFFFFB800), Color(0xFFA560E8)];
    return colors[i % colors.length];
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [Icon(icon, size: 14, color: const Color(0xFF6B7280)), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 12))]),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int stars;
  const _StarRow({required this.stars});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => Icon(i < stars ? Icons.star : Icons.star_border, size: 16, color: const Color(0xFFFFB800))),
    );
  }
}

class _BadgeSphere extends StatelessWidget {
  final Color color;
  final String label;
  const _BadgeSphere({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 2,
            child: Container(width: 40, height: 8, decoration: BoxDecoration(color: Colors.black.withOpacity(0.08), borderRadius: BorderRadius.circular(8))),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Colors.white, color.withOpacity(0.15)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
                BoxShadow(color: Colors.white.withOpacity(0.9), blurRadius: 2, offset: const Offset(-1, -1)),
              ],
            ),
            child: Center(
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
