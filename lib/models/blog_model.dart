import 'package:ottobit/utils/date_time_utils.dart';

class BlogTag {
  final String id;
  final String name;
  final DateTime createdAt;

  BlogTag({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory BlogTag.fromJson(Map<String, dynamic> json) {
    return BlogTag(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Blog {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String thumbnailUrl;
  final String authorId;
  final String authorName;
  final int viewCount;
  final int readingTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final List<dynamic> comments;
  final List<BlogTag> tags;

  Blog({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.thumbnailUrl,
    required this.authorId,
    required this.authorName,
    required this.viewCount,
    required this.readingTime,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.comments,
    required this.tags,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      content: json['content'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      readingTime: (json['readingTime'] as num?)?.toInt() ?? 0,
      createdAt: DateTimeUtils.parseDateTimeWithOffset(json['createdAt'] ?? ''),
      updatedAt: DateTimeUtils.parseDateTimeWithOffset(json['updatedAt'] ?? ''),
      isDeleted: json['isDeleted'] ?? false,
      comments: json['comments'] ?? [],
      tags: (json['tags'] as List<dynamic>?)
          ?.map((tag) => BlogTag.fromJson(tag as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'content': content,
      'thumbnailUrl': thumbnailUrl,
      'authorId': authorId,
      'authorName': authorName,
      'viewCount': viewCount,
      'readingTime': readingTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
      'comments': comments,
      'tags': tags.map((tag) => tag.toJson()).toList(),
    };
  }
}

class BlogListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Blog> items;

  BlogListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory BlogListResponse.fromJson(Map<String, dynamic> json) {
    return BlogListResponse(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => Blog.fromJson(item as Map<String, dynamic>))
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

class BlogApiResponse {
  final String message;
  final BlogListResponse? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  BlogApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory BlogApiResponse.fromJson(Map<String, dynamic> json) {
    return BlogApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? BlogListResponse.fromJson(json['data']) : null,
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

class BlogDetailResponse {
  final String message;
  final Blog? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  BlogDetailResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory BlogDetailResponse.fromJson(Map<String, dynamic> json) {
    return BlogDetailResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? Blog.fromJson(json['data']) : null,
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

class TagListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<BlogTag> items;

  TagListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory TagListResponse.fromJson(Map<String, dynamic> json) {
    return TagListResponse(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => BlogTag.fromJson(item as Map<String, dynamic>))
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

class TagApiResponse {
  final String message;
  final TagListResponse? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  TagApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory TagApiResponse.fromJson(Map<String, dynamic> json) {
    return TagApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? TagListResponse.fromJson(json['data']) : null,
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
