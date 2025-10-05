import 'dart:convert';
import 'package:ottobit/models/cart_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final HttpService _httpService = HttpService();

  /// Get current cart
  Future<CartApiResponse<Cart>> getCart() async {
    try {
      print('CartService: Getting current cart');
      
      final response = await _httpService.get(
        '/v1/cart',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => Cart.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get cart: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error getting cart: $e');
    }
  }

  /// Create new cart
  Future<CartApiResponse<Cart>> createCart() async {
    try {
      print('CartService: Creating new cart');
      
      final response = await _httpService.post(
        '/v1/cart',
        body: <String, dynamic>{},
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => Cart.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to create cart: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error creating cart: $e');
    }
  }

  /// Delete entire cart
  Future<CartApiResponse<void>> deleteCart() async {
    try {
      print('CartService: Deleting cart');
      
      final response = await _httpService.delete(
        '/v1/cart',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, null);
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to delete cart: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error deleting cart: $e');
    }
  }

  /// Get cart summary
  Future<CartApiResponse<CartSummary>> getCartSummary() async {
    try {
      print('CartService: Getting cart summary');
      
      final response = await _httpService.get(
        '/v1/cart/summary',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => CartSummary.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get cart summary: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error getting cart summary: $e');
    }
  }

  /// Validate cart before checkout
  Future<CartApiResponse<void>> validateCart() async {
    try {
      print('CartService: Validating cart');
      
      final response = await _httpService.post(
        '/v1/cart/validate',
        body: <String, dynamic>{},
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, null);
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to validate cart: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error validating cart: $e');
    }
  }

  /// Get cart items
  Future<CartApiResponse<List<CartItem>>> getCartItems() async {
    try {
      print('CartService: Getting cart items');
      
      final response = await _httpService.get(
        '/v1/cart/items',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) {
          final list = data as List<dynamic>;
          return list
              .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList();
        });
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get cart items: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error getting cart items: $e');
    }
  }

  /// Add item to cart
  Future<CartApiResponse<CartItem>> addToCart(AddToCartRequest request) async {
    try {
      print('CartService: Adding item to cart: ${request.courseId}');
      
      final response = await _httpService.post(
        '/v1/cart/items',
        body: request.toJson(),
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => CartItem.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to add item to cart: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error adding item to cart: $e');
    }
  }

  /// Remove item from cart
  Future<CartApiResponse<void>> removeFromCart(String courseId) async {
    try {
      print('CartService: Removing item from cart: $courseId');
      
      final response = await _httpService.delete(
        '/v1/cart/items/$courseId',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, null);
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to remove item from cart: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error removing item from cart: $e');
    }
  }

  /// Update item price
  Future<CartApiResponse<CartItem>> updateItemPrice(String courseId, int newPrice) async {
    try {
      print('CartService: Updating item price: $courseId to $newPrice');
      
      final response = await _httpService.put(
        '/v1/cart/items/$courseId/price',
        body: {'unitPrice': newPrice},
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => CartItem.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to update item price: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error updating item price: $e');
    }
  }

  /// Validate item before adding to cart
  Future<CartApiResponse<void>> validateItem(CartValidationRequest request) async {
    try {
      print('CartService: Validating item: ${request.courseId}');
      
      final response = await _httpService.post(
        '/v1/cart/items/validate',
        body: request.toJson(),
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, null);
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to validate item: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error validating item: $e');
    }
  }

  /// Check if item exists in cart
  Future<CartApiResponse<bool>> checkItemExists(String courseId) async {
    try {
      print('CartService: Checking if item exists: $courseId');
      
      final response = await _httpService.get(
        '/v1/cart/items/exists/$courseId',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => data as bool);
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to check item existence: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error checking item existence: $e');
    }
  }

  /// Apply discount
  Future<CartApiResponse<Cart>> applyDiscount(String discountCode) async {
    try {
      print('CartService: Applying discount: $discountCode');
      
      final response = await _httpService.post(
        '/v1/cart/discount',
        body: {'discountCode': discountCode},
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => Cart.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to apply discount: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error applying discount: $e');
    }
  }

  /// Remove discount
  Future<CartApiResponse<Cart>> removeDiscount() async {
    try {
      print('CartService: Removing discount');
      
      final response = await _httpService.delete(
        '/v1/cart/discount',
        throwOnError: false,
      );

      print('CartService: Response status: ${response.statusCode}');
      print('CartService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return CartApiResponse.fromJson(jsonData, (data) => Cart.fromJson(data as Map<String, dynamic>));
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to remove discount: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('CartService: Exception: $e');
      throw Exception('Error removing discount: $e');
    }
  }
}
