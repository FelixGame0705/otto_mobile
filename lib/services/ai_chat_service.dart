import 'dart:convert';

import 'package:ottobit/services/http_service.dart';

class AiChatService {
  final HttpService _http = HttpService();

  Future<String> sendMessage(String message) async {
    try {
      final res = await _http.post(
        '/v1/chatbot/chat',
        body: {
          'message': message,
        },
        throwOnError: false,
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        return (data?['message'] as String?) ?? '';
      }

      // Non-200: try parse server message; otherwise generic
      try {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final serverMsg = (json['message'] as String?)?.trim();
        throw Exception(serverMsg?.isNotEmpty == true ? serverMsg : 'Chat failed (${res.statusCode})');
      } catch (_) {
        throw Exception('Chat failed (${res.statusCode})');
      }
    } catch (e) {
      throw Exception('Chat failed: ${e.toString()}');
    }
  }
}


