import 'dart:convert';
import 'package:ottobit/models/order_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final HttpService _httpService = HttpService();

  Future<OrderModel> createOrder({required String cartId}) async {
    try {
      print('OrderService: Creating order from cart: $cartId');
      final response = await _httpService.post(
        '/v1/orders',
        body: CreateOrderRequest(cartId: cartId).toJson(),
        throwOnError: false,
      );
      print('OrderService: Response status: ${response.statusCode}');
      print('OrderService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      }
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to create order: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      print('OrderService: Exception: $e');
      throw Exception('Error creating order: $e');
    }
  }

  Future<PagedOrders> getOrders({
    int page = 1,
    int size = 10,
    int? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final params = <String, String>{
        'Page': '$page',
        'Size': '$size',
      };
      if (status != null) params['Status'] = '$status';
      if (fromDate != null) params['FromDate'] = fromDate.toIso8601String();
      if (toDate != null) params['ToDate'] = toDate.toIso8601String();

      final query = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
      print('OrderService: Getting orders with $query');

      final response = await _httpService.get('/v1/orders?$query', throwOnError: false);
      print('OrderService: Response status: ${response.statusCode}');
      print('OrderService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>;
        return PagedOrders.fromJson({'data': data});
      }
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to get orders: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      print('OrderService: Exception: $e');
      throw Exception('Error getting orders: $e');
    }
  }

  Future<OrderModel> getOrderById(String orderId) async {
    try {
      print('OrderService: Getting order $orderId');
      final response = await _httpService.get('/v1/orders/$orderId', throwOnError: false);
      print('OrderService: Response status: ${response.statusCode}');
      print('OrderService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>;
        return OrderModel.fromJson(data);
      }
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to get order: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      print('OrderService: Exception: $e');
      throw Exception('Error getting order: $e');
    }
  }

  Future<String> initiatePayOS({
    required String paymentTransactionId,
    required String returnUrl,
    required String cancelUrl,
  }) async {
    try {
      final body = {
        'paymentTransactionId': paymentTransactionId,
        'returnUrl': returnUrl,
        'cancelUrl': cancelUrl,
      };
      final response = await _httpService.post(
        '/v1/payos/initiate',
        body: body,
        throwOnError: false,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>;
        final url = (data['paymentUrl'] ?? '').toString();
        if (url.isEmpty) {
          throw Exception('Missing paymentUrl');
        }
        return url;
      }
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to initiate payment: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      print('OrderService: Cancelling order $orderId');
      final response = await _httpService.put(
        '/v1/orders/$orderId/cancel',
        body: {},
        throwOnError: false,
      );
      print('OrderService: Cancel response status: ${response.statusCode}');
      print('OrderService: Cancel response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = jsonData['message'] ?? 'Order cancelled successfully';
        print('OrderService: $message');
        return;
      }
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to cancel order: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      print('OrderService: Cancel exception: $e');
      throw Exception('Error cancelling order: $e');
    }
  }
}


