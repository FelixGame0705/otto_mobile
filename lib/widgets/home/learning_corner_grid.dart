import 'package:flutter/material.dart';

class LearningCornerGrid extends StatelessWidget {
  const LearningCornerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: const [
        _PromoCard(
          color: Color(0xFFFFEDD5),
          iconBg: Color(0xFFF59E0B),
          icon: Icons.brush,
          title: 'Vẽ tranh sáng tạo',
          subtitle: 'Học cách vẽ động vật',
        ),
        _PromoCard(
          color: Color(0xFFEDE9FE),
          iconBg: Color(0xFF6D28D9),
          icon: Icons.psychology,
          title: 'Giải đố thông minh',
          subtitle: 'Phát triển tư duy logic',
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Color color;
  final Color iconBg;
  final IconData icon;
  final String title;
  final String subtitle;
  const _PromoCard({required this.color, required this.iconBg, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: iconBg, foregroundColor: Colors.white, child: Icon(icon)),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}


