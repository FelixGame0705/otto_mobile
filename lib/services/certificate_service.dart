import 'dart:convert';
import 'package:ottobit/models/certificate_model.dart';
import 'package:ottobit/models/api_response.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CertificateService {
  static final CertificateService _instance = CertificateService._internal();
  factory CertificateService() => _instance;
  CertificateService._internal();

  // API endpoints
  static const String _certificatesEndpoint = '/v1/certificates/my';
  static const String _certificateTemplateEndpoint = '/v1/certificate-templates';

  // Get user's certificates with pagination and filters
  Future<ApiResponse<CertificateListResponse>> getMyCertificates({
    int page = 1,
    int size = 10,
    String? studentId,
    String? courseId,
    String? searchTerm,
    String? orderBy = 'updatedAt',
  }) async {
    try {
      final queryParams = <String, String>{
        'Page': page.toString(),
        'Size': size.toString(),
        'OrderBy': orderBy ?? 'updatedAt',
      };

      if (studentId != null && studentId.isNotEmpty) {
        queryParams['StudentId'] = studentId;
      }
      if (courseId != null && courseId.isNotEmpty) {
        queryParams['CourseId'] = courseId;
      }
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }

      final response = await HttpService().get(
        _certificatesEndpoint,
        queryParams: queryParams,
        throwOnError: false,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final certificateData = data['data'] as Map<String, dynamic>;
        final certificateList = CertificateListResponse.fromJson(certificateData);
        
        return ApiResponse.success(
          data: certificateList,
          message: data['message'] as String?,
          statusCode: response.statusCode,
        );
      } else {
        final message = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load certificates',
        );
        return ApiResponse.failure(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.failure(
        message: 'Error loading certificates: $e',
      );
    }
  }

  // Get certificate template by ID
  Future<ApiResponse<CertificateTemplate>> getCertificateTemplate(String templateId) async {
    try {
      final response = await HttpService().get(
        '$_certificateTemplateEndpoint/$templateId',
        throwOnError: false,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final templateData = data['data'] as Map<String, dynamic>;
        final template = CertificateTemplate.fromJson(templateData);
        
        return ApiResponse.success(
          data: template,
          message: data['message'] as String?,
          statusCode: response.statusCode,
        );
      } else {
        final message = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load certificate template',
        );
        return ApiResponse.failure(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.failure(
        message: 'Error loading certificate template: $e',
      );
    }
  }

  // Get certificate by ID (if needed for individual certificate details)
  Future<ApiResponse<Certificate>> getCertificate(String certificateId) async {
    try {
      final response = await HttpService().get(
        '$_certificatesEndpoint/$certificateId',
        throwOnError: false,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final certificateData = data['data'] as Map<String, dynamic>;
        final certificate = Certificate.fromJson(certificateData);
        
        return ApiResponse.success(
          data: certificate,
          message: data['message'] as String?,
          statusCode: response.statusCode,
        );
      } else {
        final message = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load certificate',
        );
        return ApiResponse.failure(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.failure(
        message: 'Error loading certificate: $e',
      );
    }
  }

  // Verify certificate by verification code
  Future<ApiResponse<Certificate>> verifyCertificate(String verificationCode) async {
    try {
      final response = await HttpService().get(
        '$_certificatesEndpoint/verify/$verificationCode',
        throwOnError: false,
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final certificateData = data['data'] as Map<String, dynamic>;
        final certificate = Certificate.fromJson(certificateData);
        
        return ApiResponse.success(
          data: certificate,
          message: data['message'] as String?,
          statusCode: response.statusCode,
        );
      } else {
        final message = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to verify certificate',
        );
        return ApiResponse.failure(
          message: message,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.failure(
        message: 'Error verifying certificate: $e',
      );
    }
  }
}
