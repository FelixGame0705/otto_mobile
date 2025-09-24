import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ottobit/models/user_model.dart';
import 'package:ottobit/utils/constants.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  // Khởi tạo SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Lưu JWT token
  static Future<bool> saveToken(String token) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(AppConstants.tokenKey, token);
  }

  // Lấy JWT token
  static Future<String?> getToken() async {
    if (_prefs == null) await init();
    return _prefs!.getString(AppConstants.tokenKey);
  }

  // Xóa JWT token
  static Future<bool> clearToken() async {
    if (_prefs == null) await init();
    return await _prefs!.remove(AppConstants.tokenKey);
  }

  // Kiểm tra có token hay không
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Lưu thông tin user
  static Future<bool> saveUser(UserModel user) async {
    if (_prefs == null) await init();
    final userJson = jsonEncode(user.toJson());
    return await _prefs!.setString(AppConstants.userKey, userJson);
  }

  // Lấy thông tin user
  static Future<UserModel?> getUser() async {
    if (_prefs == null) await init();
    final userJson = _prefs!.getString(AppConstants.userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Xóa thông tin user
  static Future<bool> clearUser() async {
    if (_prefs == null) await init();
    return await _prefs!.remove(AppConstants.userKey);
  }

  // Lưu theme
  static Future<bool> saveTheme(String theme) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(AppConstants.themeKey, theme);
  }

  // Lấy theme
  static Future<String?> getTheme() async {
    if (_prefs == null) await init();
    return _prefs!.getString(AppConstants.themeKey);
  }

  // Lưu ngôn ngữ
  static Future<bool> saveLanguage(String language) async {
    if (_prefs == null) await init();
    return await _prefs!.setString(AppConstants.languageKey, language);
  }

  // Lấy ngôn ngữ
  static Future<String?> getLanguage() async {
    if (_prefs == null) await init();
    return _prefs!.getString(AppConstants.languageKey);
  }

  // Lưu giá trị tùy ý
  static Future<bool> saveValue(String key, dynamic value) async {
    if (_prefs == null) await init();
    
    if (value is String) {
      return await _prefs!.setString(key, value);
    } else if (value is int) {
      return await _prefs!.setInt(key, value);
    } else if (value is double) {
      return await _prefs!.setDouble(key, value);
    } else if (value is bool) {
      return await _prefs!.setBool(key, value);
    } else if (value is List<String>) {
      return await _prefs!.setStringList(key, value);
    } else {
      // Convert to JSON string for complex objects
      final jsonString = jsonEncode(value);
      return await _prefs!.setString(key, jsonString);
    }
  }

  // Lấy giá trị tùy ý
  static Future<T?> getValue<T>(String key) async {
    if (_prefs == null) await init();
    
    if (T == String) {
      return _prefs!.getString(key) as T?;
    } else if (T == int) {
      return _prefs!.getInt(key) as T?;
    } else if (T == double) {
      return _prefs!.getDouble(key) as T?;
    } else if (T == bool) {
      return _prefs!.getBool(key) as T?;
    } else if (T == List<String>) {
      return _prefs!.getStringList(key) as T?;
    } else {
      // Try to parse JSON for complex objects
      final jsonString = _prefs!.getString(key);
      if (jsonString != null) {
        try {
          final jsonData = jsonDecode(jsonString);
          return jsonData as T?;
        } catch (e) {
          return null;
        }
      }
      return null;
    }
  }

  // Xóa giá trị
  static Future<bool> removeValue(String key) async {
    if (_prefs == null) await init();
    return await _prefs!.remove(key);
  }

  // Xóa tất cả dữ liệu
  static Future<bool> clearAll() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }

  // Kiểm tra key có tồn tại
  static Future<bool> containsKey(String key) async {
    if (_prefs == null) await init();
    return _prefs!.containsKey(key);
  }

  // Lấy tất cả keys
  static Future<Set<String>> getAllKeys() async {
    if (_prefs == null) await init();
    return _prefs!.getKeys();
  }

  // Lưu refresh token
  static Future<bool> saveRefreshToken(String refreshToken) async {
    if (_prefs == null) await init();
    return await _prefs!.setString('refresh_token', refreshToken);
  }

  // Lấy refresh token
  static Future<String?> getRefreshToken() async {
    if (_prefs == null) await init();
    return _prefs!.getString('refresh_token');
  }

  // Xóa refresh token
  static Future<bool> clearRefreshToken() async {
    if (_prefs == null) await init();
    return await _prefs!.remove('refresh_token');
  }

  // Xóa thời gian token hết hạn
  static Future<bool> clearTokenExpiry() async {
    if (_prefs == null) await init();
    return await _prefs!.remove('token_expiry');
  }

  // Lưu thời gian token hết hạn
  static Future<bool> saveTokenExpiry(DateTime expiry) async {
    if (_prefs == null) await init();
    final expiryString = expiry.toIso8601String();
    return await _prefs!.setString('token_expiry', expiryString);
  }

  // Lấy thời gian token hết hạn
  static Future<DateTime?> getTokenExpiry() async {
    if (_prefs == null) await init();
    final expiryString = _prefs!.getString('token_expiry');
    if (expiryString != null) {
      try {
        return DateTime.parse(expiryString);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Kiểm tra token có hết hạn chưa
  static Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    
    // Kiểm tra token hết hạn trong 5 phút tới
    final now = DateTime.now();
    final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
    
    return expiry.isBefore(fiveMinutesFromNow);
  }

  // Lưu thông tin đăng nhập cuối cùng
  static Future<bool> saveLastLoginInfo({
    required String email,
    required DateTime loginTime,
  }) async {
    if (_prefs == null) await init();
    
    final loginInfo = {
      'email': email,
      'loginTime': loginTime.toIso8601String(),
    };
    
    return await saveValue('last_login_info', loginInfo);
  }

  // Lấy thông tin đăng nhập cuối cùng
  static Future<Map<String, dynamic>?> getLastLoginInfo() async {
    return await getValue<Map<String, dynamic>>('last_login_info');
  }
}
