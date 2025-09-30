
class ChallengeProcess {
  final String id;
  final String enrollmentId;
  final String challengeId;
  final String challengeTitle;
  final int challengeOrder;
  final int difficulty;
  final int bestStar;
  final String? bestSubmissionId;
  final DateTime? completedAt;
  final String studentName;
  final String lessonTitle;
  final String courseTitle;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChallengeProcess({
    required this.id,
    required this.enrollmentId,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeOrder,
    required this.difficulty,
    required this.bestStar,
    this.bestSubmissionId,
    this.completedAt,
    required this.studentName,
    required this.lessonTitle,
    required this.courseTitle,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChallengeProcess.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return null;
    }

    return ChallengeProcess(
      id: json['id'] ?? '',
      enrollmentId: json['enrollmentId'] ?? '',
      challengeId: json['challengeId'] ?? '',
      challengeTitle: json['challengeTitle'] ?? '',
      challengeOrder: json['challengeOrder'] ?? 0,
      difficulty: json['difficulty'] ?? 0,
      bestStar: json['bestStar'] ?? 0,
      bestSubmissionId: json['bestSubmissionId'],
      completedAt: _parseDate(json['completedAt']),
      studentName: json['studentName'] ?? '',
      lessonTitle: json['lessonTitle'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChallengeProcessListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<ChallengeProcess> items;

  ChallengeProcessListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory ChallengeProcessListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => ChallengeProcess.fromJson(e as Map<String, dynamic>))
        .toList();

    return ChallengeProcessListResponse(
      size: data['size'] ?? 0,
      page: data['page'] ?? 1,
      total: data['total'] ?? 0,
      totalPages: data['totalPages'] ?? 1,
      items: items,
    );
  }
}

class ChallengeProcessApiResponse {
  final String message;
  final ChallengeProcessListResponse? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  ChallengeProcessApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory ChallengeProcessApiResponse.fromJson(Map<String, dynamic> json) {
    return ChallengeProcessApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? ChallengeProcessListResponse.fromJson(json) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
