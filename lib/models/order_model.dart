import 'package:intl/intl.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String courseId;
  final String courseTitle;
  final String courseDescription;
  final String courseImageUrl;
  final int unitPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.courseId,
    required this.courseTitle,
    required this.courseDescription,
    required this.courseImageUrl,
    required this.unitPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? '',
      orderId: json['orderId'] ?? '',
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'] ?? '',
      courseDescription: json['courseDescription'] ?? '',
      courseImageUrl: json['courseImageUrl'] ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(unitPrice)} VNĐ';
  }
}

class OrderModel {
  final String id;
  final String userId;
  final int subtotal;
  final int discountAmount;
  final int total;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.userId,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(total)} VNĐ';
  }
}

class PagedOrders {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<OrderModel> items;

  PagedOrders({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory PagedOrders.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json; // sometimes envelope
    return PagedOrders(
      size: (data['size'] as num?)?.toInt() ?? 0,
      page: (data['page'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CreateOrderRequest {
  final String cartId;
  CreateOrderRequest({required this.cartId});
  Map<String, dynamic> toJson() => {'cartId': cartId};
}

