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
