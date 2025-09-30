import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/challenge_model.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;
  final int? bestStar; // Add best star rating from challenge process

  const ChallengeCard({
    super.key, 
    required this.challenge, 
    required this.onTap,
    this.bestStar,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 900;
    final isMobile = screenWidth < 600;
    
    // Responsive sizing
    final cardPadding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final titleFontSize = isDesktop ? 18.0 : isTablet ? 16.0 : 14.0;
    final descriptionFontSize = isDesktop ? 13.0 : isTablet ? 12.0 : 11.0;
    final chipFontSize = isDesktop ? 13.0 : isTablet ? 12.0 : 11.0;
    final buttonHeight = isDesktop ? 48.0 : isTablet ? 44.0 : 40.0;
    final iconSize = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final chipPadding = isDesktop 
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : isTablet 
        ? const EdgeInsets.symmetric(horizontal: 9, vertical: 5)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    
    return Card(
      elevation: isDesktop ? 4 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                challenge.title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3748),
                  height: 1.2,
                ),
                maxLines: isMobile ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isDesktop ? 8 : 6),
              // Description
              Expanded(
                flex: isMobile ? 2 : 1,
                child: Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: descriptionFontSize, 
                    color: const Color(0xFF718096), 
                    height: 1.3,
                  ),
                  maxLines: isMobile ? 2 : (isTablet ? 3 : 4),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isDesktop ? 12 : 8),
              // Stats - Responsive layout
              _buildStatsSection(isDesktop, isTablet, isMobile, chipFontSize, iconSize, chipPadding),
              SizedBox(height: isDesktop ? 12 : 8),
              // Action Button
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
                    ),
                    side: BorderSide(
                      color: const Color(0xFF4299E1),
                      width: isDesktop ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    'challenge.viewDetails'.tr(),
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDesktop, bool isTablet, bool isMobile, double chipFontSize, double iconSize, EdgeInsets chipPadding) {
    // Responsive layout for stats
    if (isDesktop) {
      // Desktop: Show stats in a row with wrapping
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _chip(Icons.bar_chart, '${'challenge.difficulty'.tr()}: ${challenge.difficulty}', const Color(0xFFED8936), chipFontSize, iconSize, chipPadding),
          _chip(Icons.upload_file, '${'challenge.submissions'.tr()}: ${challenge.submissionsCount}', const Color(0xFF4299E1), chipFontSize, iconSize, chipPadding),
          if (bestStar != null)
            _chip(Icons.star, '${'challenge.bestStar'.tr()}: $bestStar', const Color.fromARGB(255, 255, 225, 0), chipFontSize, iconSize, chipPadding),
        ],
      );
    } else if (isTablet) {
      // Tablet: Show stats in a column with 2 per row
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _chip(Icons.bar_chart, '${'challenge.difficulty'.tr()}: ${challenge.difficulty}', const Color(0xFFED8936), chipFontSize, iconSize, chipPadding),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(Icons.upload_file, '${'challenge.submissions'.tr()}: ${challenge.submissionsCount}', const Color(0xFF4299E1), chipFontSize, iconSize, chipPadding),
              ),
            ],
          ),
          if (bestStar != null) ...[
            const SizedBox(height: 8),
            _chip(Icons.star, '${'challenge.bestStar'.tr()}: $bestStar', const Color(0xFFFFD700), chipFontSize, iconSize, chipPadding),
          ],
        ],
      );
    } else {
      // Mobile: Show stats in a single column
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chip(Icons.bar_chart, '${'challenge.difficulty'.tr()}: ${challenge.difficulty}', const Color(0xFFED8936), chipFontSize, iconSize, chipPadding),
          const SizedBox(height: 6),
          _chip(Icons.upload_file, '${'challenge.submissions'.tr()}: ${challenge.submissionsCount}', const Color(0xFF4299E1), chipFontSize, iconSize, chipPadding),
          if (bestStar != null) ...[
            const SizedBox(height: 6),
            _chip(Icons.star, '${'challenge.bestStar'.tr()}: $bestStar', const Color(0xFFFFD700), chipFontSize, iconSize, chipPadding),
          ],
        ],
      );
    }
  }

  Widget _chip(IconData icon, String text, Color color, double fontSize, double iconSize, EdgeInsets padding) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: iconSize * 0.3),
          Flexible(
            child: Text(
              text, 
              style: TextStyle(
                fontSize: fontSize, 
                color: color, 
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}


