import 'package:flutter/material.dart';
import 'package:otto_mobile/screens/auth/login_screen.dart';
import 'package:otto_mobile/screens/auth/register_screen.dart';
import 'package:otto_mobile/screens/auth/forgot_password_screen.dart';
import 'package:otto_mobile/screens/home/home_screen.dart';
import 'package:otto_mobile/screens/profile/profile_screen.dart';
import 'package:otto_mobile/features/phaser/phaser_runner_screen.dart';
import 'package:otto_mobile/features/blockly/blockly_editor_screen.dart';
import 'package:otto_mobile/screens/auth/change_password_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String changePassword = '/change-password';
  static const String phaser = '/phaser';
  static const String blockly = '/blockly';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        forgotPassword: (context) => const ForgotPasswordScreen(),
        home: (context) => const HomeScreen(),
        profile: (context) => const ProfileScreen(),
        changePassword: (context) => const ChangePasswordScreen(),
        phaser: (context) => const PhaserRunnerScreen(),
        blockly: (context) => const BlocklyEditorScreen(),
      };
}
