class ActivationCodeRequest {
  final String code;

  ActivationCodeRequest({
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
    };
  }
}

class ActivationCodeResponse {
  final String message;
  final ActivationCodeData? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  ActivationCodeResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory ActivationCodeResponse.fromJson(Map<String, dynamic> json) {
    return ActivationCodeResponse(
      message: json['message'] ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic> 
          ? ActivationCodeData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class ActivationCodeData {
  final String id;
  final String code;
  final String? courseId;
  final String? robotId;
  final bool isUsed;
  final String? usedBy;
  final String? usedAt;
  final String createdAt;
  final String updatedAt;

  ActivationCodeData({
    required this.id,
    required this.code,
    this.courseId,
    this.robotId,
    required this.isUsed,
    this.usedBy,
    this.usedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivationCodeData.fromJson(Map<String, dynamic> json) {
    try {
      return ActivationCodeData(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        courseId: json['courseId']?.toString(),
        robotId: json['robotId']?.toString(),
        isUsed: json['isUsed'] is bool ? json['isUsed'] as bool : false,
        usedBy: json['usedBy']?.toString(),
        usedAt: json['usedAt']?.toString(),
        createdAt: json['createdAt']?.toString() ?? '',
        updatedAt: json['updatedAt']?.toString() ?? '',
      );
    } catch (e) {
      print('Error parsing ActivationCodeData: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

/// Helper function to parse DateTime and add 7 hours for timezone offset
DateTime _parseDateTimeWithOffset(String dateTimeString) {
  return DateTime.parse(dateTimeString).add(const Duration(hours: 7));
}

/// Model for activation code with full details (used in My Robots)
class MyActivationCode {
  final String id;
  final String code;
  final String robotId;
  final int status; // 2 = activated
  final DateTime? usedAt;
  final String studentId;
  final DateTime expiresAt;
  final String batchId;
  final String robotName;
  final String studentFullname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  MyActivationCode({
    required this.id,
    required this.code,
    required this.robotId,
    required this.status,
    this.usedAt,
    required this.studentId,
    required this.expiresAt,
    required this.batchId,
    required this.robotName,
    required this.studentFullname,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory MyActivationCode.fromJson(Map<String, dynamic> json) {
    return MyActivationCode(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      robotId: json['robotId']?.toString() ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      usedAt: json['usedAt'] != null && json['usedAt'].toString().isNotEmpty
          ? _parseDateTimeWithOffset(json['usedAt'].toString())
          : null,
      studentId: json['studentId']?.toString() ?? '',
      expiresAt: _parseDateTimeWithOffset(json['expiresAt'].toString()),
      batchId: json['batchId']?.toString() ?? '',
      robotName: json['robotName']?.toString() ?? '',
      studentFullname: json['studentFullname']?.toString() ?? '',
      createdAt: _parseDateTimeWithOffset(json['createdAt'].toString()),
      updatedAt: _parseDateTimeWithOffset(json['updatedAt'].toString()),
      isDeleted: json['isDeleted'] is bool ? json['isDeleted'] as bool : false,
    );
  }
}

/// Paginated response for activation codes
class ActivationCodePage {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<MyActivationCode> items;

  ActivationCodePage({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory ActivationCodePage.fromJson(Map<String, dynamic> json) {
    return ActivationCodePage(
      size: (json['size'] as num?)?.toInt() ?? 10,
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => MyActivationCode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// API response wrapper for activation code list
class ActivationCodeListApiResponse {
  final String message;
  final ActivationCodePage data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  ActivationCodeListApiResponse({
    required this.message,
    required this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory ActivationCodeListApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return ActivationCodeListApiResponse(
      message: json['message']?.toString() ?? '',
      data: ActivationCodePage.fromJson(data),
      errors: json['errors']?.toString(),
      errorCode: json['errorCode']?.toString(),
      timestamp: _parseDateTimeWithOffset(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }
}