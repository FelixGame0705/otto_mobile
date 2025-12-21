import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/lesson_note_model.dart';
import 'package:ottobit/services/lesson_note_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'package:ottobit/routes/app_routes.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({super.key});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  final LessonNoteService _service = LessonNoteService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<LessonNote> _notes = [];
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  String? _searchTerm;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });

    try {
      final page = await _service.getAllMyNotes(
        pageNumber: 1,
        pageSize: 10,
        searchTerm: _searchTerm,
      );
      if (!mounted) return;
      setState(() {
        _notes = page.items;
        _totalPages = page.totalPages;
        _hasMore = _page < _totalPages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      setState(() {
        _error = friendly;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final nextPage = _page + 1;
      final page = await _service.getAllMyNotes(
        pageNumber: nextPage,
        pageSize: 10,
        searchTerm: _searchTerm,
      );
      if (!mounted) return;
      setState(() {
        _notes.addAll(page.items);
        _page = nextPage;
        _totalPages = page.totalPages;
        _hasMore = _page < _totalPages;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
      });
    }
  }

  Future<void> _onDelete(LessonNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('lessonNote.deleteNote'.tr()),
        content: Text('lessonNote.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('lessonNote.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteNote(note.id);
        if (!mounted) return;
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('lessonNote.deleted'.tr())),
        );
      } catch (e) {
        if (!mounted) return;
        final isEnglish = context.locale.languageCode == 'en';
        final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    }
  }

  Future<void> _onEdit(LessonNote note) async {
    final contentController = TextEditingController(text: note.content);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('lessonNote.editNote'.tr()),
          content: TextField(
            controller: contentController,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'lessonNote.content'.tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('common.cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('common.save'.tr()),
            ),
          ],
        );
      },
    );
    if (result == true) {
      try {
        await _service.updateNote(
          noteId: note.id,
          content: contentController.text.trim(),
          timestampInSeconds: 0,
        );
        if (!mounted) return;
        await _load();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('lessonNote.updated'.tr())),
        );
      } catch (e) {
        if (!mounted) return;
        final isEnglish = context.locale.languageCode == 'en';
        final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendly)),
        );
      }
    }
  }

  void _navigateToLessonResource(String lessonId, String? lessonResourceId) {
    if (lessonResourceId != null && lessonResourceId.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.lessonResourceDetail,
        arguments: lessonResourceId,
      );
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.lessonDetail,
        arguments: lessonId,
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value.isEmpty ? null : value;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.myNotes'.tr()),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
                _onSearchChanged(value);
              },
              decoration: InputDecoration(
                hintText: 'common.search'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                )
              : _notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.note_outlined, color: Colors.grey, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'profile.noNotes'.tr(),
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _notes.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _notes.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final note = _notes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _navigateToLessonResource(
                                note.lessonId,
                                note.lessonResourceId ?? '',
                              ),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                note.courseTitle,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                note.lessonTitle,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF374151),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (note.resourceTitle.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  note.resourceTitle,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        PopupMenuButton(
                                          icon: const Icon(Icons.more_vert),
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.edit_outlined, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text('lessonNote.editNote'.tr()),
                                                ],
                                              ),
                                              onTap: () => Future.delayed(
                                                const Duration(milliseconds: 100),
                                                () => _onEdit(note),
                                              ),
                                            ),
                                            PopupMenuItem(
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'lessonNote.deleteNote'.tr(),
                                                    style: const TextStyle(color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                              onTap: () => Future.delayed(
                                                const Duration(milliseconds: 100),
                                                () => _onDelete(note),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Text(
                                      note.content,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
    );
  }
}

