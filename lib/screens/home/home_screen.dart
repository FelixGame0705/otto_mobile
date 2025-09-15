import 'package:flutter/material.dart';
import 'package:otto_mobile/routes/app_routes.dart';
import 'package:otto_mobile/layout/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'OttoBit',
      actions: [
        IconButton(
          icon: const Icon(Icons.extension),
          tooltip: 'Blockly',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.blockly),
        ),
        IconButton(
          icon: const Icon(Icons.videogame_asset),
          tooltip: 'Phaser',
          onPressed: () => Navigator.pushNamed(context, AppRoutes.phaser),
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.profile),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
        ),
      ],
      gradientColors: const [Color(0xFFEDFCF2), Color(0xFFEDFCF2)],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.home, size: 100, color: Color(0xFF2D3748)),
          SizedBox(height: 24),
          Text(
            'Chào mừng đến với OttoBit MB!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Bạn đã đăng nhập thành công',
            style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
