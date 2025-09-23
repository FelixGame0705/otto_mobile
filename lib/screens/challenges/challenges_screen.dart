import 'package:flutter/material.dart';
import 'package:otto_mobile/models/challenge_model.dart';
import 'package:otto_mobile/services/challenge_service.dart';
import 'package:otto_mobile/widgets/challenges/challenge_card.dart';
import 'package:otto_mobile/features/blockly/blockly_editor_screen.dart';

class ChallengesScreen extends StatefulWidget {
  final String lessonId;
  final String? courseId;
  final String? lessonTitle;

  const ChallengesScreen({
    super.key,
    required this.lessonId,
    this.courseId,
    this.lessonTitle,
  });

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ChallengeService _service = ChallengeService();
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();

  List<Challenge> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  String _term = '';
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
    _search.dispose();
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
      final res = await _service.getChallenges(
        lessonId: widget.lessonId,
        courseId: widget.courseId,
        searchTerm: _term.isNotEmpty ? _term : null,
        pageNumber: _page,
        pageSize: 10,
      );
      setState(() {
        final list = res.data?.items ?? [];
        if (refresh) {
          _items = list;
        } else {
          _items.addAll(list);
        }
        _totalPages = res.data?.totalPages ?? 1;
        _hasMore = _page < _totalPages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
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
      appBar: AppBar(
        title: Text(widget.lessonTitle ?? 'Thử thách'),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _load(refresh: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => _term = v.trim(),
                    decoration: const InputDecoration(
                      hintText: 'Tìm thử thách...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _load(refresh: true),
                  child: const Text('Tìm'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xóa',
                  onPressed: () {
                    _search.clear();
                    _term = '';
                    _load(refresh: true);
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 56),
                        const SizedBox(height: 12),
                        Text(_error),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _load(refresh: true),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                ? const Center(child: Text('Không có thử thách nào'))
                : GridView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.symmetric(horizontal: padH.toDouble()),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _cols(w, o),
                      childAspectRatio: _ratio(w, o),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount:
                        _items.length +
                        (_loadingMore ? 1 : 0) +
                        (!_hasMore && _items.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _items.length && _loadingMore) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (index == _items.length + (_loadingMore ? 1 : 0) &&
                          !_hasMore &&
                          _items.isNotEmpty) {
                        return Center(
                          child: Text(
                            'Đã hiển thị tất cả thử thách',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      }
                      if (index < _items.length) {
                        final c = _items[index];
                        return ChallengeCard(
                          challenge: c,
                          onTap: () async {
                            try {
                              // Fetch latest challenge detail to ensure mapJson/challengeJson are present
                              final detail = await _service.getChallengeDetail(
                                c.id,
                              );
                              if (!mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BlocklyEditorScreen(
                                    initialMapJson: detail.mapJson,
                                    initialChallengeJson: {
                                      ...?detail.challengeJson,
                                      'id': detail.id,
                                    },
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
