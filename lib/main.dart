import 'package:flutter/material.dart';
import 'package:ottobit/screens/auth/login_screen.dart';
import 'package:ottobit/screens/auth/register_screen.dart';
import 'package:ottobit/screens/auth/forgot_password_screen.dart';
import 'package:ottobit/screens/home/home_screen.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/services/storage_service.dart';

void main() async {
  // Đảm bảo Flutter bindings được khởi tạo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo services
  await StorageService.init();
  HttpService().init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OttoBit MB',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
