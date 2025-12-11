import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ottobit/utils/constants.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/services/navigation_service.dart';
import 'package:ottobit/services/auth_service.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  late http.Client _client;
  String? _baseUrl;

  void init({String? baseUrl}) {
    _client = http.Client();
    _baseUrl = baseUrl ?? AppConstants.baseUrl;
  }

  void dispose() {
    _client.close();
  }

  // Headers với JWT token
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Chỉ thêm Authorization header khi includeAuth = true
    // Quan trọng: Khi gọi refresh token endpoint, phải set includeAuth = false
    // để không gửi accessToken cũ trong header, nếu không backend sẽ không trả về accessToken mới
    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool includeAuth = true,
    bool throwOnError = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    
    print('HttpService: Making GET request to: $uri');
    print('HttpService: Headers: $headers');
    
    try {
      final response = await _client.get(uri, headers: headers);
      print('HttpService: Response status: ${response.statusCode}');
      print('HttpService: Response body: ${response.body}');
      return await _handleResponse(response, throwOnError: throwOnError, endpoint: endpoint);
    } catch (e) {
      print('HttpService: GET request failed: $e');
      throw HttpException('GET request failed: $e');
    }
  }

  // POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool throwOnError = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return await _handleResponse(response, throwOnError: throwOnError, endpoint: endpoint);
    } catch (e) {
      throw HttpException('POST request failed: $e');
    }
  }

  // PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool throwOnError = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return await _handleResponse(response, throwOnError: throwOnError, endpoint: endpoint);
    } catch (e) {
      throw HttpException('PUT request failed: $e');
    }
  }

  // DELETE request
  Future<http.Response> delete(
    String endpoint, {
    bool includeAuth = true,
    bool throwOnError = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _client.delete(uri, headers: headers);
      return await _handleResponse(response, throwOnError: throwOnError, endpoint: endpoint);
    } catch (e) {
      throw HttpException('DELETE request failed: $e');
    }
  }

  // PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool includeAuth = true,
    bool throwOnError = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return await _handleResponse(response, throwOnError: throwOnError, endpoint: endpoint);
    } catch (e) {
      throw HttpException('PATCH request failed: $e');
    }
  }

  // Xử lý response
  Future<http.Response> _handleResponse(
    http.Response response, {
    bool throwOnError = true,
    String? endpoint, // Thêm endpoint để check xem có phải auth endpoint không
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      // Token hết hạn hoặc không hợp lệ
      // KHÔNG xử lý unauthorized cho các authentication endpoints
      // vì những endpoints này không cần token và không nên trigger token refresh
      final isAuthEndpoint = endpoint != null && (
        endpoint.contains('/authentications/login') ||
        endpoint.contains('/authentications/register') ||
        endpoint.contains('/authentications/login-google') ||
        endpoint.contains('/accounts/forgot-password') ||
        endpoint.contains('/Auth/reset-password') ||
        endpoint.contains('/authentications/refresh-token')
      );
      
      if (!isAuthEndpoint) {
        await _handleUnauthorized();
      }
      
      if (throwOnError) {
        throw HttpException('Unauthorized: Token expired or invalid');
      }
      return response;
    } else if (response.statusCode == 403) {
      if (throwOnError) {
        throw HttpException('Forbidden: Access denied');
      }
      return response;
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      if (throwOnError) {
        throw HttpException('Client error: ${response.statusCode}');
      }
      return response;
    } else if (response.statusCode >= 500) {
      if (throwOnError) {
        throw HttpException('Server error: ${response.statusCode}');
      }
      return response;
    } else {
      if (throwOnError) {
        throw HttpException('Unexpected error: ${response.statusCode}');
      }
      return response;
    }
  }

  // Xử lý khi token hết hạn
  Future<void> _handleUnauthorized() async {
    // Thử refresh token trước
    try {
      final refreshResult = await AuthService.refreshToken();
      if (refreshResult.isSuccess) {
        // Refresh thành công, không cần navigate
        return;
      }
    } catch (e) {
      // Refresh thất bại, tiếp tục logout
    }
    
    // Nếu refresh thất bại hoặc không có refresh token, navigate đến login
    await NavigationService().navigateToLogin(clearAuth: true);
  }

  // Upload file
  Future<http.Response> uploadFile(
    String endpoint, {
    required String filePath,
    String? fileName,
    Map<String, String>? fields,
    bool includeAuth = true,
  }) async {
    final headers = await _getHeaders(includeAuth: includeAuth);
    // Remove Content-Type để browser tự set multipart
    headers.remove('Content-Type');
    
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);
      
      // Add file
      final file = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      );
      request.files.add(file);
      
      // Add fields
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return await _handleResponse(response, endpoint: endpoint);
    } catch (e) {
      throw HttpException('File upload failed: $e');
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
