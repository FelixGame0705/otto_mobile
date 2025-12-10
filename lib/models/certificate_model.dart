class Certificate {
  final String id;
  final String studentId;
  final String studentFullname;
  final String courseId;
  final String courseTitle;
  final String enrollmentId;
  final String templateId;
  final String certificateNo;
  final String verificationCode;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Certificate({
    required this.id,
    required this.studentId,
    required this.studentFullname,
    required this.courseId,
    required this.courseTitle,
    required this.enrollmentId,
    required this.templateId,
    required this.certificateNo,
    required this.verificationCode,
    required this.issuedAt,
    this.expiresAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentFullname: json['studentFullname'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      enrollmentId: json['enrollmentId'] ?? '',
      templateId: json['templateId'] ?? '',
      certificateNo: json['certificateNo'] ?? '',
      verificationCode: json['verificationCode'] ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt'] ?? '') ?? DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
      status: json['status'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentFullname': studentFullname,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'enrollmentId': enrollmentId,
      'templateId': templateId,
      'certificateNo': certificateNo,
      'verificationCode': verificationCode,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Certificate copyWith({
    String? id,
    String? studentId,
    String? studentFullname,
    String? courseId,
    String? courseTitle,
    String? enrollmentId,
    String? templateId,
    String? certificateNo,
    String? verificationCode,
    DateTime? issuedAt,
    DateTime? expiresAt,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Certificate(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentFullname: studentFullname ?? this.studentFullname,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      enrollmentId: enrollmentId ?? this.enrollmentId,
      templateId: templateId ?? this.templateId,
      certificateNo: certificateNo ?? this.certificateNo,
      verificationCode: verificationCode ?? this.verificationCode,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isActive => status == 1;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  String get statusText {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Active';
      case 2:
        return 'Expired';
      case 3:
        return 'Revoked';
      default:
        return 'Unknown';
    }
  }
}

class CertificateTemplate {
  final String id;
  final String courseId;
  final String courseTitle;
  final String name;
  final String bodyHtml;
  final String issuerName;
  final String issuerTitle;
  final String signatureImageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CertificateTemplate({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.name,
    required this.bodyHtml,
    required this.issuerName,
    required this.issuerTitle,
    required this.signatureImageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CertificateTemplate.fromJson(Map<String, dynamic> json) {
    return CertificateTemplate(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      name: json['name'] ?? '',
      bodyHtml: json['bodyHtml'] ?? '',
      issuerName: json['issuerName'] ?? '',
      issuerTitle: json['issuerTitle'] ?? '',
      signatureImageUrl: json['signatureImageUrl'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'name': name,
      'bodyHtml': bodyHtml,
      'issuerName': issuerName,
      'issuerTitle': issuerTitle,
      'signatureImageUrl': signatureImageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Method to replace placeholders in HTML template
  String renderTemplate({
    required String studentName,
    required String courseTitle,
    required String issueDate,
    required String certificateId,
  }) {
    return bodyHtml
        .replaceAll('{{StudentName}}', studentName)
        .replaceAll('{{CourseTitle}}', courseTitle)
        .replaceAll('{{IssueDate}}', issueDate)
        .replaceAll('{{CertificateId}}', certificateId)
        .replaceAll('{{SignatureImageUrl}}', signatureImageUrl)
        .replaceAll('{{IssuerName}}', issuerName)
        .replaceAll('{{IssuerTitle}}', issuerTitle);
  }
}

class CertificateListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Certificate> items;

  CertificateListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory CertificateListResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((item) => Certificate.fromJson(item as Map<String, dynamic>))
        .toList();

    return CertificateListResponse(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: itemsList,
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
