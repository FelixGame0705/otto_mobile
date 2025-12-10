import 'package:flutter/material.dart';

class CompletedLessonsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const CompletedLessonsChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.map((e) => (e['value'] as num).toDouble()).fold<double>(0, (p, c) => c > p ? c : p);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((e) {
          final label = e['label'] as String;
          final v = (e['value'] as num).toDouble();
          final h = maxVal == 0 ? 0.0 : (v / maxVal) * 110.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: h,
                  width: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


