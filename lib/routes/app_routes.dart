import 'package:flutter/material.dart';
import 'package:otto_mobile/screens/auth/login_screen.dart';
import 'package:otto_mobile/screens/auth/register_screen.dart';
import 'package:otto_mobile/screens/auth/forgot_password_screen.dart';
import 'package:otto_mobile/screens/home/home_screen.dart';
import 'package:otto_mobile/screens/profile/profile_screen.dart';
import 'package:otto_mobile/screens/courses/courses_screen.dart';
import 'package:otto_mobile/screens/courses/course_detail_screen.dart';
import 'package:otto_mobile/screens/lessons/lessons_screen.dart';
import 'package:otto_mobile/screens/lessons/lesson_detail_screen.dart';
import 'package:otto_mobile/features/phaser/phaser_runner_screen.dart';
import 'package:otto_mobile/features/blockly/blockly_editor_screen.dart';
import 'package:otto_mobile/screens/auth/change_password_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String courses = '/courses';
  static const String courseDetail = '/course-detail';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lesson-detail';
  static const String changePassword = '/change-password';
  static const String phaser = '/phaser';
  static const String blockly = '/blockly';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    profile: (context) => const ProfileScreen(),
    courses: (context) => const CoursesScreen(),
    courseDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return CourseDetailScreen(courseId: args);
      }
      return const CoursesScreen(); // Fallback
    },
    lessons: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final courseId = args['courseId'] as String?;
        final courseTitle = args['courseTitle'] as String?;
        if (courseId != null) {
          return LessonsScreen(courseId: courseId, courseTitle: courseTitle);
        }
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin khóa học'),
        ),
      );
    },
    lessonDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return LessonDetailScreen(lessonId: args);
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin bài học'),
        ),
      );
    },
    changePassword: (context) => const ChangePasswordScreen(),
    phaser: (context) => const PhaserRunnerScreen(),
    blockly: (context) => const BlocklyEditorScreen(),
  };
}
