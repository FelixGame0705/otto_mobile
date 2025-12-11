class LessonNote {
  final String id;
  final String studentId;
  final String lessonId;
  final String? lessonResourceId;
  final String content;
  final int timestampInSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String studentFullname;
  final String lessonTitle;
  final String courseTitle;
  final int lessonOrder;
  final String resourceTitle;

  LessonNote({
    required this.id,
    required this.studentId,
    required this.lessonId,
    this.lessonResourceId,
    required this.content,
    required this.timestampInSeconds,
    required this.createdAt,
    required this.updatedAt,
    required this.studentFullname,
    required this.lessonTitle,
    required this.courseTitle,
    required this.lessonOrder,
    required this.resourceTitle,
  });

  factory LessonNote.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTimeWithOffset(String dateTimeString) {
      try {
        final dateTime = DateTime.parse(dateTimeString);
        return dateTime.add(const Duration(hours: 7));
      } catch (_) {
        return DateTime.now();
      }
    }

    return LessonNote(
      id: (json['id'] as String?) ?? '',
      studentId: (json['studentId'] as String?) ?? '',
      lessonId: (json['lessonId'] as String?) ?? '',
      lessonResourceId: json['lessonResourceId'] as String?,
      content: (json['content'] as String?) ?? '',
      timestampInSeconds: (json['timestampInSeconds'] as int?) ?? 0,
      createdAt: json['createdAt'] != null 
          ? _parseDateTimeWithOffset(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTimeWithOffset(json['updatedAt'] as String)
          : DateTime.now(),
      studentFullname: (json['studentFullname'] as String?) ?? '',
      lessonTitle: (json['lessonTitle'] as String?) ?? '',
      courseTitle: (json['courseTitle'] as String?) ?? '',
      lessonOrder: (json['lessonOrder'] as int?) ?? 0,
      resourceTitle: (json['resourceTitle'] as String?) ?? '',
    );
  }
}

class LessonNotePage {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<LessonNote> items;

  LessonNotePage({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory LessonNotePage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return LessonNotePage(
      size: (json['size'] as int?) ?? 0,
      page: (json['page'] as int?) ?? 1,
      total: (json['total'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ?? 0,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => LessonNote.fromJson(e))
          .toList(),
    );
  }
}


