import 'dart:convert';
import 'package:ottobit/models/user_model.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/services/jwt_token_manager.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // API endpoints
  static const String _loginEndpoint = '/v1/authentications/login';
  static const String _registerEndpoint = '/v1/authentications/register';
  static const String _forgotPasswordEndpoint = '/v1/accounts/forgot-password';
  static const String _resetPasswordEndpoint = '/Auth/reset-password';
  static const String _refreshTokenEndpoint = '/v1/authentications/refresh-token';
  static const String _logoutEndpoint = '/Auth/logout';
  static const String _profileEndpoint = '/v1/accounts/profile';

  // Đăng nhập
  static Future<AuthResult> login(String email, String password) async {
    try {
      final response = await HttpService().post(
        _loginEndpoint,
        body: {
          'email': email,
          'password': password,
        },
        includeAuth: false, // Không cần token cho đăng nhập
        throwOnError: false,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final envelope = data['data'] as Map<String, dynamic>;
        final userMap = (envelope['user'] ?? {}) as Map<String, dynamic>;
        final tokens = (envelope['tokens'] ?? {}) as Map<String, dynamic>;

        final accessToken = tokens['accessToken'] as String? ?? '';
        final refreshToken = tokens['refreshToken'] as String? ?? '';
        final expiresAtUtcStr = tokens['expiresAtUtc'] as String?;

        await StorageService.saveToken(accessToken);
        await StorageService.saveRefreshToken(refreshToken);

        DateTime? expiryTime;
        if (expiresAtUtcStr != null && expiresAtUtcStr.isNotEmpty) {
          try {
            expiryTime = DateTime.parse(expiresAtUtcStr).toLocal();
          } catch (_) {}
        }
        if (expiryTime == null) {
          final tokenPayload = JwtTokenManager.getTokenPayload(accessToken);
          final exp = tokenPayload != null ? tokenPayload['exp'] : null;
          if (exp != null) {
            expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          }
        }
        if (expiryTime != null) {
          await StorageService.saveTokenExpiry(expiryTime);
        }

        final user = UserModel(
          id: (userMap['userId'] ?? userMap['id'] ?? '').toString(),
          fullName: (userMap['fullName'] ?? '').toString(),
          email: (userMap['email'] ?? email).toString(),
          phone: (userMap['phone'] ?? '').toString(),
          avatar: (userMap['avatar'] ?? '')?.toString(),
          createdAt: DateTime.now(),
          isActive: true,
        );

        await StorageService.saveUser(user);

        await StorageService.saveLastLoginInfo(
          email: email,
          loginTime: DateTime.now(),
        );

        return AuthResult.success(user: user);
      } else {
        final message = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Đăng nhập thất bại',
        );
        return AuthResult.failure(message: message);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }

  // Đăng nhập bằng Google: gửi googleIdToken lên backend và trả về toàn bộ response map để UI hiển thị
  static Future<Map<String, dynamic>> loginWithGoogle(String googleIdToken) async {
    try {
      final response = await HttpService().post(
        '/v1/authentications/login-google',
        body: {
          'googleIdToken': googleIdToken,
        },
        includeAuth: false,
        throwOnError: false,
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {
        'message': 'Login Google failed',
        'error': e.toString(),
      };
    }
  }

  // Đăng ký
  static Future<AuthResult> register({
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await HttpService().post(
        _registerEndpoint,
        body: {
          'email': email,
          'password': password,
          'confirmPassword': password,
        },
        includeAuth: false,
        throwOnError: false,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        final payload = data['data'] as Map<String, dynamic>;
        final user = UserModel(
          id: (payload['userId'] ?? '').toString(),
          fullName: (payload['fullName'] ?? '').toString(),
          email: (payload['email'] ?? email).toString(),
          phone: phone,
          avatar: '',
          createdAt: DateTime.now(),
          isActive: true,
        );
        await StorageService.saveUser(user);
        final requiresConfirmation = payload['requiresEmailConfirmation'] == true;
        final successMsg = requiresConfirmation
            ? (data['message'] ?? 'Đăng ký thành công, vui lòng xác nhận email')
            : (data['message'] ?? 'Đăng ký thành công');
        return AuthResult.success(user: user, message: successMsg);
      } else {
        String message = ApiErrorMapper.fromBody(
          response.body,
          statusCode: response.statusCode,
          fallback: 'Đăng ký thất bại',
        );
        try {
          final errs = data['errors'];
          if (errs is List && errs.isNotEmpty) {
            final joined = errs.map((e) => e.toString()).join('\n');
            if (joined.trim().isNotEmpty) {
              message = '$message\n$joined';
            }
          }
        } catch (_) {}
        return AuthResult.failure(message: message);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }

  // Quên mật khẩu
  static Future<AuthResult> forgotPassword(String email) async {
    try {
      final response = await HttpService().post(
        _forgotPasswordEndpoint,
        body: {'email': email},
        includeAuth: true,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Email đã được gửi');
      } else {
        final message = data['message'] ?? 'Gửi email thất bại';
        return AuthResult.failure(message: message);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }

  // Đặt lại mật khẩu
  static Future<AuthResult> resetPassword(String token, String newPassword) async {
    try {
      final response = await HttpService().post(
        _resetPasswordEndpoint,
        body: {
          'token': token,
          'newPassword': newPassword,
        },
        includeAuth: false,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Đặt lại mật khẩu thành công');
      } else {
        final message = data['message'] ?? 'Đặt lại mật khẩu thất bại';
        return AuthResult.failure(message: message);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }

  // Refresh token
  static Future<AuthResult> refreshToken() async {
    try {
      final storedRefreshToken = await StorageService.getRefreshToken();
      final currentUser = await StorageService.getUser();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return AuthResult.failure(message: 'Không có refresh token');
      }

      final response = await HttpService().post(
        _refreshTokenEndpoint,
        body: {
          'userId': currentUser?.id ?? '',
          'refreshToken': storedRefreshToken,
        },
        includeAuth: false,
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final envelope = data['data'] as Map<String, dynamic>;
        final userMap = (envelope['user'] ?? {}) as Map<String, dynamic>;
        final tokens = (envelope['tokens'] ?? {}) as Map<String, dynamic>;

        final accessToken = tokens['accessToken'] as String? ?? '';
        final refreshToken = tokens['refreshToken'] as String? ?? '';
        final expiresAtUtcStr = tokens['expiresAtUtc'] as String?;

        await StorageService.saveToken(accessToken);
        await StorageService.saveRefreshToken(refreshToken);

        DateTime? expiryTime;
        if (expiresAtUtcStr != null && expiresAtUtcStr.isNotEmpty) {
          try {
            expiryTime = DateTime.parse(expiresAtUtcStr).toLocal();
          } catch (_) {}
        }
        if (expiryTime == null) {
          final tokenPayload = JwtTokenManager.getTokenPayload(accessToken);
          final exp = tokenPayload != null ? tokenPayload['exp'] : null;
          if (exp != null) {
            expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          }
        }
        if (expiryTime != null) {
          await StorageService.saveTokenExpiry(expiryTime);
        }

        if (userMap.isNotEmpty) {
          final user = UserModel(
            id: (userMap['userId'] ?? userMap['id'] ?? '').toString(),
            fullName: (userMap['fullName'] ?? '').toString(),
            email: (userMap['email'] ?? '').toString(),
            phone: (currentUser?.phone ?? '').toString(),
            avatar: (currentUser?.avatar ?? '').toString(),
            createdAt: currentUser?.createdAt ?? DateTime.now(),
            isActive: true,
          );
          await StorageService.saveUser(user);
        }

        return AuthResult.success(message: data['message'] ?? 'Token đã được làm mới');
      } else {
        await logout();
        return AuthResult.failure(message: data['message'] ?? 'Phiên đăng nhập đã hết hạn');
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi làm mới token: $e');
    }
  }

  // Lấy thông tin profile
  static Future<AuthResult> getProfile() async {
    try {
      final response = await HttpService().get(_profileEndpoint, throwOnError: false);
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final Map<String, dynamic> payload = (data['data'] ?? {}) as Map<String, dynamic>;
        final user = UserModel(
          id: (payload['id'] ?? '').toString(),
          fullName: (payload['fullName'] ?? '').toString(),
          email: (payload['email'] ?? '').toString(),
          phone: (payload['phoneNumber'] ?? '').toString(),
          avatar: (payload['avatarUrl'] ?? '')?.toString(),
          createdAt: DateTime.tryParse((payload['registrationDate'] ?? '').toString()) ?? DateTime.now(),
          isActive: true,
        );
        await StorageService.saveUser(user);
        return AuthResult.success(user: user, message: data['message'] as String?);
      }
      final message = data['message']?.toString() ?? 'Không thể lấy thông tin profile';
      return AuthResult.failure(message: message);
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }

  // Cập nhật profile
  static Future<AuthResult> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

      final response = await HttpService().put(
        _profileEndpoint,
        body: body,
        throwOnError: false,
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        final Map<String, dynamic> payload = (data['data'] ?? {}) as Map<String, dynamic>;
        final user = UserModel(
          id: (payload['id'] ?? '').toString(),
          fullName: (payload['fullName'] ?? '').toString(),
          email: (payload['email'] ?? '').toString(),
          phone: (payload['phoneNumber'] ?? '').toString(),
          avatar: (payload['avatarUrl'] ?? '')?.toString(),
          createdAt: DateTime.tryParse((payload['registrationDate'] ?? '').toString()) ?? DateTime.now(),
          isActive: true,
        );
        await StorageService.saveUser(user);
        return AuthResult.success(user: user, message: data['message'] as String?);
      } else {
        final message = data['message']?.toString() ?? 'Cập nhật profile thất bại';
        return AuthResult.failure(message: message);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }

  // Đăng xuất
  static Future<AuthResult> logout() async {
    try {
      try {
        await HttpService().post(_logoutEndpoint);
      } catch (e) {}

      await StorageService.clearToken();
      await StorageService.clearRefreshToken();
      await StorageService.clearTokenExpiry();
      await StorageService.clearUser();
      await StorageService.removeValue('last_login_info');

      return AuthResult.success(message: 'Đăng xuất thành công');
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi đăng xuất: $e');
    }
  }

  // Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    final hasToken = await StorageService.hasToken();
    if (!hasToken) return false;
    
    final isExpired = await StorageService.isTokenExpired();
    if (isExpired) {
      final refreshResult = await refreshToken();
      return refreshResult.isSuccess;
    }
    
    return true;
  }

  // Lấy user hiện tại
  static Future<UserModel?> getCurrentUser() async {
    return await StorageService.getUser();
  }

  // Thay đổi mật khẩu
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await HttpService().post(
        '/v1/accounts/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': newPassword,
        },
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return AuthResult.success(message: data['message'] ?? 'Đổi mật khẩu thành công');
      } else {
        final message = data['message'] ?? 'Đổi mật khẩu thất bại';
        return AuthResult.failure(message: message);
      }
    } catch (e) {
      return AuthResult.failure(message: 'Lỗi kết nối: $e');
    }
  }
}

// Kết quả của các operation
class AuthResult {
  final bool isSuccess;
  final String? message;
  final UserModel? user;
  final String? errorCode;

  AuthResult._({
    required this.isSuccess,
    this.message,
    this.user,
    this.errorCode,
  });

  factory AuthResult.success({UserModel? user, String? message}) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.failure({String? message, String? errorCode}) {
    return AuthResult._(
      isSuccess: false,
      message: message,
      errorCode: errorCode,
    );
  }
}

// Extension để lưu thông tin đăng nhập cuối cùng
extension StorageServiceExtension on StorageService {
  static Future<bool> clearLastLoginInfo() async {
    return await StorageService.removeValue('last_login_info');
  }
}
