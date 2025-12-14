class Component {
  final String id;
  final String name;
  final String description;
  final int type;
  final String? imageUrl;
  final int price;
  final int stockQuantity;
  final String specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final int imagesCount;

  Component({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.price,
    required this.stockQuantity,
    required this.specifications,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.imagesCount,
  });

  factory Component.fromJson(Map<String, dynamic> json) {
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

    return Component(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: _parseInt(json['type']),
      imageUrl: json['imageUrl'],
      price: _parseInt(json['price']),
      stockQuantity: _parseInt(json['stockQuantity']),
      specifications: json['specifications'] ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isDeleted: json['isDeleted'] ?? false,
      imagesCount: _parseInt(json['imagesCount']),
    );
  }
}

class ComponentListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<Component> items;

  ComponentListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory ComponentListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => Component.fromJson(e as Map<String, dynamic>))
        .toList();

    return ComponentListResponse(
      size: data['size'] ?? 0,
      page: data['page'] ?? 1,
      total: data['total'] ?? 0,
      totalPages: data['totalPages'] ?? 1,
      items: items,
    );
  }
}

class ComponentApiResponse {
  final String message;
  final ComponentListResponse? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  ComponentApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory ComponentApiResponse.fromJson(Map<String, dynamic> json) {
    return ComponentApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? ComponentListResponse.fromJson(json) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class RobotComponent {
  final String id;
  final String robotId;
  final String componentId;
  final int quantity;
  final String robotName;
  final String componentName;
  final String? componentImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  RobotComponent({
    required this.id,
    required this.robotId,
    required this.componentId,
    required this.quantity,
    required this.robotName,
    required this.componentName,
    this.componentImageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  factory RobotComponent.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTimeWithOffset(String dateTimeString) {
      try {
        final dateTime = DateTime.parse(dateTimeString);
        return dateTime.add(const Duration(hours: 7));
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return RobotComponent(
      id: json['id'] ?? '',
      robotId: json['robotId'] ?? '',
      componentId: json['componentId'] ?? '',
      quantity: json['quantity'] ?? 0,
      robotName: json['robotName'] ?? '',
      componentName: json['componentName'] ?? '',
      componentImageUrl: json['componentImageUrl'],
      createdAt: _parseDateTimeWithOffset(json['createdAt'] ?? ''),
      updatedAt: _parseDateTimeWithOffset(json['updatedAt'] ?? ''),
      isDeleted: json['isDeleted'] ?? false,
    );
  }
}

class RobotComponentListResponse {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<RobotComponent> items;

  RobotComponentListResponse({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory RobotComponentListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => RobotComponent.fromJson(e as Map<String, dynamic>))
        .toList();

    return RobotComponentListResponse(
      size: data['size'] ?? 0,
      page: data['page'] ?? 1,
      total: data['total'] ?? 0,
      totalPages: data['totalPages'] ?? 1,
      items: items,
    );
  }
}

class RobotComponentApiResponse {
  final String message;
  final RobotComponentListResponse? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  RobotComponentApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory RobotComponentApiResponse.fromJson(Map<String, dynamic> json) {
    DateTime _parseDateTimeWithOffset(String dateTimeString) {
      try {
        final dateTime = DateTime.parse(dateTimeString);
        return dateTime.add(const Duration(hours: 7));
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return RobotComponentApiResponse(
      message: json['message'] ?? '',
      data: json['data'] != null ? RobotComponentListResponse.fromJson(json) : null,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: _parseDateTimeWithOffset(json['timestamp'] ?? ''),
    );
  }
}