class LessonResourceItem {
  final String id;
  final String lessonId;
  final String title;
  final String? description;
  final int type; // 1: video, 2: document, etc.
  final String fileUrl;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lessonTitle;
  final String courseTitle;
  final int lessonOrder;

  LessonResourceItem({
    required this.id,
    required this.lessonId,
    required this.title,
    this.description,
    required this.type,
    required this.fileUrl,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.lessonTitle,
    required this.courseTitle,
    required this.lessonOrder,
  });

  factory LessonResourceItem.fromJson(Map<String, dynamic> json) {
    return LessonResourceItem(
      id: (json['id'] as String?) ?? '',
      lessonId: (json['lessonId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      type: (json['type'] as int?) ?? 0,
      fileUrl: (json['fileUrl'] as String?) ?? '',
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      lessonTitle: (json['lessonTitle'] as String?) ?? '',
      courseTitle: (json['courseTitle'] as String?) ?? '',
      lessonOrder: (json['lessonOrder'] as int?) ?? 0,
    );
  }
}

class LessonResourcePageData {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<LessonResourceItem> items;

  LessonResourcePageData({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory LessonResourcePageData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return LessonResourcePageData(
      size: (json['size'] as int?) ?? 0,
      page: (json['page'] as int?) ?? 1,
      total: (json['total'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ?? 0,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => LessonResourceItem.fromJson(e))
          .toList(),
    );
  }
}

class LessonResourceApiResponse {
  final String message;
  final LessonResourcePageData data;
  final dynamic errors;
  final String? errorCode;
  final DateTime timestamp;

  LessonResourceApiResponse({
    required this.message,
    required this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory LessonResourceApiResponse.fromJson(Map<String, dynamic> json) {
    return LessonResourceApiResponse(
      message: (json['message'] as String?) ?? '',
      data: LessonResourcePageData.fromJson(
        (json['data'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      errors: json['errors'],
      errorCode: (json['errorCode'] as String?)?.trim(),
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}


