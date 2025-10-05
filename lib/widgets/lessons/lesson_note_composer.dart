import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ottobit/services/lesson_note_service.dart';

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
  int _timestamp = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
        timestampInSeconds: _timestamp,
      );
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ghi chú')),
      );
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _openTimePicker() async {
    Duration temp = Duration(seconds: _timestamp);
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text('Chọn thời gian', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF00ba4a))),
              SizedBox(
                height: 200,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: temp,
                  onTimerDurationChanged: (d) {
                    temp = d;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(temp.inSeconds),
                        child: const Text('Xong'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && mounted) {
      setState(() => _timestamp = result);
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
              const Text(
                'Thêm ghi chú',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(_format(_timestamp), style: const TextStyle(color: Color(0xFF4A5568))),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Lấy thời gian hiện tại',
                icon: const Icon(Icons.timelapse_outlined),
                onPressed: () {
                  final getSeconds = widget.getCurrentSeconds;
                  if (getSeconds != null) {
                    setState(() => _timestamp = getSeconds());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openTimePicker,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF334155),
                  elevation: 3,
                  shadowColor: Colors.black12,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                icon: const Icon(Icons.access_time),
                label: const Text('Chọn thời gian', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Nội dung ghi chú...',
              border: OutlineInputBorder(),
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
              label: _submitting ? const Text('Đang lưu...') : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}


