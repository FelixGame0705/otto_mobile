class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    this.statusCode,
  });

  factory ApiResponse.success({
    T? data,
    String? message,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure({
    String? message,
    String? errorCode,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errorCode: errorCode,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJsonT,
  ) {
    final success = json['success'] ?? false;
    final message = json['message'];
    final errorCode = json['error_code'];
    final statusCode = json['status_code'];

    T? data;
    if (json['data'] != null && fromJsonT != null) {
      try {
        data = fromJsonT(json['data']);
      } catch (e) {
        // Handle parsing error
      }
    }

    return ApiResponse<T>(
      success: success,
      message: message,
      data: data,
      errorCode: errorCode,
      statusCode: statusCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error_code': errorCode,
      'status_code': statusCode,
    };
  }

  // Helper methods
  bool get isSuccess => success;
  bool get isFailure => !success;
  
  // Get data with null safety
  T? get safeData => data;
  
  // Get message with default
  String get displayMessage => message ?? 'Không có thông báo';
}

// Specific response models
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserResponse user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
      user: UserResponse.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}

class UserResponse {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatar;
  final DateTime createdAt;
  final bool isActive;

  UserResponse({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatar,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class RegisterResponse {
  final UserResponse user;
  final String? message;

  RegisterResponse({
    required this.user,
    this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      user: UserResponse.fromJson(json['user'] ?? {}),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'message': message,
    };
  }
}

class ForgotPasswordResponse {
  final String message;
  final bool emailSent;

  ForgotPasswordResponse({
    required this.message,
    required this.emailSent,
  });

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message'] ?? '',
      emailSent: json['email_sent'] ?? json['emailSent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'email_sent': emailSent,
    };
  }
}

class ResetPasswordResponse {
  final String message;
  final bool success;

  ResetPasswordResponse({
    required this.message,
    required this.success,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
    };
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  RefreshTokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
    };
  }
}

class ProfileUpdateResponse {
  final UserResponse user;
  final String message;

  ProfileUpdateResponse({
    required this.user,
    required this.message,
  });

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      user: UserResponse.fromJson(json['user'] ?? {}),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'message': message,
    };
  }
}

class ChangePasswordResponse {
  final String message;
  final bool success;

  ChangePasswordResponse({
    required this.message,
    required this.success,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      message: json['message'] ?? '',
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'success': success,
    };
  }
}
