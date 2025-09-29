import 'dart:convert';

import 'package:ottobit/models/robot_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class RobotService {
  static final RobotService _instance = RobotService._internal();
  factory RobotService() => _instance;
  RobotService._internal();

  final HttpService _http = HttpService();

  Future<RobotsApiResponse> getRobots({
    int page = 1,
    int size = 10,
    String? searchTerm,
    String? brand,
    int? minPrice,
    int? maxPrice,
    int? minAge,
    int? maxAge,
    bool? inStock,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      final response = await _http.get(
        '/v1/robots',
        queryParams: {
          'Page': page.toString(),
          'Size': size.toString(),
          if (searchTerm != null && searchTerm.isNotEmpty) 'SearchTerm': searchTerm,
          if (brand != null && brand.isNotEmpty) 'Brand': brand,
          if (minPrice != null) 'MinPrice': minPrice.toString(),
          if (maxPrice != null) 'MaxPrice': maxPrice.toString(),
          if (minAge != null) 'MinAge': minAge.toString(),
          if (maxAge != null) 'MaxAge': maxAge.toString(),
          if (inStock != null) 'InStock': inStock.toString(),
          if (orderBy != null) 'OrderBy': orderBy,
          if (orderDirection != null) 'OrderDirection': orderDirection,
        },
        throwOnError: false,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return RobotsApiResponse.fromJson(jsonData);
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể tải danh sách robot (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }
}


