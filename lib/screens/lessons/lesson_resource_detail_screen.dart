import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/services/lesson_resource_service.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_meta.dart';
import 'package:ottobit/widgets/lessons/lesson_resource_view.dart';

class LessonResourceDetailScreen extends StatefulWidget {
  final String resourceId;

  const LessonResourceDetailScreen({super.key, required this.resourceId});

  @override
  State<LessonResourceDetailScreen> createState() => _LessonResourceDetailScreenState();
}

class _LessonResourceDetailScreenState extends State<LessonResourceDetailScreen> {
  final LessonResourceService _service = LessonResourceService();
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
                  : Column(
                      children: [
                        LessonResourceMeta(item: _item!),
                        Expanded(
                          child: LessonResourceView(url: _item!.fileUrl),
                        ),
                      ],
                    ),
    );
  }
}


