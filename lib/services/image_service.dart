import 'dart:convert';

import 'package:ottobit/models/robot_image_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final HttpService _http = HttpService();

  Future<RobotImagePage> getRobotImages({
    required String robotId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final res = await _http.get(
        '/v1/images',
        queryParams: {
          'RobotId': robotId,
          'PageNumber': pageNumber.toString(),
          'PageSize': pageSize.toString(),
        },
        throwOnError: false,
      );

      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return RobotImagePage.fromJson(data);
      }

      final friendly = ApiErrorMapper.fromBody(
        res.body,
        statusCode: res.statusCode,
        fallback: 'Không thể tải danh sách ảnh (${res.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }
}


