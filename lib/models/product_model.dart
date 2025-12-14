class Product {
  final String id;
  final String name;
  final String model;
  final String brand;
  final String description;
  final String? imageUrl;
  final int price;
  final int stockQuantity;
  final String technicalSpecs;
  final String requirements;
  final int minAge;
  final int maxAge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final int imagesCount;
  final int courseRobotsCount;
  final int studentRobotsCount;

  Product({
    required this.id,
    required this.name,
    required this.model,
    required this.brand,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.stockQuantity,
    required this.technicalSpecs,
    required this.requirements,
    required this.minAge,
    required this.maxAge,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.imagesCount,
    required this.courseRobotsCount,
    required this.studentRobotsCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        try {
          return DateTime.parse(v);
        } catch (_) {}
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    int _parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (_) {}
      }
      return 0;
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      price: _parseInt(json['price']),
      stockQuantity: _parseInt(json['stockQuantity']),
      technicalSpecs: json['technicalSpecs'] ?? json['specifications'] ?? '',
      requirements: json['requirements'] ?? '',
      minAge: _parseInt(json['minAge']),
      maxAge: _parseInt(json['maxAge']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
      imagesCount: _parseInt(json['imagesCount']),
      courseRobotsCount: _parseInt(json['courseRobotsCount']),
      studentRobotsCount: _parseInt(json['studentRobotsCount']),
    );
  }
}

class ProductApiResponse {
  final String message;
  final Product? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  ProductApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory ProductApiResponse.fromJson(Map<String, dynamic> json) {
    return ProductApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? Product.fromJson(json['data']) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
