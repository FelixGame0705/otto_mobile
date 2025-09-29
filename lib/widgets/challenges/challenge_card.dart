import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/challenge_model.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const ChallengeCard({super.key, required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // Description
              Text(
                challenge.description,
                style: const TextStyle(fontSize: 12, color: Color(0xFF718096), height: 1.3),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              const SizedBox(height: 8),
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _chip(Icons.bar_chart, '${'challenge.difficulty'.tr()}: ${challenge.difficulty}', const Color(0xFFED8936)),
                  const SizedBox(height: 8),
                  _chip(Icons.upload_file, '${'challenge.submissions'.tr()}: ${challenge.submissionsCount}', const Color(0xFF4299E1)),
                ],
              ),
              const SizedBox(height: 8),
              // Action
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  child: Text('challenge.viewDetails'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


