import 'dart:convert';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/services/auth_service.dart';

class JwtTokenManager {
  static final JwtTokenManager _instance = JwtTokenManager._internal();
  factory JwtTokenManager() => _instance;
  JwtTokenManager._internal();

  // JWT token structure: header.payload.signature
  static const int _tokenParts = 3;
  
  // Kiểm tra token có hợp lệ không
  static bool isValidToken(String token) {
    if (token.isEmpty) return false;
    
    final parts = token.split('.');
    if (parts.length != _tokenParts) return false;
    
    try {
      // Decode payload
      final payload = parts[1];
      final decodedPayload = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final payloadMap = jsonDecode(decodedPayload) as Map<String, dynamic>;
      
      // Kiểm tra thời gian hết hạn
      final exp = payloadMap['exp'];
      if (exp == null) return false;
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      
      return expiryTime.isAfter(now);
    } catch (e) {
      return false;
    }
  }

  // Lấy thông tin từ token
  static Map<String, dynamic>? getTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != _tokenParts) return null;
      
      final payload = parts[1];
      final decodedPayload = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      return jsonDecode(decodedPayload) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Lấy thời gian hết hạn từ token
  static DateTime? getTokenExpiry(String token) {
    final payload = getTokenPayload(token);
    if (payload == null) return null;
    
    final exp = payload['exp'];
    if (exp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
  }

  // Lấy user ID từ token
  static String? getUserId(String token) {
    final payload = getTokenPayload(token);
    return payload?['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ?? 
           payload?['sub'] ?? 
           payload?['user_id'];
  }

  // Lấy email từ token
  static String? getUserEmail(String token) {
    final payload = getTokenPayload(token);
    return payload?['email'];
  }

  // Lấy roles từ token
  static List<String> getUserRoles(String token) {
    final payload = getTokenPayload(token);
    final roles = payload?['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ?? 
                 payload?['roles'];
    
    if (roles is List) {
      return roles.cast<String>();
    } else if (roles is String) {
      return [roles];
    }
    
    return [];
  }

  // Kiểm tra token có sắp hết hạn không (trong vòng 5 phút)
  static bool isTokenExpiringSoon(String token) {
    final expiry = getTokenExpiry(token);
    if (expiry == null) return true;
    
    final now = DateTime.now();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    
    return expiry.isBefore(fiveMinutesFromNow);
  }

  // Kiểm tra token có cần refresh không
  static Future<bool> shouldRefreshToken() async {
    final token = await StorageService.getToken();
    if (token == null) return false;
    
    return isTokenExpiringSoon(token);
  }

  // Refresh token nếu cần
  static Future<bool> refreshTokenIfNeeded() async {
    if (await shouldRefreshToken()) {
      try {
        final result = await AuthService.refreshToken();
        return result.isSuccess;
      } catch (e) {
        return false;
      }
    }
    return true;
  }

  // Lấy token hiện tại (đã refresh nếu cần)
  static Future<String?> getValidToken() async {
    // Kiểm tra và refresh token nếu cần
    if (!await refreshTokenIfNeeded()) {
      return null;
    }
    
    return await StorageService.getToken();
  }

  // Kiểm tra token có quyền truy cập endpoint không
  static Future<bool> hasPermission(String requiredRole) async {
    final token = await getValidToken();
    if (token == null) return false;
    
    final roles = getUserRoles(token);
    return roles.contains(requiredRole);
  }

  // Kiểm tra token có quyền admin không
  static Future<bool> isAdmin() async {
    return await hasPermission('admin');
  }

  // Kiểm tra token có quyền user không
  static Future<bool> isUser() async {
    return await hasPermission('user');
  }

  // Lấy thông tin user từ token
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final token = await getValidToken();
    if (token == null) return null;
    
    final payload = getTokenPayload(token);
    if (payload == null) return null;
    
    return {
      'id': getUserId(token),
      'name': payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'],
      'email': getUserEmail(token),
      'roles': getUserRoles(token),
      'exp': payload['exp'],
      'iat': payload['iat'],
    };
  }

  // Log token info (chỉ dùng cho debug)
  static void logTokenInfo(String token) {
    try {
      final payload = getTokenPayload(token);
      if (payload != null) {
        print('Token Info:');
        print('  User ID: ${getUserId(token)}');
        print('  Name: ${payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name']}');
        print('  Email: ${getUserEmail(token)}');
        print('  Roles: ${getUserRoles(token)}');
        print('  Issued At: ${DateTime.fromMillisecondsSinceEpoch((payload['iat'] ?? 0) * 1000)}');
        print('  Expires At: ${getTokenExpiry(token)}');
        print('  Is Valid: ${isValidToken(token)}');
        print('  Is Expiring Soon: ${isTokenExpiringSoon(token)}');
      }
    } catch (e) {
      print('Error logging token info: $e');
    }
  }

  // Validate token format
  static bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;
    
    final parts = token.split('.');
    if (parts.length != _tokenParts) return false;
    
    // Kiểm tra mỗi part có phải base64 không
    for (final part in parts) {
      try {
        base64Url.decode(base64Url.normalize(part));
      } catch (e) {
        return false;
      }
    }
    
    return true;
  }

  // Extract token từ Authorization header
  static String? extractTokenFromHeader(String? authHeader) {
    if (authHeader == null || authHeader.isEmpty) return null;
    
    if (authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7); // Remove 'Bearer ' prefix
    }
    
    return null;
  }

  // Tạo Authorization header
  static Future<String?> createAuthHeader() async {
    final token = await getValidToken();
    if (token == null) return null;
    
    return 'Bearer $token';
  }
}

// Extension để dễ sử dụng
extension JwtTokenManagerExtension on JwtTokenManager {
  // Kiểm tra token có hợp lệ và chưa hết hạn
  static Future<bool> isTokenValidAndNotExpired() async {
    final token = await StorageService.getToken();
    if (token == null) return false;
    
    return JwtTokenManager.isValidToken(token);
  }
  
  // Lấy thời gian còn lại của token (tính bằng giây)
  static Future<int?> getTokenTimeRemaining() async {
    final token = await StorageService.getToken();
    if (token == null) return null;
    
    final expiry = JwtTokenManager.getTokenExpiry(token);
    if (expiry == null) return null;
    
    final now = DateTime.now();
    final remaining = expiry.difference(now).inSeconds;
    
    return remaining > 0 ? remaining : 0;
  }
}
