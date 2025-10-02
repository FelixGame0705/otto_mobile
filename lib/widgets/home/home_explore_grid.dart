import 'package:flutter/material.dart';
import 'package:ottobit/widgets/enrolls/my_enrollments_grid.dart';

class HomeExploreGrid extends StatelessWidget {
  const HomeExploreGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_ExploreItem>[
      _ExploreItem(
        icon: Icons.library_books,
        label: 'My Enrollments',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('My Enrollments')),
                body: const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: MyEnrollmentsGrid(),
                ),
              ),
            ),
          );
        },
        color: const Color(0xFF3B82F6),
      ),
      _ExploreItem(
        icon: Icons.smart_toy_outlined,
        label: 'My Robots',
        onTap: () => Navigator.of(context).pushNamed('/microbit-connection'),
        color: const Color(0xFF10B981),
      ),
      _ExploreItem(
        icon: Icons.history_edu,
        label: 'Recent submissions',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recent submissions coming soon')),
          );
        },
        color: const Color(0xFFF59E0B),
      ),
      _ExploreItem(
        icon: Icons.developer_board,
        label: 'Studio',
        onTap: () => Navigator.of(context).pushNamed('/blockly'),
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ExploreCard(item: items[index]),
    );
  }
}

class _ExploreItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  _ExploreItem({required this.icon, required this.label, required this.onTap, required this.color});
}

class _ExploreCard extends StatelessWidget {
  final _ExploreItem item;
  const _ExploreCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(color: item.color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(height: 8),
            Text(item.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}


