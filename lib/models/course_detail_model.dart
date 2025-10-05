import 'package:intl/intl.dart';

class CourseDetail {
  final String id;
  final String createdById;
  final String title;
  final String description;
  final String imageUrl;
  final int price;
  final int type; // 1 = free, 2 = paid
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
    required this.price,
    required this.type,
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
      price: (json['price'] as num?)?.toInt() ?? 0,
      type: (json['type'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lessonsCount: (json['lessonsCount'] as num?)?.toInt() ?? 0,
      enrollmentsCount: (json['enrollmentsCount'] as num?)?.toInt() ?? 0,
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
      'price': price,
      'type': type,
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

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(price)} VNĐ';
  }

  bool get isFree => type == 1;
  bool get isPaid => type == 2;
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
