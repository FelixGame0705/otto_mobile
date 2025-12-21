import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/services/lesson_resource_service.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_card.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonResourcesScreen extends StatefulWidget {
  final String lessonId;
  final String? lessonTitle;

  const LessonResourcesScreen({super.key, required this.lessonId, this.lessonTitle});

  @override
  State<LessonResourcesScreen> createState() => _LessonResourcesScreenState();
}

class _LessonResourcesScreenState extends State<LessonResourcesScreen> {
  final LessonResourceService _service = LessonResourceService();
  LessonResourcePageData? _page;
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
      final res = await _service.getLessonResources(lessonId: widget.lessonId);
      setState(() {
        _page = res.data;
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
      appBar: AppBar(
        title: Text(widget.lessonTitle ?? 'resource.title'.tr()),
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
                        child: Text('common.retry'.tr()),
                      ),
                    ],
                  ),
                )
              : _page == null || _page!.items.isEmpty
                  ? Center(child: Text('resource.empty'.tr()))
                  : ListView.builder(
                      itemCount: _page!.items.length,
                      itemBuilder: (context, index) {
                        final item = _page!.items[index];
                        return LessonResourceCard(
                          item: item,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/lesson-resource-detail',
                              arguments: item.id,
                            );
                          },
                        );
                      },
                    ),
        ),
    );
  }
}


