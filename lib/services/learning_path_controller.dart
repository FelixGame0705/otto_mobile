import 'package:ottobit/models/lesson_model.dart';
import 'package:ottobit/models/lesson_resource_model.dart';
import 'package:ottobit/services/lesson_resource_service.dart';
import 'package:ottobit/services/lesson_service.dart';

class LearningPathController {
  final LessonService _lessonService = LessonService();
  final LessonResourceService _resourceService = LessonResourceService();

  Future<List<Lesson>> loadLessons(String courseId) async {
    final res = await _lessonService.getLessons(
      courseId: courseId,
      pageSize: 100,
      pageNumber: 1,
    );
    return res.data?.items ?? <Lesson>[];
  }

  Future<List<LessonResourceItem>> loadLessonResourcesPreview(
    String lessonId, {
    int limit = 3,
  }) async {
    final res = await _resourceService.getLessonResources(
      lessonId: lessonId,
      pageNumber: 1,
      pageSize: limit,
    );
    return res.data.items;
  }
}


