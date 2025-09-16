import 'package:flutter/material.dart';

class ResponsiveHelpers {
  static double getResponsiveMaxWidth(double screenWidth, bool isGameOver, bool isTablet) {
    if (screenWidth > 1200) { // Large desktop
      return isGameOver ? 400 : 480;
    } else if (screenWidth > 900) { // Desktop
      return isGameOver ? 360 : 440;
    } else if (screenWidth > 600) { // Tablet
      return isGameOver ? 320 : 380;
    } else if (screenWidth > 400) { // Large phone
      return screenWidth * (isGameOver ? 0.75 : 0.85);
    } else { // Small phone
      return screenWidth * (isGameOver ? 0.85 : 0.90);
    }
  }

  static double getResponsiveMaxHeight(double screenHeight, bool isGameOver, bool isLandscape) {
    final baseRatio = isGameOver 
      ? (isLandscape ? 0.80 : 0.55)  // Tăng từ 0.65 lên 0.80 cho Game Over landscape
      : (isLandscape ? 0.85 : 0.70); // Tăng từ 0.75 lên 0.85 cho Victory landscape
    
    if (screenHeight < 600) { // Small screen
      return screenHeight * (baseRatio + 0.05);
    } else if (screenHeight > 900) { // Large screen
      return screenHeight * (baseRatio - 0.05);
    }
    return screenHeight * baseRatio;
  }

  static double getResponsiveMinWidth(double screenWidth, bool isGameOver) {
    if (screenWidth < 360) {
      return screenWidth * 0.8;
    }
    return isGameOver ? 280 : 300;
  }

  static EdgeInsets getResponsivePadding(double screenWidth, double screenHeight, bool isTablet, bool isGameOver, String section) {
    final scale = screenWidth < 400 ? 0.8 : (screenWidth > 800 ? 1.2 : 1.0);
    
    switch (section) {
      case 'header':
        return EdgeInsets.all((isTablet ? 16 : 12) * scale);
      case 'content':
        return EdgeInsets.all((isTablet ? 16 : (isGameOver ? 10 : 12)) * scale);
      case 'actions':
        return EdgeInsets.all((isTablet ? 14 : (isGameOver ? 10 : 12)) * scale);
      default:
        return EdgeInsets.all(12 * scale);
    }
  }

  static double getResponsiveIconSize(double screenWidth, double screenHeight, bool isGameOver, bool isTablet, bool isLandscape, String status) {
    double baseSize;
    
    if (screenWidth > 800) { // Desktop/Large tablet
      baseSize = isLandscape ? 80.0 : 90.0;
    } else if (screenWidth > 600) { // Tablet
      baseSize = isLandscape ? 70.0 : 80.0;
    } else if (screenWidth > 400) { // Large phone
      baseSize = isLandscape ? 60.0 : 70.0;
    } else { // Small phone
      baseSize = isLandscape ? 50.0 : 60.0;
    }
    
    return isGameOver ? baseSize * 0.6 : (status == 'VICTORY' ? baseSize * 0.8 : baseSize);
  }

  static double getResponsiveFontSize(double screenWidth, double screenHeight, bool isGameOver, bool isTablet, String type, String status) {
    double baseSize;
    
    switch (type) {
      case 'title':
        if (screenWidth > 800) {
          baseSize = 28.0;
        } else if (screenWidth > 600) {
          baseSize = 24.0;
        } else if (screenWidth > 400) {
          baseSize = 20.0;
        } else {
          baseSize = 18.0;
        }
        if (isGameOver) {
          return baseSize * 0.75; // Smaller for Game Over
        } else if (status == 'VICTORY') {
          return baseSize * 0.85; // Smaller for Victory
        }
        return baseSize;
      case 'status':
        if (screenWidth > 800) {
          baseSize = 16.0;
        } else if (screenWidth > 600) {
          baseSize = 14.0;
        } else {
          baseSize = 12.0;
        }
        if (isGameOver) {
          return baseSize * 0.8; // Smaller for Game Over
        } else if (status == 'VICTORY') {
          return baseSize * 0.9; // Smaller for Victory
        }
        return baseSize;
      case 'reason':
        if (screenWidth > 800) {
          baseSize = 15.0;
        } else if (screenWidth > 600) {
          baseSize = 14.0;
        } else if (screenWidth > 400) {
          baseSize = 13.0;
        } else {
          baseSize = 12.0;
        }
        return baseSize * 0.9; // Make defeat reason smaller
      default:
        return 14.0;
    }
  }

  static double getButtonPadding(double screenWidth, bool isTablet, String direction) {
    final scale = screenWidth < 400 ? 0.7 : (screenWidth > 800 ? 1.0 : 0.85);
    
    if (direction == 'horizontal') {
      return (isTablet ? 20 : 14) * scale;
    } else {
      return (isTablet ? 10 : 8) * scale;
    }
  }

  static LinearGradient getStatusGradient(String status) {
    switch (status) {
      case 'VICTORY':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4CAF50),
            Color(0xFF2E7D32),
            Color(0xFF1B5E20),
          ],
        );
      case 'LOSE':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE53E3E),
            Color(0xFFC53030),
            Color(0xFF9B2C2C),
          ],
        );
      case 'ERROR':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9800),
            Color(0xFFE65100),
            Color(0xFFBF360C),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
            Color(0xFF0D47A1),
          ],
        );
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'VICTORY':
        return Icons.emoji_events;
      case 'LOSE':
        return Icons.sentiment_very_dissatisfied;
      case 'PROGRESS':
        return Icons.trending_up;
      case 'ERROR':
        return Icons.error;
      case 'READY':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}
