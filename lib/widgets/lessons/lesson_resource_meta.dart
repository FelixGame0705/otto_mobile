import 'package:flutter/material.dart';
import 'package:ottobit/models/lesson_resource_model.dart';

class LessonResourceMeta extends StatelessWidget {
  final LessonResourceItem item;

  const LessonResourceMeta({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final Color accent = item.type == 1 ? const Color(0xFF3182CE) : const Color(0xFF48BB78);
    final IconData icon = item.type == 1 ? Icons.ondemand_video : Icons.article_outlined;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.description!,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 16, color: Color(0xFF718096)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.courseTitle} • ${item.lessonTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


