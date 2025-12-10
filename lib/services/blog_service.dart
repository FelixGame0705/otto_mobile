import 'dart:convert';
import 'package:ottobit/models/blog_model.dart';
import 'package:ottobit/models/blog_comment_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class BlogService {
  static final BlogService _instance = BlogService._internal();
  factory BlogService() => _instance;
  BlogService._internal();

  final HttpService _httpService = HttpService();

  /// Get blogs with pagination and search
  Future<BlogApiResponse> getBlogs({
    String? searchTerm,
    String? tagId,
    String? dateFrom,
    String? dateTo,
    int? readingTimeMin,
    int? readingTimeMax,
    int? viewCountMin,
    int? viewCountMax,
    String? sortBy,
    String? sortDirection,
    int pageNumber = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['SearchTerm'] = searchTerm;
      }
      if (tagId != null && tagId.isNotEmpty) {
        queryParams['TagId'] = tagId;
      }
      if (dateFrom != null && dateFrom.isNotEmpty) {
        queryParams['DateFrom'] = dateFrom;
      }
      if (dateTo != null && dateTo.isNotEmpty) {
        queryParams['DateTo'] = dateTo;
      }
      if (readingTimeMin != null) {
        queryParams['ReadingTimeMin'] = readingTimeMin.toString();
      }
      if (readingTimeMax != null) {
        queryParams['ReadingTimeMax'] = readingTimeMax.toString();
      }
      if (viewCountMin != null) {
        queryParams['ViewCountMin'] = viewCountMin.toString();
      }
      if (viewCountMax != null) {
        queryParams['ViewCountMax'] = viewCountMax.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['SortBy'] = sortBy;
      }
      if (sortDirection != null && sortDirection.isNotEmpty) {
        queryParams['SortDirection'] = sortDirection;
      }

      print('BlogService: Making request to /v1/Blog');
      print('BlogService: Query params: $queryParams');
      
      final response = await _httpService.get(
        '/v1/blogs',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('BlogService: Parsed JSON: $jsonData');
        return BlogApiResponse.fromJson(jsonData);
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load blogs: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (getBlogs): $friendly');
      throw Exception(friendly);
    }
  }

  /// Get a specific blog by slug
  Future<Blog?> getBlogBySlug(String slug) async {
    try {
      // Ensure slug is safely encoded for use in URL path (handles spaces, punctuation, unicode, etc.)
      final encodedSlug = Uri.encodeComponent(slug);
      print('BlogService: Making request to /v1/blogs/slug/$encodedSlug');
      
      final response = await _httpService.get(
        '/v1/blogs/slug/$encodedSlug',
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        if (jsonData['data'] != null) {
          return Blog.fromJson(jsonData['data']);
        }
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load blog: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
      return null;
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (getBlogBySlug): $friendly');
      throw Exception(friendly);
    }
  }

  /// Get all available tags
  Future<TagApiResponse> getTags({
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'PageNumber': pageNumber.toString(),
        'PageSize': pageSize.toString(),
      };

      print('BlogService: Making request to /v1/tags');
      print('BlogService: Query params: $queryParams');
      
      final response = await _httpService.get(
        '/v1/tags',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('BlogService: Parsed JSON: $jsonData');
        return TagApiResponse.fromJson(jsonData);
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load tags: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (getTags): $friendly');
      throw Exception(friendly);
    }
  }

  /// Get comments for a specific blog
  Future<BlogCommentApiResponse> getBlogComments({
    required String blogId,
    int page = 1,
    int size = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      print('BlogService: Making request to /v1/blog-comments/by-blog/$blogId');
      print('BlogService: Query params: $queryParams');
      
      final response = await _httpService.get(
        '/v1/blog-comments/by-blog/$blogId',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('BlogService: Parsed JSON: $jsonData');
        return BlogCommentApiResponse.fromJson(jsonData);
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to load comments: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (getBlogComments): $friendly');
      throw Exception(friendly);
    }
  }

  /// Create a new comment
  Future<BlogCommentCreateResponse> createComment({
    required String blogId,
    required String content,
  }) async {
    try {
      final body = {
        'blogId': blogId,
        'content': content,
      };

      print('BlogService: Making request to /v1/blog-comments');
      print('BlogService: Body: $body');
      
      final response = await _httpService.post(
        '/v1/blog-comments',
        body: body,
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('BlogService: Parsed JSON: $jsonData');
        return BlogCommentCreateResponse.fromJson(jsonData);
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to create comment: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (createComment): $friendly');
      throw Exception(friendly);
    }
  }

  /// Update a comment
  Future<BlogCommentUpdateResponse> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final body = {
        'content': content,
      };

      print('BlogService: Making request to /v1/blog-comments/$commentId');
      print('BlogService: Body: $body');
      
      final response = await _httpService.put(
        '/v1/blog-comments/$commentId',
        body: body,
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('BlogService: Parsed JSON: $jsonData');
        return BlogCommentUpdateResponse.fromJson(jsonData);
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to update comment: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (updateComment): $friendly');
      throw Exception(friendly);
    }
  }

  /// Delete a comment
  Future<BlogCommentDeleteResponse> deleteComment({
    required String commentId,
  }) async {
    try {
      print('BlogService: Making request to /v1/blog-comments/$commentId');
      
      final response = await _httpService.delete(
        '/v1/blog-comments/$commentId',
        throwOnError: false,
      );

      print('BlogService: Response status: ${response.statusCode}');
      print('BlogService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        print('BlogService: Parsed JSON: $jsonData');
        return BlogCommentDeleteResponse.fromJson(jsonData);
      } else {
        print('BlogService: Error response: ${response.statusCode} - ${response.body}');
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to delete comment: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      final friendly = ApiErrorMapper.fromException(e);
      print('BlogService error (deleteComment): $friendly');
      throw Exception(friendly);
    }
  }
}
