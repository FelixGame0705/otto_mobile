class RobotItem {
  final String id;
  final String name;
  final String model;
  final String brand;
  final String? description;
  final String? imageUrl;
  final int price;
  final int stockQuantity;
  final String? technicalSpecs;
  final String? requirements;
  final int minAge;
  final int maxAge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final int imagesCount;
  final int courseRobotsCount;
  final int studentRobotsCount;

  RobotItem({
    required this.id,
    required this.name,
    required this.model,
    required this.brand,
    this.description,
    this.imageUrl,
    required this.price,
    required this.stockQuantity,
    this.technicalSpecs,
    this.requirements,
    required this.minAge,
    required this.maxAge,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.imagesCount,
    required this.courseRobotsCount,
    required this.studentRobotsCount,
  });

  factory RobotItem.fromJson(Map<String, dynamic> json) {
    return RobotItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      technicalSpecs: json['technicalSpecs'] as String?,
      requirements: json['requirements'] as String?,
      minAge: (json['minAge'] as num?)?.toInt() ?? 0,
      maxAge: (json['maxAge'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      imagesCount: (json['imagesCount'] as num?)?.toInt() ?? 0,
      courseRobotsCount: (json['courseRobotsCount'] as num?)?.toInt() ?? 0,
      studentRobotsCount: (json['studentRobotsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class RobotPageData {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<RobotItem> items;

  RobotPageData({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory RobotPageData.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return RobotPageData(
      size: (json['size'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => RobotItem.fromJson(e))
          .toList(),
    );
  }
}

class RobotsApiResponse {
  final String message;
  final RobotPageData data;
  final dynamic errors;
  final String? errorCode;
  final DateTime timestamp;

  RobotsApiResponse({
    required this.message,
    required this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory RobotsApiResponse.fromJson(Map<String, dynamic> json) {
    return RobotsApiResponse(
      message: (json['message'] as String?) ?? '',
      data: RobotPageData.fromJson(
        (json['data'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
      errors: json['errors'],
      errorCode: (json['errorCode'] as String?)?.trim(),
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}


