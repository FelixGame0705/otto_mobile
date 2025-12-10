import 'package:flutter/material.dart';
import 'responsive_helpers.dart';

class ActionButtonWidget extends StatelessWidget {
  final String text;
  final IconData? icon; // allow null, will fallback to default
  final Color textColor;
  final Color backgroundColor;
  final bool isTablet;
  final bool isLandscape;
  final VoidCallback onPressed;

  const ActionButtonWidget({
    super.key,
    required this.text,
    this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.isTablet,
    required this.isLandscape,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final iconData = icon ?? null;

    // Responsive icon size
    double iconSize;
    if (screenWidth > 1200) {
      iconSize = isLandscape ? 18 : 20;
    } else if (screenWidth > 600) {
      iconSize = isLandscape ? 16 : 18;
    } else if (screenWidth > 400) {
      iconSize = isLandscape ? 14 : 15;
    } else {
      iconSize = isLandscape ? 12 : 14;
    }

    // Responsive font size
    double fontSize;
    if (screenWidth > 1200) {
      fontSize = isLandscape ? 13 : 14;
    } else if (screenWidth > 600) {
      fontSize = isLandscape ? 12 : 13;
    } else if (screenWidth > 400) {
      fontSize = isLandscape ? 11 : 12;
    } else {
      fontSize = isLandscape ? 10 : 11;
    }

    // Responsive border radius
    double borderRadius;
    if (screenWidth > 1200) {
      borderRadius = 24;
    } else if (screenWidth > 600) {
      borderRadius = 22;
    } else if (screenWidth > 400) {
      borderRadius = 18;
    } else {
      borderRadius = 16;
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: iconData != null ? Icon(
        iconData,
        color: textColor,
        size: iconSize,
      ) : null,
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
    );
  }
}
