import 'package:intl/intl.dart';

class CourseDetail {
  final String id;
  final String createdById;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int lessonsCount;
  final int enrollmentsCount;
  final String createdByName;

  CourseDetail({
    required this.id,
    required this.createdById,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.lessonsCount,
    required this.enrollmentsCount,
    required this.createdByName,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    return CourseDetail(
      id: json['id'] ?? '',
      createdById: json['createdById'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lessonsCount: json['lessonsCount'] ?? 0,
      enrollmentsCount: json['enrollmentsCount'] ?? 0,
      createdByName: json['createdByName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdById': createdById,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lessonsCount': lessonsCount,
      'enrollmentsCount': enrollmentsCount,
      'createdByName': createdByName,
    };
  }

  String get formattedCreatedAt {
    return DateFormat('dd/MM/yyyy').format(createdAt);
  }

  String get formattedUpdatedAt {
    return DateFormat('dd/MM/yyyy').format(updatedAt);
  }
}

class CourseDetailApiResponse {
  final String message;
  final CourseDetail? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  CourseDetailApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory CourseDetailApiResponse.fromJson(Map<String, dynamic> json) {
    return CourseDetailApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null
          ? CourseDetail.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
