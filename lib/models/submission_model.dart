class Submission {
  final String id;
  final String challengeId;
  final String studentId;
  final String codeJson;
  final int star;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String challengeTitle;
  final String studentName;
  final String lessonTitle;
  final String courseTitle;

  const Submission({
    required this.id,
    required this.challengeId,
    required this.studentId,
    required this.codeJson,
    required this.star,
    required this.createdAt,
    required this.updatedAt,
    required this.challengeTitle,
    required this.studentName,
    required this.lessonTitle,
    required this.courseTitle,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'] as String,
      challengeId: json['challengeId'] as String,
      studentId: json['studentId'] as String,
      codeJson: json['codeJson'] as String,
      star: json['star'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      challengeTitle: json['challengeTitle'] as String,
      studentName: json['studentName'] as String,
      lessonTitle: json['lessonTitle'] as String,
      courseTitle: json['courseTitle'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengeId': challengeId,
      'studentId': studentId,
      'codeJson': codeJson,
      'star': star,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'challengeTitle': challengeTitle,
      'studentName': studentName,
      'lessonTitle': lessonTitle,
      'courseTitle': courseTitle,
    };
  }
}

class SubmissionApiResponse {
  final String message;
  final Submission? data;
  final List<String>? errors;
  final String? errorCode;
  final DateTime timestamp;

  const SubmissionApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory SubmissionApiResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionApiResponse(
      message: json['message'] as String,
      data: json['data'] != null ? Submission.fromJson(json['data'] as Map<String, dynamic>) : null,
      errors: json['errors'] != null ? List<String>.from(json['errors'] as List) : null,
      errorCode: json['errorCode'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class CreateSubmissionRequest {
  final String challengeId;
  final String codeJson;
  final int star;

  const CreateSubmissionRequest({
    required this.challengeId,
    required this.codeJson,
    required this.star,
  });

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'codeJson': codeJson,
      'star': star,
    };
  }
}
