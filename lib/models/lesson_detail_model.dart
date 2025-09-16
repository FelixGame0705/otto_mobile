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
  final int challengesCount;
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
    required this.challengesCount,
    required this.courseTitle,
  });

  factory LessonDetail.fromJson(Map<String, dynamic> json) {
    return LessonDetail(
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
      message: json['message'] ?? '',
      data: json['data'] != null
          ? LessonDetail.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
