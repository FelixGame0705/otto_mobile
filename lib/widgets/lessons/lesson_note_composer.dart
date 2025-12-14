import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/services/lesson_note_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonNoteComposer extends StatefulWidget {
  final String lessonId;
  final String lessonResourceId;
  final int Function()? getCurrentSeconds; // optional callback to pick current time
  final VoidCallback? onSaved;

  const LessonNoteComposer({
    super.key,
    required this.lessonId,
    required this.lessonResourceId,
    this.getCurrentSeconds,
    this.onSaved,
  });

  @override
  State<LessonNoteComposer> createState() => _LessonNoteComposerState();
}

class _LessonNoteComposerState extends State<LessonNoteComposer> {
  final TextEditingController _controller = TextEditingController();
  final LessonNoteService _service = LessonNoteService();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _service.createNote(
        lessonId: widget.lessonId,
        lessonResourceId: widget.lessonResourceId,
        content: content,
        timestampInSeconds: 0,
      );
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('lessonNote.saved'.tr())),
      );
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendly)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.note_add_outlined, color: Color(0xFF4A5568)),
              const SizedBox(width: 8),
              Text(
                'lessonNote.addNote'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'lessonNote.contentHint'.tr(),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ba4a),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.black26,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: _submitting ? Text('lessonNote.saving'.tr()) : Text('common.save'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}


