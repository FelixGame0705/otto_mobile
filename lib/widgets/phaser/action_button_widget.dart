import 'package:flutter/material.dart';
import 'responsive_helpers.dart';

class ActionButtonWidget extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;
  final bool isTablet;
  final bool isLandscape;
  final VoidCallback onPressed;

  const ActionButtonWidget({
    super.key,
    required this.text,
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.isTablet,
    required this.isLandscape,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon, 
        color: textColor, 
        size: isTablet ? 16 : (isLandscape ? 14 : 15),
      ),
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: isTablet ? 11 : (isLandscape ? 11 : 12),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelpers.getButtonPadding(screenWidth, isTablet, 'horizontal'), 
          vertical: ResponsiveHelpers.getButtonPadding(screenWidth, isTablet, 'vertical'),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
    );
  }
}
