import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ottobit/models/activation_code_model.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class ActivationCodeService {
  static const String _baseUrl = 'https://ottobit-be.felixtien.dev/api/v1';
  
  Future<ActivationCodeResponse> redeemCode(String code) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception(ApiErrorMapper.fromException('No authentication token found'));
      }

      final uri = Uri.parse('$_baseUrl/activation-codes/redeem');
      
      final request = ActivationCodeRequest(code: code);
      
      final response = await http.post(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('Activation code response status: ${response.statusCode}');
      print('Activation code response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Parsed JSON data: $jsonData');
        
        // Handle different response structures
        if (jsonData is Map<String, dynamic>) {
          return ActivationCodeResponse.fromJson(jsonData);
        } else {
          throw Exception('Unexpected response format: ${jsonData.runtimeType}');
        }
      } else {
        final errorMsg = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to redeem activation code',
        );
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('Activation code error: $e');
      final friendlyMsg = ApiErrorMapper.fromException(e);
      throw Exception(friendlyMsg);
    }
  }

  Future<ActivationCodeListApiResponse> getMyActivationCodes({
    int? status,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception(ApiErrorMapper.fromException('No authentication token found'));
      }

      final queryParams = <String, String>{
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      };
      if (status != null) {
        queryParams['status'] = status.toString();
      }

      final uri = Uri.parse('$_baseUrl/activation-codes/my').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ActivationCodeListApiResponse.fromJson(jsonData);
      } else {
        final errorMsg = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get activation codes',
        );
        throw Exception(errorMsg);
      }
    } catch (e) {
      final friendlyMsg = ApiErrorMapper.fromException(e);
      throw Exception(friendlyMsg);
    }
  }
}
