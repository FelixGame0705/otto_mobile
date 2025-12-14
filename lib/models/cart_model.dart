import 'package:intl/intl.dart';

/// Helper function to parse DateTime and add 7 hours for timezone offset
DateTime _parseDateTimeWithOffset(String dateTimeString) {
  return DateTime.parse(dateTimeString).add(const Duration(hours: 7));
}

class CartItem {
  final String id;
  final String cartId;
  final String courseId;
  final String courseTitle;
  final String courseDescription;
  final String courseImageUrl;
  final int unitPrice;
  final int discountAmount;
  final int finalPrice;
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
    required this.discountAmount,
    required this.finalPrice,
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
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      finalPrice: (json['finalPrice'] as num?)?.toInt() ?? (json['unitPrice'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTimeWithOffset(json['createdAt']),
      updatedAt: _parseDateTimeWithOffset(json['updatedAt']),
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
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(finalPrice)} VNĐ';
  }
}

class Cart {
  final String id;
  final String userId;
  final int subtotal;
  final int courseDiscountTotal;
  final int voucherDiscountAmount;
  final int discountAmount;
  final int total;
  final String? voucherId;
  final String? voucherCode;
  final String? voucherName;
  final int itemsCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItem> items;

  Cart({
    required this.id,
    required this.userId,
    required this.subtotal,
    required this.courseDiscountTotal,
    required this.voucherDiscountAmount,
    required this.discountAmount,
    required this.total,
    required this.voucherId,
    required this.voucherCode,
    required this.voucherName,
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
      courseDiscountTotal: (json['courseDiscountTotal'] as num?)?.toInt() ?? 0,
      voucherDiscountAmount: (json['voucherDiscountAmount'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      voucherId: json['voucherId'],
      voucherCode: json['voucherCode'],
      voucherName: json['voucherName'],
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTimeWithOffset(json['createdAt']),
      updatedAt: _parseDateTimeWithOffset(json['updatedAt']),
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
      'courseDiscountTotal': courseDiscountTotal,
      'voucherDiscountAmount': voucherDiscountAmount,
      'discountAmount': discountAmount,
      'total': total,
      'voucherId': voucherId,
      'voucherCode': voucherCode,
      'voucherName': voucherName,
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
  final int courseDiscountTotal;
  final int voucherDiscountAmount;
  final String? voucherId;
  final String? voucherCode;
  final String? voucherName;
  final int discountAmount;
  final int total;
  final bool isEmpty;
  final DateTime lastUpdated;

  CartSummary({
    required this.cartId,
    required this.itemsCount,
    required this.subtotal,
    required this.courseDiscountTotal,
    required this.voucherDiscountAmount,
    required this.voucherId,
    required this.voucherCode,
    required this.voucherName,
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
      courseDiscountTotal: (json['courseDiscountTotal'] as num?)?.toInt() ?? 0,
      voucherDiscountAmount: (json['voucherDiscountAmount'] as num?)?.toInt() ?? 0,
      voucherId: json['voucherId'],
      voucherCode: json['voucherCode'],
      voucherName: json['voucherName'],
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      isEmpty: json['isEmpty'] ?? true,
      lastUpdated: _parseDateTimeWithOffset(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'itemsCount': itemsCount,
      'subtotal': subtotal,
      'courseDiscountTotal': courseDiscountTotal,
      'voucherDiscountAmount': voucherDiscountAmount,
      'voucherId': voucherId,
      'voucherCode': voucherCode,
      'voucherName': voucherName,
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
      timestamp: _parseDateTimeWithOffset(json['timestamp']),
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
