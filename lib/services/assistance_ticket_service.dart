import 'dart:convert';
import 'package:ottobit/models/assistance_ticket_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class AssistanceTicketService {
  static final AssistanceTicketService _instance = AssistanceTicketService._internal();
  factory AssistanceTicketService() => _instance;
  AssistanceTicketService._internal();

  final HttpService _httpService = HttpService();

  /// Create a new ticket
  Future<TicketApiResponse<AssistanceTicket>> createTicket(CreateTicketRequest request) async {
    try {
      print('AssistanceTicketService: Creating ticket');
      
      final response = await _httpService.post(
        '/v1/assistance-tickets',
        body: request.toJson(),
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => AssistanceTicket.fromJson(data as Map<String, dynamic>),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to create ticket: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error creating ticket: $e');
    }
  }

  /// Get all tickets for current user with filters
  Future<TicketApiResponse<PaginatedResponse<AssistanceTicket>>> getMyTickets({
    int page = 1,
    int size = 10,
    String? studentId,
    String? courseId,
    String? searchTerm,
    int? status,
    String? orderBy,
  }) async {
    try {
      print('AssistanceTicketService: Getting my tickets');
      
      final queryParams = <String, String>{
        'Page': page.toString(),
        'Size': size.toString(),
      };
      
      if (studentId != null) queryParams['StudentId'] = studentId;
      if (courseId != null) queryParams['CourseId'] = courseId;
      if (searchTerm != null && searchTerm.isNotEmpty) queryParams['SearchTerm'] = searchTerm;
      if (status != null) queryParams['Status'] = status.toString();
      if (orderBy != null) queryParams['OrderBy'] = orderBy;

      final response = await _httpService.get(
        '/v1/assistance-tickets/my',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => PaginatedResponse.fromJson(
            data as Map<String, dynamic>,
            (item) => AssistanceTicket.fromJson(item as Map<String, dynamic>),
          ),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get tickets: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error getting tickets: $e');
    }
  }

  /// Get ticket by ID
  Future<TicketApiResponse<AssistanceTicket>> getTicketById(String ticketId) async {
    try {
      print('AssistanceTicketService: Getting ticket: $ticketId');
      
      final response = await _httpService.get(
        '/v1/assistance-tickets/$ticketId',
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => AssistanceTicket.fromJson(data as Map<String, dynamic>),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get ticket: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error getting ticket: $e');
    }
  }

  /// Create a message in a ticket
  Future<TicketApiResponse<AssistanceMessage>> createMessage(CreateMessageRequest request) async {
    try {
      print('AssistanceTicketService: Creating message');
      
      final response = await _httpService.post(
        '/v1/assistance-messages',
        body: request.toJson(),
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => AssistanceMessage.fromJson(data as Map<String, dynamic>),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to create message: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error creating message: $e');
    }
  }

  /// Get messages for a ticket
  Future<TicketApiResponse<PaginatedResponse<AssistanceMessage>>> getTicketMessages({
    required String ticketId,
    int page = 1,
    int pageSize = 20,
    String? studentId,
    String? searchTerm,
    String? fromDate,
    String? toDate,
    String? orderBy,
  }) async {
    try {
      print('AssistanceTicketService: Getting messages for ticket: $ticketId');
      
      final queryParams = <String, String>{
        'Page': page.toString(),
        'PageSize': pageSize.toString(),
        'TicketId': ticketId,
      };
      
      if (studentId != null) queryParams['StudentId'] = studentId;
      if (searchTerm != null && searchTerm.isNotEmpty) queryParams['SearchTerm'] = searchTerm;
      if (fromDate != null) queryParams['FromDate'] = fromDate;
      if (toDate != null) queryParams['ToDate'] = toDate;
      if (orderBy != null) queryParams['OrderBy'] = orderBy;

      final response = await _httpService.get(
        '/v1/assistance-messages',
        queryParams: queryParams,
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => PaginatedResponse.fromJson(
            data as Map<String, dynamic>,
            (item) => AssistanceMessage.fromJson(item as Map<String, dynamic>),
          ),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get messages: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error getting messages: $e');
    }
  }

  /// Create rating for an assistance ticket
  Future<TicketApiResponse<AssistanceRating>> createRating(
    CreateAssistanceRatingRequest request,
  ) async {
    try {
      print('AssistanceTicketService: Creating assistance rating');

      final response = await _httpService.post(
        '/v1/assistance-ratings',
        body: request.toJson(),
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => AssistanceRating.fromJson(data as Map<String, dynamic>),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to create rating: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error creating rating: $e');
    }
  }

  /// Get rating by ticket id
  Future<TicketApiResponse<AssistanceRating>> getRatingByTicketId(
    String ticketId,
  ) async {
    try {
      print('AssistanceTicketService: Getting rating for ticket: $ticketId');

      final response = await _httpService.get(
        '/v1/assistance-ratings/by-ticket/$ticketId',
        throwOnError: false,
      );

      print('AssistanceTicketService: Response status: ${response.statusCode}');
      print('AssistanceTicketService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return TicketApiResponse.fromJson(
          jsonData,
          (data) => AssistanceRating.fromJson(data as Map<String, dynamic>),
        );
      } else {
        final friendly = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Failed to get rating: ${response.statusCode}',
        );
        throw Exception(friendly);
      }
    } catch (e) {
      print('AssistanceTicketService: Exception: $e');
      throw Exception('Error getting rating: $e');
    }
  }
}

