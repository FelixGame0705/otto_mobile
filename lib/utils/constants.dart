class AppConstants {
  // App Info
  static const String appName = 'OttoBit MB';
  static const String appVersion = '1.0.0';
  
  // Colors
  static const int primaryColor = 0xFF667eea;
  static const int secondaryColor = 0xFF764ba2;
  static const int backgroundColor = 0xFFF7FAFC;
  static const int textPrimaryColor = 0xFF2D3748;
  static const int textSecondaryColor = 0xFF718096;
  static const int borderColor = 0xFFE2E8F0;
  static const int successColor = 0xFF38A169;
  static const int errorColor = 0xFFE53E3E;
  static const int warningColor = 0xFFD69E2E;
  
  // Text Styles
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 18.0;
  static const double fontSizeXLarge = 24.0;
  static const double fontSizeXXLarge = 28.0;
  
  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  static const int phoneLength = 10;
  
  // API
  static const String baseUrl = 'https://ottobit-be.felixtien.dev/api'; // Thay đổi thành URL thực tế của backend
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
}
