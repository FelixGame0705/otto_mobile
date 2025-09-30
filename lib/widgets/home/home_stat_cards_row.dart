import 'package:flutter/material.dart';

class HomeStatCardsRow extends StatelessWidget {
  final int joined;
  final String quickCourseTitle;
  const HomeStatCardsRow({super.key, required this.joined, required this.quickCourseTitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(title: '$joined', subtitle: 'bé tham gia', icon: Icons.emoji_events, color: const Color(0xFFF59E0B))),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(title: 'Học vui', subtitle: 'Hiểu nhanh', icon: Icons.bolt, color: const Color(0xFF60A5FA))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.15), foregroundColor: color, child: Icon(icon)),
          const Spacer(),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}


