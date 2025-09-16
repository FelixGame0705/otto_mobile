class Challenge {
  final String id;
  final String lessonId;
  final String title;
  final String description;
  final int order;
  final int difficulty;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int submissionsCount;
  final String lessonTitle;
  final String courseTitle;

  Challenge({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.description,
    required this.order,
    required this.difficulty,
    required this.createdAt,
    required this.updatedAt,
    required this.submissionsCount,
    required this.lessonTitle,
    required this.courseTitle,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      order: json['order'] ?? 0,
      difficulty: json['difficulty'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      submissionsCount: json['submissionsCount'] ?? 0,
      lessonTitle: json['lessonTitle'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
    );
  }
}

class ChallengeListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Challenge> items;

  ChallengeListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory ChallengeListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => Challenge.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChallengeListResponse(
      size: data['size'] ?? 0,
      page: data['page'] ?? 1,
      total: data['total'] ?? 0,
      totalPages: data['totalPages'] ?? 1,
      items: items,
    );
  }
}

class ChallengeApiResponse {
  final String message;
  final ChallengeListResponse? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  ChallengeApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory ChallengeApiResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? ChallengeListResponse.fromJson(json) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}


