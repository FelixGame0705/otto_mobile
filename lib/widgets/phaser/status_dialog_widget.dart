import 'dart:convert';
import 'package:flutter/material.dart';
import 'responsive_helpers.dart';
import 'stat_card_widget.dart';
import 'action_button_widget.dart';
import 'defeat_reason_widget.dart';

class StatusDialogWidget extends StatelessWidget {
  final String status;
  final String title;
  final Color color;
  final Map<String, dynamic> data;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;

  const StatusDialogWidget({
    super.key,
    required this.status,
    required this.title,
    required this.color,
    required this.data,
    required this.onPlayAgain,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isGameOver = status == 'LOSE';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? 40 : 24, 
            vertical: screenHeight > 800 
              ? (isGameOver ? 20 : 24) 
              : (isGameOver ? 16 : 20),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = screenWidth > 600;
              final isLandscape = screenWidth > screenHeight;
              
              return Container(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelpers.getResponsiveMaxWidth(screenWidth, isGameOver, isTablet),
                  maxHeight: ResponsiveHelpers.getResponsiveMaxHeight(screenHeight, isGameOver, isLandscape),
                  minWidth: ResponsiveHelpers.getResponsiveMinWidth(screenWidth, isGameOver),
                ),
                decoration: BoxDecoration(
                  gradient: ResponsiveHelpers.getStatusGradient(status),
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: isTablet ? 25 : 15,
                      spreadRadius: isTablet ? 8 : 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(screenWidth, screenHeight, isTablet, isLandscape, isGameOver),
                    _buildContent(screenWidth, screenHeight, isTablet, isLandscape, isGameOver, context),
                    _buildActions(screenWidth, screenHeight, isTablet, isLandscape, isGameOver),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight, bool isTablet, bool isLandscape, bool isGameOver) {
    return Container(
      padding: ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'header'),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 24 : 16),
          topRight: Radius.circular(isTablet ? 24 : 16),
        ),
      ),
      child: Column(
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              final iconSize = ResponsiveHelpers.getResponsiveIconSize(screenWidth, screenHeight, isGameOver, isTablet, isLandscape, status);
              final iconInnerSize = iconSize * 0.5;
              
              return Transform.scale(
                scale: value,
                child: Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: isTablet ? 20 : 15,
                        spreadRadius: isTablet ? 8 : 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    ResponsiveHelpers.getStatusIcon(status),
                    color: color,
                    size: iconInnerSize,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isTablet ? 20 : (isLandscape ? 12 : 16)),
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelpers.getResponsiveFontSize(screenWidth, screenHeight, isGameOver, isTablet, 'title', status),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 12 : 8),
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16, 
              vertical: isTablet ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelpers.getResponsiveFontSize(screenWidth, screenHeight, isGameOver, isTablet, 'status', status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth, double screenHeight, bool isTablet, bool isLandscape, bool isGameOver, BuildContext context) {
    return Flexible(
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'content'),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == 'VICTORY') ...[
                StatCardWidget(
                  label: 'Score',
                  value: '${data['score'] ?? 0}',
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                StatCardWidget(
                  label: 'Batteries',
                  value: '${data['collectedBatteries'] ?? 0}',
                  icon: Icons.battery_charging_full,
                  iconColor: Colors.green,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                StatCardWidget(
                  label: 'Map',
                  value: '${data['mapKey'] ?? 'Unknown'}',
                  icon: Icons.map,
                  iconColor: Colors.blue,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                ),
              ] else if (status == 'LOSE') ...[
                DefeatReasonWidget(
                  data: data,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  status: status,
                ),
              ],
              
              // Only show details for non-Game Over or if user wants to see them
              if (!isGameOver) ...[
                SizedBox(height: isTablet ? 20 : 16),
                
                // Expandable details section
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white70,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        margin: EdgeInsets.only(top: isTablet ? 12 : 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          const JsonEncoder.withIndent('  ').convert(data),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: isTablet ? 13 : (isLandscape ? 10 : 11),
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(double screenWidth, double screenHeight, bool isTablet, bool isLandscape, bool isGameOver) {
    if (status == 'VICTORY' || status == 'LOSE') {
      return Container(
        padding: ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'actions'),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isTablet ? 24 : 16),
            bottomRight: Radius.circular(isTablet ? 24 : 16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ActionButtonWidget(
                text: 'Play Again',
                icon: Icons.refresh,
                textColor: Colors.white,
                backgroundColor: color.withOpacity(0.15),
                isTablet: isTablet,
                isLandscape: isLandscape,
                onPressed: onPlayAgain,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ActionButtonWidget(
                text: 'Close',
                icon: Icons.close,
                textColor: Colors.white70,
                backgroundColor: Colors.white.withOpacity(0.1),
                isTablet: isTablet,
                isLandscape: isLandscape,
                onPressed: onClose,
              ),
            ),
          ],
        ),
      );
    } else if (status != 'VICTORY' && status != 'LOSE') {
      // Actions for other dialogs (READY, ERROR, etc.)
      return Container(
        padding: ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'actions'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActionButtonWidget(
              text: 'Close',
              icon: Icons.close,
              textColor: Colors.white70,
              backgroundColor: Colors.white.withOpacity(0.1),
              isTablet: isTablet,
              isLandscape: isLandscape,
              onPressed: onClose,
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }
}
