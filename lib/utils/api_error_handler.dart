import 'dart:convert';

/// Represents a standardized error parsed from backend responses.
class ApiError {
  final String? errorCode;
  final String? rawMessage;
  final int? statusCode;

  ApiError({this.errorCode, this.rawMessage, this.statusCode});

  /// Builds an [ApiError] from a decoded JSON map.
  factory ApiError.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    return ApiError(
      errorCode: (json['errorCode'] as String?)?.trim(),
      rawMessage: (json['message'] as String?)?.trim(),
      statusCode: statusCode,
    );
  }

  /// Tries to parse a response body (JSON string) into [ApiError].
  /// Returns null if parsing fails or body is not JSON.
  static ApiError? tryParseBody(String? body, {int? statusCode}) {
    if (body == null || body.isEmpty) return null;
    try {
      final jsonData = jsonDecode(body);
      if (jsonData is Map<String, dynamic>) {
        return ApiError.fromJson(jsonData, statusCode: statusCode);
      }
    } catch (_) {}
    return null;
  }
}

/// Centralized mapper for backend error codes/messages → user-friendly messages.
class ApiErrorMapper {
  /// Registry of errorCode → friendly message. Update here to customize.
  static final Map<String, String> _codeToMessage = <String, String>{
    // Lesson/Access
    'USER_003': 'Bạn cần hoàn thành các bài học trước đó trước khi xem nội dung này.',
    // Challenge/Access
    'CHA_009':
        'Bạn không thể truy cập thử thách này. Hãy hoàn thành các thử thách trước hoặc bắt đầu bài học.',
    // ================= Auth errors =================
    'AUTH_001': 'Email hoặc mật khẩu không đúng.', // INVALID_CREDENTIALS
    'AUTH_002': 'Tài khoản đã bị khóa. Vui lòng thử lại sau.', // ACCOUNT_LOCKED
    'AUTH_003': 'Email chưa được xác nhận. Vui lòng xác nhận email trước.', // EMAIL_NOT_CONFIRMED
    'AUTH_006': 'Refresh token không hợp lệ hoặc đã hết hạn.', // REFRESH_TOKEN_INVALID

    // ================= User errors =================
    'USER_001': 'Không tìm thấy người dùng.', // USER_NOT_FOUND
    'USER_002': 'Email đã được đăng ký.', // EMAIL_ALREADY_EXISTS
    'USER_005': 'Đổi mật khẩu thất bại: Mật khẩu hiện tại không chính xác.', // CURRENT_PASSWORD_INCORRECT
  };

  /// Optional mapping by HTTP status to a default message.
  static final Map<int, String> _statusToMessage = <int, String>{
    400: 'Yêu cầu không hợp lệ. Vui lòng kiểm tra và thử lại.',
    401: 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
    403: 'Bạn không có quyền thực hiện thao tác này.',
    404: 'Không tìm thấy tài nguyên.',
    500: 'Lỗi máy chủ. Vui lòng thử lại sau.',
  };

  /// Returns a friendly message from [ApiError].
  /// Priority: known errorCode → rawMessage (server) → statusCode default → generic.
  static String toFriendlyMessage(ApiError? error, {String? fallback}) {
    if (error == null) {
      return fallback?.trim().isNotEmpty == true
          ? fallback!.trim()
          : 'Đã xảy ra lỗi. Vui lòng thử lại.';
    }

    final code = error.errorCode?.trim();
    if (code != null && code.isNotEmpty) {
      final mapped = _codeToMessage[code];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }

    final serverMsg = error.rawMessage?.trim();
    if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;

    final status = error.statusCode;
    if (status != null) {
      final byStatus = _statusToMessage[status];
      if (byStatus != null && byStatus.isNotEmpty) return byStatus;
    }

    return fallback?.trim().isNotEmpty == true
        ? fallback!.trim()
        : 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  /// Convenience: derive a message from a response body string and optional status.
  static String fromBody(String? body, {int? statusCode, String? fallback}) {
    final err = ApiError.tryParseBody(body, statusCode: statusCode);
    return toFriendlyMessage(err, fallback: fallback);
  }

  /// Allows updating or adding mappings at runtime (e.g., feature flags or A/B tests).
  static void registerCodeMessage(String code, String message) {
    if (code.trim().isEmpty || message.trim().isEmpty) return;
    _codeToMessage[code.trim()] = message.trim();
  }

  /// Allows overriding default status messages.
  static void registerStatusMessage(int statusCode, String message) {
    if (message.trim().isEmpty) return;
    _statusToMessage[statusCode] = message.trim();
  }
}


