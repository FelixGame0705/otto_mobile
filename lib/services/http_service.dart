import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ottobit/utils/constants.dart';
import 'package:ottobit/services/storage_service.dart';

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
      return _handleResponse(response, throwOnError: throwOnError);
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
      return _handleResponse(response, throwOnError: throwOnError);
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
      return _handleResponse(response, throwOnError: throwOnError);
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
      return _handleResponse(response, throwOnError: throwOnError);
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
      return _handleResponse(response, throwOnError: throwOnError);
    } catch (e) {
      throw HttpException('PATCH request failed: $e');
    }
  }

  // Xử lý response
  http.Response _handleResponse(
    http.Response response, {
    bool throwOnError = true,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      // Token hết hạn hoặc không hợp lệ
      _handleUnauthorized();
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
  void _handleUnauthorized() {
    // Clear token và redirect về login
    StorageService.clearToken();
    // Có thể emit event để app biết cần logout
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
      
      return _handleResponse(response);
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
