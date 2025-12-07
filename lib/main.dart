import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/http_service.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/services/navigation_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await StorageService.init();
  HttpService().init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('vi'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize locale in ApiErrorMapper
    ApiErrorMapper.updateLocale(context.locale);
    
    // Tạo navigator key và set vào NavigationService và ApiErrorMapper
    final navigatorKey = GlobalKey<NavigatorState>();
    NavigationService().setNavigatorKey(navigatorKey);
    ApiErrorMapper.setNavigatorKey(navigatorKey);
    
    return MaterialApp(
      title: 'OttoBit MB',
      navigatorKey: navigatorKey,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
