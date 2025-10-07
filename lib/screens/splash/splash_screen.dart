import 'package:flutter/material.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    // Small delay for logo feel
    await Future.delayed(const Duration(milliseconds: 300));

    final seen = await StorageService.getValue<bool>(AppConstants.onboardingSeenKey) ?? false;
    final hasToken = await StorageService.hasToken();

    if (!mounted) return;

    if (!seen) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    } else if (hasToken) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEDFCF2),
      body: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00ba4a))),
        ),
      ),
    );
  }
}


