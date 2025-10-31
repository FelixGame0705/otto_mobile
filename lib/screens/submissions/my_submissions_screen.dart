import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ottobit/models/submission_model.dart';
import 'package:ottobit/services/submission_service.dart';
import 'package:ottobit/features/blockly/solution_viewer_screen.dart';

class MySubmissionsScreen extends StatefulWidget {
  const MySubmissionsScreen({super.key});

  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  final SubmissionService _service = SubmissionService();
  final ScrollController _scroll = ScrollController();

  List<Submission> _items = [];
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
      final pageData = await _service.getMySubmissions(pageNumber: _page, pageSize: 10);
      setState(() {
        if (refresh) {
          _items = pageData.items;
        } else {
          _items.addAll(pageData.items);
        }
        _totalPages = pageData.totalPages;
        _hasMore = _page < _totalPages;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_error.isNotEmpty ? _error : 'Failed to load submissions'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _page++;
    await _load();
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _openSubmission(Submission s) {
    try {
      final program = jsonDecode(s.codeJson) as Map<String, dynamic>;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SolutionViewerScreen(program: program, title: s.challengeTitle),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid submission payload'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
        backgroundColor: const Color(0xFF17a64b),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _items.isEmpty
                  ? const Center(child: Text('No submissions yet'))
                  : ListView.separated(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        if (index == _items.length && _loadingMore) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        if (index < _items.length) {
                          final s = _items[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade50,
                              child: Text('${s.star}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                            ),
                            title: Text(s.challengeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${s.courseTitle} • ${s.lessonTitle}\n${s.createdAt.toLocal()}'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => _openSubmission(s),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: _items.length + (_loadingMore ? 1 : 0),
                    ),
    );
  }
}


