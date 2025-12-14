import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ottobit/services/navigation_service.dart';

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
    // ================= AUTH errors =================
    'AUTH_001': 'Email hoặc mật khẩu không đúng.',
    'AUTH_002': 'Tài khoản đã bị khóa. Vui lòng thử lại sau.',
    'AUTH_003': 'Email chưa được xác nhận. Vui lòng xác nhận email trước.',
    'AUTH_004': 'Token không hợp lệ hoặc đã hết hạn.',
    'AUTH_005': 'Token có thể không hợp lệ hoặc đã hết hạn.',
    'AUTH_006': 'Refresh token không hợp lệ hoặc đã hết hạn.',
    'AUTH_007': 'Người dùng chưa được xác thực.',
    'AUTH_008': 'Email đã được xác nhận trước đó.',

    // ================= USER errors =================
    'USER_001': 'Không tìm thấy người dùng.',
    'USER_002': 'Email đã được đăng ký.',
    'USER_003':
        'Bạn cần hoàn thành các bài học trước đó trước khi xem nội dung này.',
    'USER_005':
        'Đổi mật khẩu thất bại: Mật khẩu hiện tại không chính xác.',
    'USER_006': 'Thao tác với người dùng thất bại. Vui lòng thử lại.',
    'USER_007': 'Người dùng chưa được xác thực.',

    // ================= VALIDATION errors =================
    'VAL_001': 'Dữ liệu không hợp lệ hoặc thiếu thông tin bắt buộc.',
    'VAL_002': 'Định dạng email không hợp lệ.',
    'VAL_003': 'Mật khẩu không đúng định dạng yêu cầu.',
    'VAL_004': 'Mật khẩu xác nhận không khớp.',

    // ================= COURSE / MAP / ROBOT / COMPONENT / IMAGE =================
    'COU_001': 'Không tìm thấy khóa học.',
    'COU_006': 'Khóa học không có thử thách để theo dõi tiến trình.',
    'CR_001': 'Không tìm thấy cấu hình robot cho khóa học.',
    'CR_002': 'Cấu hình robot cho khóa học đã tồn tại hoặc không thể xoá.',

    'MAP_001': 'Không tìm thấy bản đồ.',
    'MAP_002': 'Đã tồn tại bản đồ với tiêu đề này.',
    'MAP_004': 'Không thể xóa bản đồ đang được sử dụng bởi các thử thách.',
    'MAP_005': 'Bản đồ được chọn không thuộc về khóa học này.',

    'COURSEMAP_001': 'Không tìm thấy bản đồ khóa học.',
    'COURSEMAP_002': 'Bản đồ này đã được gán cho khóa học.',

    'ROB_001': 'Không tìm thấy robot.',
    'ROB_002': 'Đã tồn tại robot với tên và model này.',

    'COM_001': 'Không tìm thấy linh kiện.',
    'COM_002': 'Đã tồn tại linh kiện với tên này.',

    'IMG_001': 'Không tìm thấy hình ảnh.',

    // ================= LESSON errors =================
    'LES_001': 'Không tìm thấy bài học hoặc bài học đã bị xoá.',
    'LES_005': 'Bạn không có quyền truy cập bài học hoặc tài nguyên này.',
    'LES_007':
        'Bài học đang bị khoá. Hãy hoàn thành các bài học trước đó trước khi tiếp tục.',
    'LES_008': 'Bài học này đã được hoàn thành.',
    'LES_009':
        'Không tìm thấy tiến trình bài học. Vui lòng bắt đầu bài học trước.',
    'LES_010': 'Trạng thái tiến trình bài học không hợp lệ.',
    'LEN_001':
        'Không tìm thấy ghi chú bài học hoặc bạn không có quyền truy cập.',
    'LEN_002':
        'Không tìm thấy tài nguyên bài học hoặc tài nguyên không thuộc bài học này.',

    // ================= CHALLENGE errors =================
    'CHA_001': 'Không tìm thấy thử thách hoặc thử thách đã bị xoá.',
    'CHA_004': 'Không tìm thấy bài học của thử thách này.',
    'CHA_005':
        'Bạn không thể truy cập thử thách hoặc lời giải này. Hãy hoàn thành các thử thách trước hoặc bắt đầu bài học.',
    'CHA_009':
        'Bạn không thể nộp bài/truy cập thử thách này. Hãy hoàn thành các thử thách trước hoặc bắt đầu bài học.',
    'CHA_010': 'Lời giải cho thử thách này hiện chưa khả dụng.',

    // ================= CART / ORDER / PAYMENT =================
    'CART_001': 'Không tìm thấy giỏ hàng.',
    'CART_002': 'Giỏ hàng đã tồn tại cho người dùng này.',
    'CART_003': 'ID giỏ hàng không khớp với giỏ hàng của người dùng.',
    'CART_004': 'Không tìm thấy sản phẩm trong giỏ hàng.',
    'CART_005': 'Khoá học đã tồn tại trong giỏ hàng.',
    'CART_006':
        'Khoá học này yêu cầu robot tương thích. Vui lòng kích hoạt robot phù hợp trước khi mua.',
    'CART_007': 'Giỏ hàng đang trống.',
    'CART_008': 'Mã giảm giá không hợp lệ.',

    'ORDER_001': 'Không tìm thấy đơn hàng.',
    'ORDER_004':
        'Trạng thái đơn hàng không hợp lệ hoặc không thể chuyển đổi trạng thái này.',
    'ORDER_006': 'Khoá học đã tồn tại trong đơn hàng.',

    'PAY_001': 'Không tìm thấy giao dịch thanh toán.',
    'PAY_005': 'Thanh toán không còn ở trạng thái chờ xử lý.',
    'PAY_006': 'Bạn không có quyền truy cập thanh toán này.',
    'PAY_007':
        'Đây là khóa học trả phí. Vui lòng hoàn tất thanh toán trước khi ghi danh.',

    // ================= BLOG / TAG / COMMENT / TICKET / RATING =================
    'BLOG_001': 'Không tìm thấy bài viết hoặc bài viết đã bị xoá.',
    'BLOG_003': 'Đã tồn tại bài viết với tiêu đề này.',

    'TAG_001': 'Không tìm thấy thẻ (tag).',
    'TAG_003': 'Đã tồn tại thẻ (tag) với tên này.',
    'TAG_004': 'Không thể xoá thẻ đang được sử dụng trong các bài viết.',

    'COMMENT_001': 'Không tìm thấy bình luận.',

    'TICKET_001':
        'Không tìm thấy phiếu hỗ trợ hoặc bạn không có quyền truy cập.',
    'TICKET_004':
        'Không thể gán phiếu hỗ trợ đã đóng hoặc phiếu hỗ trợ đã được đóng.',

    'RATING_001':
        'Không tìm thấy đánh giá hoặc đánh giá không tồn tại cho phiếu hỗ trợ này.',

    // ================= STUDENT / ENROLLMENT / SUBMISSION / VOUCHER / ACTIVATION =================
    // Student profile missing / not registered
    'STU_001': 'Bạn chưa là học viên. Vui lòng đăng ký học viên để tiếp tục.',
    'STU_005': 'Hồ sơ học sinh đã tồn tại cho người dùng này.',

    'ENR_001': 'Học sinh chưa đăng ký khóa học này.',
    'ENR_002': 'Học sinh đã ghi danh khóa học này.',
    'ENR_003': 'Dữ liệu ghi danh không hợp lệ.',
    'ENR_004': 'Không tìm thấy học sinh cho lượt ghi danh này.',
    'ENR_005': 'Không tìm thấy khoá học cho lượt ghi danh này.',
    'ENR_006': 'Khóa học này đã được hoàn thành.',
    'ENR_007': 'Bạn không có quyền thực hiện thao tác này.',
    'ENR_008': 'Tiến độ khóa học của bạn phải đạt ít nhất 50% để có thể đánh giá.',

    'SUB_001':
        'Không tìm thấy bài nộp hoặc bạn không có quyền xem bài nộp này.',
    'SUB_004': 'Không tìm thấy thử thách cho bài nộp này.',
    'SUB_005': 'Không tìm thấy học sinh cho bài nộp này.',

    'VOU_001': 'Không tìm thấy voucher hoặc voucher đã bị xoá.',
    'VOU_003': 'Mã voucher đã tồn tại.',
    'VOU_005': 'Voucher chưa bắt đầu hiệu lực.',
    'VOU_006': 'Voucher đã hết hạn.',
    'VOU_007': 'Voucher đã đạt giới hạn sử dụng.',
    'VOU_008': 'Voucher không còn khả dụng.',
    'VOU_012': 'Voucher không còn khả dụng hoặc đã đạt giới hạn sử dụng.',

    'VOU_USAGE_001': 'Không tìm thấy lịch sử sử dụng voucher.',

    'AC_001': 'Không tìm thấy mã kích hoạt.',
    'AC_002':
        'Số lượng mã kích hoạt không hợp lệ. Số lượng phải từ 1 đến 10000.',
    'AC_003': 'Thời gian hết hạn phải ở tương lai.',
    'AC_004': 'Không thể thay đổi trạng thái của mã kích hoạt đã được sử dụng.',
    'AC_005': 'Mã kích hoạt chưa ở trạng thái hoạt động.',
    'AC_006':
        'Bạn đã kích hoạt một mã cho robot này trước đó. Không thể kích hoạt thêm.',

    // ================= SYSTEM / GENERAL =================
    'SYS_001': 'Lỗi hệ thống nội bộ. Vui lòng thử lại sau.',
    'GEN_005': 'Lỗi hệ thống nội bộ. Vui lòng thử lại sau.',
    'SYS_002': 'Đã xảy ra lỗi khi gửi email xác nhận.',
    'SYS_003': 'Lỗi khi gọi dịch vụ bên ngoài. Vui lòng thử lại sau.',
    'SYS_004': 'Lỗi cấu hình hệ thống.',

    'GEN_001': 'Dữ liệu đầu vào không hợp lệ.',
    'GEN_002':
        'Thao tác không hợp lệ (ví dụ: không thể khóa tài khoản admin, không thể đóng phiếu hỗ trợ này).',
    'GEN_003':
        'Dữ liệu bị trùng lặp (ví dụ: bạn đã đánh giá phiếu hỗ trợ này trước đó).',
    'GEN_004': 'Bạn không có quyền thực hiện thao tác này.',
    
    // ================= RATING errors =================
    'PERMISSION_DENIED': 'Tiến độ khóa học của bạn phải đạt ít nhất 50% để có thể đánh giá.',

    'BGJ_001': 'Lỗi khi xử lý hết hạn đơn hàng trong nền.',

    // ================= CERTIFICATE / MESSAGE / PAYOS =================
    'CT_001': 'Không tìm thấy mẫu chứng chỉ.',
    'CER_001': 'Không tìm thấy chứng chỉ.',
    'MESSAGE_001': 'Không tìm thấy tin nhắn.',
    'PAYOS_001':
        'Yêu cầu webhook không hợp lệ hoặc payload webhook không hợp lệ.',
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
  /// Priority for Vietnamese: known errorCode → rawMessage (server) → statusCode default → generic.
  /// Priority for English: rawMessage (server) → statusCode default → generic.
  /// If [isEnglish] is true, always returns rawMessage from backend instead of mapped Vietnamese message.
  static String toFriendlyMessage(ApiError? error, {String? fallback, bool? isEnglish}) {
    if (error == null) {
      final defaultMsg = (isEnglish == true) 
          ? 'An error occurred. Please try again.'
          : 'Đã xảy ra lỗi. Vui lòng thử lại.';
      return fallback?.trim().isNotEmpty == true
          ? fallback!.trim()
          : defaultMsg;
    }

    // Check if locale is English (use parameter or try to detect)
    final isEn = isEnglish ?? _isEnglishLocale();

    // For English: Always prioritize rawMessage from backend first
    if (isEn) {
      final serverMsg = error.rawMessage?.trim();
      if (serverMsg != null && serverMsg.isNotEmpty) {
        final lower = serverMsg.toLowerCase();
        // Normalize noisy prerequisite lesson errors from backend/.NET
        if (lower.contains('previous lessons must be completed first') ||
            lower.contains("no authentication handler is registered for the scheme 'previous lessons must be completed first'")) {
          return 'Previous lessons must be completed first.';
        }
        return serverMsg;
      }
      
      // If no rawMessage, try status code message
      final status = error.statusCode;
      if (status != null) {
        final englishStatusMsg = _getEnglishStatusMessage(status);
        if (englishStatusMsg != null && englishStatusMsg.isNotEmpty) {
          return englishStatusMsg;
        }
      }
      
      // Fallback to generic English message
      return fallback?.trim().isNotEmpty == true
          ? fallback!.trim()
          : 'An error occurred. Please try again.';
    }

    // For Vietnamese: Use mapped messages first, then translate rawMessage if available
    // Special-case: if server message is known, translate it first to bypass wrong errorCode mapping
    final serverMsg = error.rawMessage?.trim();
    if (serverMsg != null && serverMsg.isNotEmpty) {
      final translatedEarly = _translateCommonMessage(serverMsg);
      if (translatedEarly != null) return translatedEarly;
    }

    final code = error.errorCode?.trim();
    if (code != null && code.isNotEmpty) {
      final mapped = _codeToMessage[code];
      if (mapped != null && mapped.isNotEmpty) {
        return mapped;
      }
    }

    // If no mapped message but have rawMessage, try to translate it
    if (serverMsg != null && serverMsg.isNotEmpty) {
      // Try to find translation for common messages
      final translated = _translateCommonMessage(serverMsg);
      if (translated != null) return translated;
      // If no translation found, return rawMessage (will be in English)
      return serverMsg;
    }

    // Try status code message
    final status = error.statusCode;
    if (status != null) {
      final byStatus = _statusToMessage[status];
      if (byStatus != null && byStatus.isNotEmpty) {
        return byStatus;
      }
    }

    // Final fallback
    return fallback?.trim().isNotEmpty == true
        ? fallback!.trim()
        : 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  /// Current locale cache (updated when locale changes)
  static Locale? _currentLocale;

  /// Check if current locale is English
  /// Tries multiple methods to get locale
  static bool _isEnglishLocale() {
    try {
      // Method 1: Use cached locale if available
      if (_currentLocale != null) {
        return _currentLocale!.languageCode == 'en';
      }

      // Method 2: Try to get locale from navigator context
      final navKey = navigatorKey;
      final context = navKey?.currentContext;
      if (context != null) {
        final locale = context.locale;
        _currentLocale = locale; // Cache it
        return locale.languageCode == 'en';
      }
    } catch (_) {
      // If context is not available, default to Vietnamese
    }
    return false; // Default to Vietnamese
  }

  /// Navigator key for accessing context (should be set from main app)
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Set the navigator key to enable automatic locale detection
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Get navigator key from NavigationService if available
  static GlobalKey<NavigatorState>? get navigatorKey {
    try {
      // Try to get from NavigationService first
      final navService = NavigationService();
      if (navService.navigatorKey != null) {
        return navService.navigatorKey;
      }
    } catch (_) {
      // Fallback to local key
    }
    return _navigatorKey;
  }

  /// Update current locale (should be called when locale changes)
  static void updateLocale(Locale locale) {
    _currentLocale = locale;
  }

  /// Get English status messages
  static String? _getEnglishStatusMessage(int statusCode) {
    const englishStatusMessages = <int, String>{
      400: 'Invalid request. Please check and try again.',
      401: 'Session expired or invalid. Please log in again.',
      403: 'You do not have permission to perform this action.',
      404: 'Resource not found.',
      500: 'Server error. Please try again later.',
    };
    return englishStatusMessages[statusCode];
  }

  /// Convenience: derive a message from a response body string and optional status.
  static String fromBody(String? body, {int? statusCode, String? fallback, bool? isEnglish}) {
    final err = ApiError.tryParseBody(body, statusCode: statusCode);
    return toFriendlyMessage(err, fallback: fallback, isEnglish: isEnglish);
  }

  /// Convenience: derive a friendly message from an [error] object (e.g. Exception),
  /// stripping common prefixes like "Exception: " and optionally parsing JSON bodies.
  ///
  /// - Loại bỏ tất cả các pattern "Exception:" hoặc "Exception: " trong message
  /// - Nếu chuỗi bên trong trông giống JSON (bắt đầu bằng '{' và kết thúc bằng '}'),
  ///   hàm sẽ gọi [fromBody] để map theo `errorCode` / `message`.
  /// - Ngược lại, trả về phần message đã được làm sạch (không còn tiền tố "Exception: ").
  /// - Nếu [isEnglish] là true, trả về message gốc từ backend thay vì message đã dịch.
  /// - Đảm bảo không có duplicate messages (tiếng Việt và tiếng Anh cùng lúc).
  static String fromException(
    Object error, {
    int? statusCode,
    String? fallback,
    bool? isEnglish,
  }) {
    final raw = error.toString().trim();
    final defaultMsg = (isEnglish == true)
        ? 'An error occurred. Please try again.'
        : 'Đã xảy ra lỗi. Vui lòng thử lại.';
    
    if (raw.isEmpty) {
      return fallback?.trim().isNotEmpty == true
          ? fallback!.trim()
          : defaultMsg;
    }

    // Loại bỏ tất cả các pattern "Exception:" hoặc "Exception: " ở mọi vị trí
    // Sử dụng regex để loại bỏ tất cả các occurrence (case-insensitive)
    String cleaned = raw.replaceAll(RegExp(r'Exception:\s*', caseSensitive: false), '').trim();

    // Kiểm tra và loại bỏ duplicate messages (tiếng Việt và tiếng Anh cùng lúc)
    if (cleaned.contains('Đã xảy ra lỗi') && cleaned.contains('An error occurred')) {
      final isEn = isEnglish ?? _isEnglishLocale();
      if (isEn) {
        // Lấy phần tiếng Anh (từ "An error occurred" đến trước "Đã xảy ra lỗi")
        final englishStart = cleaned.indexOf('An error occurred');
        final vietnameseStart = cleaned.indexOf('Đã xảy ra lỗi', englishStart);
        if (englishStart >= 0) {
          if (vietnameseStart > englishStart) {
            cleaned = cleaned.substring(englishStart, vietnameseStart).trim();
          } else {
            cleaned = cleaned.substring(englishStart).trim();
          }
        }
      } else {
        // Lấy phần tiếng Việt (từ "Đã xảy ra lỗi" đến trước "An error occurred")
        final vietnameseStart = cleaned.indexOf('Đã xảy ra lỗi');
        final englishStart = cleaned.indexOf('An error occurred', vietnameseStart);
        if (vietnameseStart >= 0) {
          if (englishStart > vietnameseStart) {
            cleaned = cleaned.substring(vietnameseStart, englishStart).trim();
          } else {
            cleaned = cleaned.substring(vietnameseStart).trim();
          }
        }
      }
    }

    // Nếu phần còn lại là JSON thì parse qua fromBody,
    // ngược lại trả về nguyên văn (đã được service map sẵn nếu có).
    final looksLikeJson = cleaned.startsWith('{') &&
        (cleaned.endsWith('}') || cleaned.endsWith('}\n'));

    if (looksLikeJson) {
      return fromBody(cleaned, statusCode: statusCode, fallback: fallback, isEnglish: isEnglish);
    }

    return cleaned.isNotEmpty
        ? cleaned
        : (fallback?.trim().isNotEmpty == true
            ? fallback!.trim()
            : defaultMsg);
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

  /// Translate common English error messages to Vietnamese
  static String? _translateCommonMessage(String englishMessage) {
    final lowerMsg = englishMessage.toLowerCase();
    
    // Common enrollment/rating error messages
    if (lowerMsg.contains('student is not enrolled') || 
        lowerMsg.contains('not enrolled in this course')) {
      return 'Học sinh chưa đăng ký khóa học này.';
    }
    
    if (lowerMsg.contains('course progress must be at least 50%') ||
        lowerMsg.contains('progress must be at least 50% to rate')) {
      return 'Tiến độ khóa học của bạn phải đạt ít nhất 50% để có thể đánh giá.';
    }

    // Lessons prerequisites
    if (lowerMsg.contains('previous lessons must be completed first')) {
      return 'Bạn cần hoàn thành các bài học trước đó trước khi tiếp tục.';
    }
    // .NET auth handler misconfiguration message containing the prerequisite text
    if (lowerMsg.contains("no authentication handler is registered for the scheme 'previous lessons must be completed first'")
        || lowerMsg.contains("previous lessons must be completed first'. the registered schemes are")) {
      return 'Bạn cần hoàn thành các bài học trước đó trước khi tiếp tục.';
    }

    // Student not found / not registered
    if (lowerMsg.contains('student not found') ||
        lowerMsg.contains('no student found') ||
        lowerMsg.contains('student profile not found')) {
      return 'Bạn chưa là học viên. Vui lòng đăng ký học viên để tiếp tục.';
    }

    // Price changed between add-to-cart and checkout
    if (lowerMsg.contains('price has changed for course')) {
      return 'Giá khóa học đã thay đổi. Vui lòng tải lại giỏ hàng.';
    }

    // Robot compatibility / activation
    if (lowerMsg.contains('you do not have an activated robot compatible with this course')) {
      return 'Bạn chưa có robot đã kích hoạt tương thích với khóa học này.';
    }
    
    // Blog comment error messages - check exact phrases
    if (lowerMsg == 'please wait a few seconds before commenting again.' ||
        lowerMsg.contains('please wait a few seconds before commenting again')) {
      return 'Vui lòng đợi vài giây trước khi bình luận lại.';
    }
    
    if (lowerMsg == 'too many comments in a short time. please try again later.' ||
        lowerMsg.contains('too many comments in a short time')) {
      return 'Bạn đã bình luận quá nhiều trong thời gian ngắn. Vui lòng thử lại sau.';
    }
    
    if (lowerMsg == 'duplicate comment detected.' ||
        lowerMsg.contains('duplicate comment detected')) {
      return 'Phát hiện bình luận trùng lặp.';
    }
    
    // Add more common translations as needed
    return null;
  }
}


