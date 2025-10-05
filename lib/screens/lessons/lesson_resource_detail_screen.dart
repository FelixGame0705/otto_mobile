import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/services/lesson_resource_service.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_meta.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_view.dart';
import 'package:ottobit/widgets/lessons/lesson_note_composer.dart';
import 'package:ottobit/widgets/lessons/lesson_note_list.dart';

class LessonResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const LessonResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<LessonResourceDetailScreen> createState() => _LessonResourceDetailScreenState();
}

class _LessonResourceDetailScreenState extends State<LessonResourceDetailScreen> {
  final LessonResourceService _service = LessonResourceService();
  final GlobalKey<LessonNoteListState> _notesKey = GlobalKey<LessonNoteListState>();
  LessonResourceItem? _item;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final item = await _service.getLessonResourceById(widget.resourceId);
      setState(() {
        _item = item;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item?.title ?? 'resource.title'.tr()),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                )
              : _item == null
                  ? Center(child: Text('resource.notFound'.tr()))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LessonResourceMeta(item: _item!),
                          AspectRatio(
                            aspectRatio: 14 / 9,
                            child: LessonResourceView(url: _item!.fileUrl),
                          ),
                          const SizedBox(height: 8),
                          // Note composer (manual time selection or pick current if supported)
                          LessonNoteComposer(
                            lessonId: _item!.lessonId,
                            lessonResourceId: _item!.id,
                            getCurrentSeconds: null,
                            onSaved: () => _notesKey.currentState?.reload(),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Ghi chú của tôi',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          LessonNoteList(
                            key: _notesKey,
                            lessonId: _item!.lessonId,
                            lessonResourceId: _item!.id,
                            onJumpTo: null,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }
}


