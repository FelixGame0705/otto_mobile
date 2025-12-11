import 'package:intl/intl.dart';

class LessonDetail {
  final String id;
  final String courseId;
  final String title;
  final String content;
  final int durationInMinutes;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int challengeCount;
  final String courseTitle;

  LessonDetail({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.durationInMinutes,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    required this.challengeCount,
    required this.courseTitle,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    return LessonDetail(
      id: (json['id'] as String?) ?? '',
      courseId: (json['courseId'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      durationInMinutes: (json['durationInMinutes'] as int?) ?? 0,
      order: (json['order'] as int?) ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '')
              ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '')
              ?? DateTime.fromMillisecondsSinceEpoch(0),
      challengeCount: (json['challengeCount'] as int?) ?? 0,
      courseTitle: (json['courseTitle'] as String?) ?? '',
    );
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('dd/MM/yyyy HH:mm').format(updatedAt);
  }

  String get formattedDuration {
    if (durationInMinutes < 60) {
      return '${durationInMinutes} phút';
    }
    final hours = durationInMinutes ~/ 60;
    final minutes = durationInMinutes % 60;
    if (minutes == 0) {
      return '$hours giờ';
    }
    return '$hours giờ $minutes phút';
  }

  String get lessonNumber {
    return 'Bài ${order + 1}';
  }
}

class LessonDetailApiResponse {
  final String message;
  final LessonDetail? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  LessonDetailApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory LessonDetailApiResponse.fromJson(Map<String, dynamic> json) {
    return LessonDetailApiResponse(
      message: (json['message'] as String?) ?? '',
      data: json['data'] is Map<String, dynamic>
          ? LessonDetail.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: (json['errors'] is String)
          ? json['errors'] as String
          : (json['errors']?.toString()),
      errorCode: (json['errorCode'] as String?)?.trim(),
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '')
          ?? DateTime.now(),
    );
  }
}
