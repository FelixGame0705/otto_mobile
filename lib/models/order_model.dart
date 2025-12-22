import 'package:intl/intl.dart';
import 'package:ottobit/utils/date_time_utils.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String courseId;
  final String courseTitle;
  final String courseDescription;
  final String courseImageUrl;
  final int unitPrice;
  final int discountAmount;
  final int finalPrice;
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
    required this.discountAmount,
    required this.finalPrice,
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
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      finalPrice: (json['finalPrice'] as num?)?.toInt() ?? (json['unitPrice'] as num?)?.toInt() ?? 0,
      createdAt: DateTimeUtils.parseDateTimeWithOffset(json['createdAt']),
      updatedAt: DateTimeUtils.parseDateTimeWithOffset(json['updatedAt']),
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
  final int courseDiscountTotal;
  final int voucherDiscountAmount;
  final int discountAmount;
  final int total;
  final int status;
  final String? voucherId;
  final String? voucherCode;
  final String? voucherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;
  final List<PaymentTransactionModel> paymentTransactions;

  OrderModel({
    required this.id,
    required this.userId,
    required this.subtotal,
    required this.courseDiscountTotal,
    required this.voucherDiscountAmount,
    required this.discountAmount,
    required this.total,
    required this.status,
    required this.voucherId,
    required this.voucherCode,
    required this.voucherName,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.paymentTransactions,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      courseDiscountTotal: (json['courseDiscountTotal'] as num?)?.toInt() ?? 0,
      voucherDiscountAmount: (json['voucherDiscountAmount'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      voucherId: json['voucherId'],
      voucherCode: json['voucherCode'],
      voucherName: json['voucherName'],
      createdAt: DateTimeUtils.parseDateTimeWithOffset(json['createdAt']),
      updatedAt: DateTimeUtils.parseDateTimeWithOffset(json['updatedAt']),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentTransactions: (json['paymentTransactions'] as List<dynamic>?)
              ?.map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(total)} VNĐ';
  }
}

class PaymentTransactionModel {
  final String id;
  final String orderId;
  final int type;
  final int method;
  final String? orderCode;
  final int amount;
  final int status;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentTransactionModel({
    required this.id,
    required this.orderId,
    required this.type,
    required this.method,
    required this.orderCode,
    required this.amount,
    required this.status,
    required this.errorCode,
    required this.errorMessage,
    required this.paidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: (json['id'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      type: (json['type'] as num?)?.toInt() ?? 0,
      method: (json['method'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode']?.toString(),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      errorCode: json['errorCode']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      paidAt: (json['paidAt'] != null && json['paidAt'].toString().isNotEmpty)
          ? DateTime.tryParse(json['paidAt'].toString())?.add(const Duration(hours: 7))
          : null,
      createdAt: DateTimeUtils.parseDateTimeWithOffset(json['createdAt'].toString()),
      updatedAt: DateTimeUtils.parseDateTimeWithOffset(json['updatedAt'].toString()),
    );
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

