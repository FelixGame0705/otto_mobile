import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LessonActionButtons extends StatelessWidget {
  final VoidCallback onStartLesson;
  final VoidCallback onViewChallenges;
  final VoidCallback onViewTheory;
  final bool isStarting;
  final int challengesCount;

  const LessonActionButtons({
    super.key,
    required this.onStartLesson,
    required this.onViewChallenges,
    required this.onViewTheory,
    this.isStarting = false,
    required this.challengesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Start Lesson Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isStarting ? null : onStartLesson,
              icon: isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.play_arrow, size: 24),
              label: Text(
                isStarting ? 'common.loading'.tr() : 'common.startLearning'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: const Color(0xFF4299E1).withOpacity(0.4),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Theory Resources Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewTheory,
              icon: const Icon(Icons.menu_book_outlined, size: 20),
              label: Text(
                'common.theory'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4299E1),
                side: const BorderSide(
                  color: Color(0xFF4299E1),
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Challenges Button
          if (challengesCount > 0)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewChallenges,
                icon: const Icon(Icons.flag, size: 20),
                label: Text(
                  'common.viewChallenges'.tr(namedArgs: {'count': '$challengesCount'}),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF48BB78),
                  side: const BorderSide(
                    color: Color(0xFF48BB78),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          // Secondary Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('common.markComplete'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(
                    'common.markComplete'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF48BB78),
                    side: const BorderSide(color: Color(0xFF48BB78)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('common.addToFavorites'.tr()),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: Text(
                    'common.addToFavorites'.tr(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFED8936),
                    side: const BorderSide(color: Color(0xFFED8936)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
