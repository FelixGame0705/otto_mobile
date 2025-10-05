import 'package:flutter/material.dart';
import 'package:ottobit/screens/auth/login_screen.dart';
import 'package:ottobit/screens/auth/register_screen.dart';
import 'package:ottobit/screens/auth/forgot_password_screen.dart';
import 'package:ottobit/screens/home/home_screen.dart';
import 'package:ottobit/screens/profile/profile_screen.dart';
import 'package:ottobit/screens/courses/course_detail_screen.dart';
import 'package:ottobit/screens/lessons/lessons_screen.dart';
import 'package:ottobit/screens/lessons/lesson_detail_screen.dart';
import 'package:ottobit/screens/lessons/lesson_resources_screen.dart';
import 'package:ottobit/screens/lessons/lesson_resource_detail_screen.dart';
import 'package:ottobit/features/phaser/phaser_runner_screen.dart';
import 'package:ottobit/screens/challenges/challenges_screen.dart';
import 'package:ottobit/features/blockly/blockly_editor_screen.dart';
import 'package:ottobit/screens/detect/detect_capture_screen.dart';
import 'package:ottobit/screens/auth/change_password_screen.dart';
import 'package:ottobit/screens/products/product_detail_screen.dart';
import 'package:ottobit/screens/universal_hex/universal_hex_screen.dart';
import 'package:ottobit/screens/cart/cart_screen.dart';
import 'package:ottobit/screens/order/checkout_screen.dart';
import 'package:ottobit/screens/order/orders_screen.dart';
import 'package:ottobit/screens/order/order_detail_screen.dart';
import 'package:ottobit/models/cart_model.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  // static const String courses = '/courses'; // removed dedicated screen; explore tab handles courses
  static const String courseDetail = '/course-detail';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lesson-detail';
  static const String challenges = '/challenges';
  static const String lessonResources = '/lesson-resources';
  static const String lessonResourceDetail = '/lesson-resource-detail';
  static const String productDetail = '/product-detail';
  static const String changePassword = '/change-password';
  static const String phaser = '/phaser';
  static const String blockly = '/blockly';
  static const String detectCapture = '/detect-capture';
  static const String universalHex = '/universal-hex';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const HomeScreen(),
    profile: (context) => const ProfileScreen(),
    courseDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return CourseDetailScreen(courseId: args);
      }
      if (args is Map<String, dynamic>) {
        final courseId = args['courseId'] as String?;
        final hideEnroll = (args['hideEnroll'] as bool?) ?? false;
        if (courseId != null) {
          return CourseDetailScreen(courseId: courseId, hideEnroll: hideEnroll);
        }
      }
      return const HomeScreen(); // Fallback
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
    challenges: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final lessonId = args['lessonId'] as String?;
        final courseId = args['courseId'] as String?;
        final lessonTitle = args['lessonTitle'] as String?;
        final showBestStars = args['showBestStars'] as bool? ?? false;
        if (lessonId != null) {
          return ChallengesScreen(
            lessonId: lessonId,
            courseId: courseId,
            lessonTitle: lessonTitle,
            showBestStars: showBestStars,
          );
        }
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin thử thách'),
        ),
      );
    },
    lessonResources: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final lessonId = args['lessonId'] as String?;
        final lessonTitle = args['lessonTitle'] as String?;
        if (lessonId != null) {
          return LessonResourcesScreen(lessonId: lessonId, lessonTitle: lessonTitle);
        }
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin tài nguyên bài học'),
        ),
      );
    },
    lessonResourceDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        return LessonResourceDetailScreen(resourceId: args);
      }
      if (args is Map<String, dynamic>) {
        final id = args['resourceId'] as String?;
        if (id != null) {
          return LessonResourceDetailScreen(resourceId: id);
        }
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin tài nguyên'),
        ),
      );
    },
    changePassword: (context) => const ChangePasswordScreen(),
    phaser: (context) => const PhaserRunnerScreen(),
    blockly: (context) => const BlocklyEditorScreen(),
    detectCapture: (context) => const DetectCaptureScreen(),
    universalHex: (context) => const UniversalHexScreen(),
    productDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final productId = args['productId'] as String?;
        final productType = args['productType'] as String? ?? 'robot';
        if (productId != null) {
          return ProductDetailScreen(
            productId: productId,
            productType: productType,
          );
        }
      } else if (args is String) {
        // Backward compatibility for old String argument
        return ProductDetailScreen(productId: args);
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin sản phẩm'),
        ),
      );
    },
    cart: (context) => const CartScreen(),
    checkout: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final cartItems = args['cartItems'] as List<CartItem>?;
        final cartSummary = args['cartSummary'] as CartSummary?;
        if (cartItems != null) {
          return CheckoutScreen(
            cartItems: cartItems,
            cartSummary: cartSummary,
          );
        }
      }
      return const Scaffold(
        body: Center(
          child: Text('Thiếu thông tin giỏ hàng'),
        ),
      );
    },
    orders: (context) => const OrdersScreen(),
    orderDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) return OrderDetailScreen(orderId: args);
      return const Scaffold(body: Center(child: Text('Thiếu mã đơn hàng')));
    },
  };
}
