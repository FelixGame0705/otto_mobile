import 'dart:convert';
import 'package:ottobit/models/product_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  final HttpService _httpService = HttpService();

  Future<ProductApiResponse> getProductDetail(String productId, {String productType = 'robot'}) async {
    try {
      final path = productType == 'component' ? '/v1/components/$productId' : '/v1/robots/$productId';
      print('ProductService: Making request to $path');
      final response = await _httpService.get(path, throwOnError: false);
      print('ProductService: Response status: ${response.statusCode}');
      print('ProductService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('ProductService: Parsed JSON: $jsonData');
        return ProductApiResponse.fromJson(jsonData);
      }
      
      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Failed to load product: ${response.statusCode}',
      );
      throw Exception(friendly);
    } catch (e) {
      print('ProductService: Exception: $e');
      rethrow;
    }
  }
}
