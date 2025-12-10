import 'dart:convert';

import 'package:ottobit/models/lesson_note_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class LessonNoteService {
  static final LessonNoteService _instance = LessonNoteService._internal();
  factory LessonNoteService() => _instance;
  LessonNoteService._internal();

  final HttpService _http = HttpService();

  Future<LessonNote> createNote({
    required String lessonId,
    required String lessonResourceId,
    required String content,
    required int timestampInSeconds,
  }) async {
    try {
      final response = await _http.post(
        '/v1/lesson-notes',
        body: {
          'lessonId': lessonId,
          'lessonResourceId': lessonResourceId,
          'content': content,
          'timestampInSeconds': timestampInSeconds,
        },
        throwOnError: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return LessonNote.fromJson(data);
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể tạo ghi chú (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }

  Future<LessonNotePage> getMyNotes({
    required String lessonId,
    required String lessonResourceId,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _http.get(
        '/v1/lesson-notes/my-notes',
        queryParams: {
          'PageNumber': pageNumber.toString(),
          'PageSize': pageSize.toString(),
          'LessonId': lessonId,
          'LessonResourceId': lessonResourceId,
        },
        throwOnError: false,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return LessonNotePage.fromJson(data);
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể tải danh sách ghi chú (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }

  Future<LessonNote> updateNote({
    required String noteId,
    required String content,
    required int timestampInSeconds,
  }) async {
    try {
      final response = await _http.put(
        '/v1/lesson-notes/$noteId',
        body: {
          'content': content,
          'timestampInSeconds': timestampInSeconds,
        },
        throwOnError: false,
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        final data = jsonData['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
        return LessonNote.fromJson(data);
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể cập nhật ghi chú (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final response = await _http.delete(
        '/v1/lesson-notes/$noteId',
        throwOnError: false,
      );

      if (response.statusCode == 200) {
        return;
      }

      final friendly = ApiErrorMapper.fromBody(
        response.body,
        statusCode: response.statusCode,
        fallback: 'Không thể xoá ghi chú (${response.statusCode})',
      );
      throw Exception(friendly);
    } catch (e) {
      rethrow;
    }
  }
}


