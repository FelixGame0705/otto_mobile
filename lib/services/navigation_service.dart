import 'package:flutter/material.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/auth_service.dart';

/// Service để quản lý navigation toàn cục
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  /// Set navigator key từ main app
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  /// Get navigator key
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  /// Navigate đến login screen và clear auth data
  Future<void> navigateToLogin({bool clearAuth = true}) async {
    if (clearAuth) {
      await AuthService.logout();
    }
    
    if (_navigatorKey?.currentContext != null) {
      Navigator.of(_navigatorKey!.currentContext!).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false, // Xóa tất cả routes trước đó
      );
    }
  }

  /// Navigate đến một route
  Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    if (_navigatorKey?.currentContext != null) {
      return Navigator.of(_navigatorKey!.currentContext!).pushNamed(
        routeName,
        arguments: arguments,
      );
    }
    return Future.value();
  }

  /// Navigate và replace route hiện tại
  Future<dynamic> navigateReplacement(String routeName, {Object? arguments}) {
    if (_navigatorKey?.currentContext != null) {
      return Navigator.of(_navigatorKey!.currentContext!).pushReplacementNamed(
        routeName,
        arguments: arguments,
      );
    }
    return Future.value();
  }

  /// Go back
  void goBack([dynamic result]) {
    if (_navigatorKey?.currentContext != null) {
      Navigator.of(_navigatorKey!.currentContext!).pop(result);
    }
  }
}

