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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.home, size: 100, color: Color(0xFF2D3748)),
          const SizedBox(height: 24),
          const Text(
            'Chào mừng đến với OttoBit MB!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn đã đăng nhập thành công',
            style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Course Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.courses),
              icon: const Icon(Icons.school, size: 24),
              label: const Text(
                'Khóa học',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Additional action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context,
                icon: Icons.extension,
                label: 'Blockly',
                route: AppRoutes.blockly,
                color: const Color(0xFF48BB78),
              ),
              _buildActionButton(
                context,
                icon: Icons.videogame_asset,
                label: 'Phaser',
                route: AppRoutes.phaser,
                color: const Color(0xFFED8936),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required Color color,
  }) {
    return Container(
      width: 120,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
