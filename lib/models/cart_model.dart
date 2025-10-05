import 'package:intl/intl.dart';

class CartItem {
  final String id;
  final String cartId;
  final String courseId;
  final String courseTitle;
  final String courseDescription;
  final String courseImageUrl;
  final int unitPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.cartId,
    required this.courseId,
    required this.courseTitle,
    required this.courseDescription,
    required this.courseImageUrl,
    required this.unitPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      cartId: json['cartId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      courseImageUrl: json['courseImageUrl'] ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'courseDescription': courseDescription,
      'courseImageUrl': courseImageUrl,
      'unitPrice': unitPrice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(unitPrice)} VNĐ';
  }
}

class Cart {
  final String id;
  final String userId;
  final int subtotal;
  final int discountAmount;
  final int total;
  final int itemsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItem> items;

  Cart({
    required this.id,
    required this.userId,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.itemsCount,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'total': total,
      'itemsCount': itemsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String get formattedSubtotal {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(subtotal)} VNĐ';
  }

  String get formattedDiscountAmount {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(discountAmount)} VNĐ';
  }

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(total)} VNĐ';
  }

  bool get isEmpty => items.isEmpty;
}

class CartSummary {
  final String cartId;
  final int itemsCount;
  final int subtotal;
  final int discountAmount;
  final int total;
  final bool isEmpty;
  final DateTime lastUpdated;

  CartSummary({
    required this.cartId,
    required this.itemsCount,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.isEmpty,
    required this.lastUpdated,
  });

  factory CartSummary.fromJson(Map<String, dynamic> json) {
    return CartSummary(
      cartId: json['cartId'] ?? '',
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      isEmpty: json['isEmpty'] ?? true,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'itemsCount': itemsCount,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'total': total,
      'isEmpty': isEmpty,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  String get formattedSubtotal {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(subtotal)} VNĐ';
  }

  String get formattedDiscountAmount {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(discountAmount)} VNĐ';
  }

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(total)} VNĐ';
  }
}

class AddToCartRequest {
  final String courseId;
  final int unitPrice;

  AddToCartRequest({
    required this.courseId,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'unitPrice': unitPrice,
    };
  }
}

class CartValidationRequest {
  final String courseId;

  CartValidationRequest({
    required this.courseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
    };
  }
}

class CartApiResponse<T> {
  final String message;
  final T? data;
  final String? errors;
  final String? errorCode;
  final DateTime timestamp;

  CartApiResponse({
    required this.message,
    this.data,
    this.errors,
    this.errorCode,
    required this.timestamp,
  });

  factory CartApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final dynamic rawData = json['data'];
    final T? parsedData = rawData != null && fromJsonT != null
        ? fromJsonT(rawData)
        : rawData as T?;
    return CartApiResponse<T>(
      message: json['message'] ?? '',
      data: parsedData,
      errors: json['errors'],
      errorCode: json['errorCode'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'data': data,
      'errors': errors,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
