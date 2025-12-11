import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/lesson_note_model.dart';
import 'package:ottobit/services/lesson_note_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonNoteList extends StatefulWidget {
  final String lessonId;
  final String lessonResourceId;
  final void Function(int seconds)? onJumpTo;

  const LessonNoteList({
    super.key,
    required this.lessonId,
    required this.lessonResourceId,
    this.onJumpTo,
  });

  @override
  State<LessonNoteList> createState() => LessonNoteListState();
}

class LessonNoteListState extends State<LessonNoteList> {
  final LessonNoteService _service = LessonNoteService();
  bool _loading = true;
  String? _error;
  LessonNotePage? _page;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final page = await _service.getMyNotes(
        lessonId: widget.lessonId,
        lessonResourceId: widget.lessonResourceId,
      );
      if (!mounted) return;
      setState(() => _page = page);
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Allow parent to trigger reload
  Future<void> reload() => _load();

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(_error!),
          TextButton(onPressed: _load, child: Text('common.retry'.tr())),
        ],
      );
    }

    final items = _page?.items ?? const <LessonNote>[];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('lessonNote.noNotes'.tr()),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final note = items[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          title: Text(note.content),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'lessonNote.editNote'.tr(),
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _onEdit(note),
              ),
              IconButton(
                tooltip: 'lessonNote.deleteNote'.tr(),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _onDelete(note),
              ),
            ],
          ),
        );
      },
    );
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('common.save'.tr())),
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
        await reload();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('lessonNote.updated'.tr())));
      } catch (e) {
        if (!mounted) return;
        final isEnglish = context.locale.languageCode == 'en';
        final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      }
    }
  }


  Future<void> _onDelete(LessonNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('lessonNote.deleteNote'.tr()),
        content: Text('lessonNote.deleteConfirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('lessonNote.delete'.tr())),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteNote(note.id);
        if (!mounted) return;
        await reload();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('lessonNote.deleted'.tr())));
      } catch (e) {
        if (!mounted) return;
        final isEnglish = context.locale.languageCode == 'en';
        final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendly)));
      }
    }
  }
}


