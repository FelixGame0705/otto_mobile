class CourseRobot {
  final String id;
  final String courseId;
  final String robotId;
  final bool isRequired;
  final String courseTitle;
  final String robotName;
  final String robotBrand;
  final String robotModel;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;

  CourseRobot({
    required this.id,
    required this.courseId,
    required this.robotId,
    required this.isRequired,
    required this.courseTitle,
    required this.robotName,
    required this.robotBrand,
    required this.robotModel,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory CourseRobot.fromJson(Map<String, dynamic> json) {
    return CourseRobot(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      robotId: json['robotId'] ?? '',
      isRequired: json['isRequired'] ?? false,
      courseTitle: json['courseTitle'] ?? '',
      robotName: json['robotName'] ?? '',
      robotBrand: json['robotBrand'] ?? '',
      robotModel: json['robotModel'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'robotId': robotId,
      'isRequired': isRequired,
      'courseTitle': courseTitle,
      'robotName': robotName,
      'robotBrand': robotBrand,
      'robotModel': robotModel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };
  }
}

class CourseRobotPageData {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<CourseRobot> items;

  CourseRobotPageData({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory CourseRobotPageData.fromJson(Map<String, dynamic> json) {
    return CourseRobotPageData(
      size: json['size'] ?? 0,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CourseRobot.fromJson(item))
          .toList() ?? [],
    );
  }
}

class CourseRobotResponse {
  final String message;
  final CourseRobotPageData? data;
  final String? errors;
  final String? errorCode;
  final String timestamp;

  CourseRobotResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory CourseRobotResponse.fromJson(Map<String, dynamic> json) {
    return CourseRobotResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? CourseRobotPageData.fromJson(json['data']) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: json['timestamp'] ?? '',
    );
  }
}
