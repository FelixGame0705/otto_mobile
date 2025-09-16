import 'package:intl/intl.dart';

class Lesson {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final int durationInMinutes;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int challengesCount;
  final String courseTitle;

  Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.durationInMinutes,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.challengesCount,
    required this.courseTitle,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      durationInMinutes: json['durationInMinutes'] ?? 0,
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      challengesCount: json['challengesCount'] ?? 0,
      courseTitle: json['courseTitle'] ?? '',
    );
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  String get formattedDuration {
    if (durationInMinutes < 60) {
      return '${durationInMinutes}p';
    }
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}p';
  }
}

class LessonListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Lesson> items;

  LessonListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory LessonListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
        .toList();

    return LessonListResponse(
      size: data['size'] ?? 0,
      page: data['page'] ?? 1,
      total: data['total'] ?? 0,
      totalPages: data['totalPages'] ?? 1,
      items: items,
    );
  }
}

class LessonApiResponse {
  final String message;
  final LessonListResponse? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  LessonApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory LessonApiResponse.fromJson(Map<String, dynamic> json) {
    return LessonApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? LessonListResponse.fromJson(json)
          : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
