import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/services/lesson_resource_service.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_meta.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_view.dart';
import 'package:ottobit/widgets/lessons/lesson_note_composer.dart';
import 'package:ottobit/widgets/lessons/lesson_note_list.dart';
import 'package:ottobit/utils/api_error_handler.dart';

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
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      setState(() {
        _error = friendly;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Text(
          _item?.title ?? 'resource.title'.tr(),
          style: const TextStyle(color: Color(0xFF1F2937)),
        ),
      ),
      body: SafeArea(
        child: _loading
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00ba4a),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                )
              : _item == null
                  ? Center(child: Text('resource.notFound'.tr()))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LessonResourceMeta(item: _item!),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: AspectRatio(
                                aspectRatio: 14 / 9,
                                child: LessonResourceView(url: _item!.fileUrl),
                              ),
                            ),
                            // Note composer (manual time selection or pick current if supported)
                            LessonNoteComposer(
                              lessonId: _item!.lessonId,
                              lessonResourceId: _item!.id,
                              getCurrentSeconds: null,
                              onSaved: () => _notesKey.currentState?.reload(),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.sticky_note_2_outlined, size: 18, color: Color(0xFF475569)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'lesson.myNotes'.tr(),
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            LessonNoteList(
                              key: _notesKey,
                              lessonId: _item!.lessonId,
                              lessonResourceId: _item!.id,
                              onJumpTo: null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
        ),
    );
  }
}


