import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ottobit/models/activation_code_model.dart';
import 'package:ottobit/services/storage_service.dart';

class ActivationCodeService {
  static const String _baseUrl = 'https://ottobit-be.felixtien.dev/api/v1';
  
  Future<ActivationCodeResponse> redeemCode(String code) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
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
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData is Map<String, dynamic> 
              ? (errorData['message'] ?? 'Failed to redeem activation code')
              : 'Failed to redeem activation code';
          throw Exception(errorMessage);
        } catch (parseError) {
          throw Exception('Failed to redeem activation code: ${response.body}');
        }
      }
    } catch (e) {
      print('Activation code error: $e');
      throw Exception('Error redeeming activation code: $e');
    }
  }
}
