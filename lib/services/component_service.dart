import 'dart:convert';
import 'package:ottobit/models/component_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class ComponentService {
  static final ComponentService _instance = ComponentService._internal();
  factory ComponentService() => _instance;
  ComponentService._internal();

  final HttpService _httpService = HttpService();

  Future<ComponentApiResponse> getComponents({
    int page = 1,
    int size = 10,
    String? searchTerm,
    int? type,
    int? minPrice,
    int? maxPrice,
    bool? inStock,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      final queryParams = <String, String>{
        'Page': page.toString(),
        'Size': size.toString(),
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }
      if (type != null) {
        queryParams['Type'] = type.toString();
      }
      if (minPrice != null) {
        queryParams['MinPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['MaxPrice'] = maxPrice.toString();
      }
      if (inStock != null) {
        queryParams['InStock'] = inStock.toString();
      }
      if (orderBy != null && orderBy.isNotEmpty) {
        queryParams['OrderBy'] = orderBy;
      }
      if (orderDirection != null && orderDirection.isNotEmpty) {
        queryParams['OrderDirection'] = orderDirection;
      }

      print('ComponentService: Making request to /v1/components');
      print('ComponentService: Query params: $queryParams');

      final response = await _httpService.get(
        '/v1/components',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('ComponentService: Response status: ${response.statusCode}');
      print('ComponentService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('ComponentService: Parsed JSON: $jsonData');
        return ComponentApiResponse.fromJson(jsonData);
      } else {
        print(
          'ComponentService: Error response: ${response.statusCode} - ${response.body}',
        );
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load components: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('ComponentService error: $friendly');
      rethrow;
    }
  }

  Future<RobotComponentApiResponse> getRobotComponents({
    required String robotId,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'Page': page.toString(),
        'Size': size.toString(),
        'RobotId': robotId,
      };

      print('ComponentService: Making request to /v1/robot-components');
      print('ComponentService: Query params: $queryParams');

      final response = await _httpService.get(
        '/v1/robot-components',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('ComponentService: Response status: ${response.statusCode}');
      print('ComponentService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('ComponentService: Parsed JSON: $jsonData');
        return RobotComponentApiResponse.fromJson(jsonData);
      } else {
        print(
          'ComponentService: Error response: ${response.statusCode} - ${response.body}',
        );
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load robot components: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('ComponentService error (getRobotComponents): $friendly');
      rethrow;
    }
  }
}
