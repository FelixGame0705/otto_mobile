import 'package:ottobit/utils/date_time_utils.dart';

class BlogComment {
  final String id;
  final String blogId;
  final String userId;
  final String? userName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  BlogComment({
    required this.id,
    required this.blogId,
    required this.userId,
    this.userName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id'] ?? '',
      blogId: json['blogId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'],
      content: json['content'] ?? '',
      createdAt: DateTimeUtils.parseDateTimeWithOffset(json['createdAt'] ?? ''),
      updatedAt: DateTimeUtils.parseDateTimeWithOffset(json['updatedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blogId': blogId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'blogId': blogId,
      'content': content,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'content': content,
    };
  }
}

class BlogCommentListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<BlogComment> items;

  BlogCommentListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory BlogCommentListResponse.fromJson(Map<String, dynamic> json) {
    return BlogCommentListResponse(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => BlogComment.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'page': page,
      'total': total,
      'totalPages': totalPages,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class BlogCommentApiResponse {
  final String message;
  final BlogCommentListResponse? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  BlogCommentApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory BlogCommentApiResponse.fromJson(Map<String, dynamic> json) {
    return BlogCommentApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? BlogCommentListResponse.fromJson(json['data']) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp,
    };
  }
}

class BlogCommentCreateResponse {
  final String message;
  final BlogComment? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  BlogCommentCreateResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory BlogCommentCreateResponse.fromJson(Map<String, dynamic> json) {
    return BlogCommentCreateResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? BlogComment.fromJson(json['data']) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp,
    };
  }
}

class BlogCommentUpdateResponse {
  final String message;
  final BlogComment? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  BlogCommentUpdateResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory BlogCommentUpdateResponse.fromJson(Map<String, dynamic> json) {
    return BlogCommentUpdateResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? BlogComment.fromJson(json['data']) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data?.toJson(),
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp,
    };
  }
}

class BlogCommentDeleteResponse {
  final String message;
  final bool? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  BlogCommentDeleteResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory BlogCommentDeleteResponse.fromJson(Map<String, dynamic> json) {
    return BlogCommentDeleteResponse(
      message: json['message'] ?? '',
      data: json['data'],
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data,
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp,
    };
  }
}
