DateTime _parseBackendDate(dynamic value) {
  String s = (value ?? '').toString();
  if (s.isEmpty) return DateTime.now();

  // Capture parts and truncate fractional seconds to max 6 digits
  final r = RegExp(r'^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})(\.(\d+))?(Z|[+-]\d{2}:?\d{2})?$');
  final m = r.firstMatch(s);
  if (m != null) {
    final main = m.group(1)!; // yyyy-MM-ddTHH:mm:ss
    final fracDigits = m.group(3); // digits only
    final tz = m.group(4); // Z or offset or null
    final frac = (fracDigits == null || fracDigits.isEmpty)
        ? ''
        : '.${fracDigits.substring(0, fracDigits.length > 6 ? 6 : fracDigits.length)}';
    final tzFixed = tz ?? 'Z';
    s = '$main$frac$tzFixed';
  } else {
    // Fallback: ensure timezone exists
    final hasTz = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(s);
    if (!hasTz) s = '${s}Z';
  }

  return DateTime.parse(s).toLocal();
}

class AssistanceTicket {
  final String id;
  final String title;
  final String description;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String courseId;
  final String courseName;
  final String? assignedToId;
  final String? assignedToName;
  final int status; // 1: Open, 2: InProgress, 3: Resolved, 4: Closed
  final String? resolution;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssistanceTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseId,
    required this.courseName,
    this.assignedToId,
    this.assignedToName,
    required this.status,
    this.resolution,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssistanceTicket.fromJson(Map<String, dynamic> json) {
    return AssistanceTicket(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      assignedToId: json['assignedToId'],
      assignedToName: json['assignedToName'],
      status: json['status'] as int? ?? 1,
      resolution: json['resolution'],
      createdAt: _parseBackendDate(json['createdAt']),
      updatedAt: _parseBackendDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'courseId': courseId,
      'courseName': courseName,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'status': status,
      'resolution': resolution,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Open';
      case 2:
        return 'In Progress';
      case 3:
        return 'Resolved';
      case 4:
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  bool get isActive {
    return status == 1 || status == 2 || status == 3; // Only show Open, InProgress, Resolved
  }
}

class AssistanceMessage {
  final String id;
  final String ticketId;
  final String studentId;
  final String content;
  final bool isFromStudent;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String studentName;
  final String studentEmail;

  AssistanceMessage({
    required this.id,
    required this.ticketId,
    required this.studentId,
    required this.content,
    required this.isFromStudent,
    required this.createdAt,
    required this.updatedAt,
    required this.studentName,
    required this.studentEmail,
  });

  factory AssistanceMessage.fromJson(Map<String, dynamic> json) {
    return AssistanceMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      studentId: json['studentId'] ?? '',
      content: json['content'] ?? '',
      isFromStudent: json['isFromStudent'] as bool? ?? false,
      createdAt: _parseBackendDate(json['createdAt']),
      updatedAt: _parseBackendDate(json['updatedAt']),
      studentName: json['studentName'] ?? '',
      studentEmail: json['studentEmail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'studentId': studentId,
      'content': content,
      'isFromStudent': isFromStudent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'studentName': studentName,
      'studentEmail': studentEmail,
    };
  }
}

class CreateTicketRequest {
  final String title;
  final String description;
  final String courseId;

  CreateTicketRequest({
    required this.title,
    required this.description,
    required this.courseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'courseId': courseId,
    };
  }
}

class CreateMessageRequest {
  final String ticketId;
  final String content;

  CreateMessageRequest({
    required this.ticketId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'content': content,
    };
  }
}

class PaginatedResponse<T> {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<T> items;

  PaginatedResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      size: json['size'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => fromJsonT(item))
              .toList() ??
          [],
    );
  }
}

class TicketApiResponse<T> {
  final String message;
  final T? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  TicketApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory TicketApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final dynamic rawData = json['data'];
    final T? parsedData = rawData != null && fromJsonT != null
        ? fromJsonT(rawData)
        : rawData as T?;
    return TicketApiResponse<T>(
      message: json['message'] ?? '',
      data: parsedData,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: _parseBackendDate(json['timestamp']),
    );
  }

  bool get isSuccess => errors == null && errorCode == null;
}

// Rating models
class AssistanceRating {
  final String id;
  final String ticketId;
  final String studentId;
  final int score;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? studentFullname;
  final String? ticketTitle;
  final String? courseTitle;

  AssistanceRating({
    required this.id,
    required this.ticketId,
    required this.studentId,
    required this.score,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.studentFullname,
    this.ticketTitle,
    this.courseTitle,
  });

  factory AssistanceRating.fromJson(Map<String, dynamic> json) {
    return AssistanceRating(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      studentId: json['studentId'] ?? '',
      score: json['score'] as int? ?? 0,
      comment: json['comment'],
      createdAt: _parseBackendDate(json['createdAt']),
      updatedAt: _parseBackendDate(json['updatedAt']),
      studentFullname: json['studentFullname'],
      ticketTitle: json['ticketTitle'],
      courseTitle: json['courseTitle'],
    );
  }
}

class CreateAssistanceRatingRequest {
  final String ticketId;
  final int score;
  final String? comment;

  CreateAssistanceRatingRequest({
    required this.ticketId,
    required this.score,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'score': score,
      if (comment != null) 'comment': comment,
    };
  }
}

