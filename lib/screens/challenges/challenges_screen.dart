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

  List<Challenge> _items = [];
  Map<String, int> _challengeBestStars = {}; // Map challenge ID to best star
  Set<String> _unlockedChallengeIds = {}; // Set of unlocked challenge IDs
  bool _loading = true;
  String _error = '';
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible again (user returns from blockly)
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      final now = DateTime.now();
      // Only refresh if last refresh was more than 1 second ago (avoid multiple refreshes)
      if (_lastRefreshTime == null || 
          now.difference(_lastRefreshTime!).inSeconds > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _load(refresh: true);
            _lastRefreshTime = DateTime.now();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = '';
      if (refresh) {
        _items.clear();
        _challengeBestStars.clear();
      }
    });
    try {
      // Load challenges (100 items at once, no pagination needed)
      final res = await _service.getChallenges(
        lessonId: widget.lessonId,
        courseId: widget.courseId,
        searchTerm: null,
        pageNumber: 1,
        pageSize: 100,
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
        
        // Calculate unlocked challenges based on best submissions
        final unlockedIds = _calculateUnlockedChallenges(list, bestStars);
          _items = list;
          _challengeBestStars = bestStars;
          _unlockedChallengeIds = unlockedIds;
          _lastRefreshTime = DateTime.now();
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


  /// Calculate which challenges should be unlocked based on best submissions
  /// Rules:
  /// - First challenge (order = 1) is always unlocked
  /// - Challenges that have been submitted are unlocked
  /// - The next challenge after the highest submitted challenge is unlocked
  Set<String> _calculateUnlockedChallenges(List<Challenge> challenges, Map<String, int> bestStars) {
    final unlockedIds = <String>{};
    
    if (challenges.isEmpty) return unlockedIds;
    
    // Sort challenges by order
    final sortedChallenges = List<Challenge>.from(challenges)..sort((a, b) => a.order.compareTo(b.order));
    
    // First challenge is always unlocked
    if (sortedChallenges.isNotEmpty) {
      unlockedIds.add(sortedChallenges.first.id);
    }
    
    // Find the highest order challenge that has been submitted
    int highestSubmittedOrder = 0;
    for (final challenge in sortedChallenges) {
      if (bestStars.containsKey(challenge.id)) {
        unlockedIds.add(challenge.id);
        if (challenge.order > highestSubmittedOrder) {
          highestSubmittedOrder = challenge.order;
        }
      }
    }
    
    // Unlock the next challenge after the highest submitted one
    if (highestSubmittedOrder > 0) {
      final nextOrder = highestSubmittedOrder + 1;
      final nextChallenge = sortedChallenges.firstWhere(
        (c) => c.order == nextOrder,
        orElse: () => sortedChallenges.first,
      );
      if (nextChallenge.order == nextOrder) {
        unlockedIds.add(nextChallenge.id);
      }
    }
    
    return unlockedIds;
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
                                padding: EdgeInsets.symmetric(horizontal: padH.toDouble(), vertical: 8),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                    final c = _items[index];
                                    final int? bestStar = _challengeBestStars[c.id];
                                    final bool isUnlocked = _unlockedChallengeIds.contains(c.id);
                                    return _GameChallengeTile(
                                      challenge: c,
                                      bestStar: bestStar,
                                      isUnlocked: isUnlocked,
                                      onTap: isUnlocked ? () async {
                                        try {
                                          final detail = await _service.getChallengeDetail(c.id);
                                          if (!mounted) return;
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => BlocklyEditorScreen(
                                                initialMapJson: detail.mapJson,
                                                initialChallengeJson: {
                                                  ...?detail.challengeJson,
                                                  'id': detail.id,
                                                  'lessonId': detail.lessonId,
                                                  'order': detail.order,
                                                  'courseId': widget.courseId,
                                                  // Prefer top-level API field; fallback to embedded JSON
                                                  'challengeMode': detail.challengeMode ?? (detail.challengeJson != null
                                                      ? (detail.challengeJson!['challengeMode'] ?? detail.challengeJson!['mode'] ?? 0)
                                                      : 0),
                                                  // Prefer top-level API field; fallback to embedded JSON
                                                  'challengeType': detail.challengeType ?? (detail.challengeJson != null
                                                      ? detail.challengeJson!['challengeType']
                                                      : null),
                                                },
                                              ),
                                            ),
                                          );
                                          
                                          // Refresh when returning from blockly screen
                                          if (mounted) {
                                            print('🔄 Refreshing challenges after returning from blockly');
                                            _load(refresh: true);
                                          }
                                        } catch (e) {
                                          if (!mounted) return;
                                          final msg = e.toString().replaceFirst('Exception: ', '');
                                          showErrorToast(context, msg.isNotEmpty ? msg : 'Đã xảy ra lỗi khi mở thử thách.');
                                        }
                                      } : null,
                                      index: index,
                                    );
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
  final VoidCallback? onTap;
  final bool isUnlocked;
  final int index;
  const _GameChallengeTile({
    required this.challenge, 
    required this.bestStar, 
    required this.onTap, 
    required this.isUnlocked,
    required this.index
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = _palette(index);
    final bool isLocked = !isUnlocked;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Container(
          height: 96,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLocked 
                  ? Colors.grey.withOpacity(0.3) 
                  : accent.withOpacity(0.2), 
              width: 1.5
            ),
            boxShadow: isLocked 
                ? []
                : [
                    BoxShadow(
                      color: accent.withOpacity(0.12), 
                      blurRadius: 14, 
                      offset: const Offset(0, 6)
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  _BadgeSphere(
                    color: isLocked ? Colors.grey : accent, 
                    label: challenge.order.toString()
                  ),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w800, 
                                  fontSize: 16,
                                  color: isLocked ? Colors.grey : null,
                                ),
                              ),
                            ),
                            if (bestStar != null) _StarRow(stars: bestStar!.clamp(0, 3)),
                            if (isLocked) 
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(Icons.lock, size: 16, color: Colors.grey),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Pill(icon: Icons.speed, text: 'Lv ${challenge.difficulty}'),
                            const SizedBox(width: 8),
                            _Pill(icon: Icons.access_time, text: '${(challenge.order + 1) * 2}p'),
                            if (challenge.challengeMode != null) ...[
                              const SizedBox(width: 8),
                              _Pill(
                                icon: challenge.challengeMode == 0 ? Icons.computer : Icons.usb,
                                text: challenge.challengeMode == 0 ? '' : '',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
