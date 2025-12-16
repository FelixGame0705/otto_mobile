import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'responsive_helpers.dart';

class DefeatReasonWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isTablet;
  final bool isLandscape;
  final double screenWidth;
  final double screenHeight;
  final String status;

  const DefeatReasonWidget({
    super.key,
    required this.data,
    required this.isTablet,
    required this.isLandscape,
    required this.screenWidth,
    required this.screenHeight,
    required this.status,
  });

  @override
  State<DefeatReasonWidget> createState() => _DefeatReasonWidgetState();
}

class _DefeatReasonWidgetState extends State<DefeatReasonWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isGameOver = widget.status == 'LOSE';
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(widget.isTablet ? 16 : 12),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with expand/collapse button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.isTablet ? 16 : 12),
              topRight: Radius.circular(widget.isTablet ? 16 : 12),
              bottomLeft: _isExpanded ? Radius.zero : Radius.circular(widget.isTablet ? 16 : 12),
              bottomRight: _isExpanded ? Radius.zero : Radius.circular(widget.isTablet ? 16 : 12),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(widget.isTablet ? 14 : 12),
              decoration: BoxDecoration(
                color: _isExpanded ? Colors.red.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.isTablet ? 16 : 12),
                  topRight: Radius.circular(widget.isTablet ? 16 : 12),
                  bottomLeft: _isExpanded ? Radius.zero : Radius.circular(widget.isTablet ? 16 : 12),
                  bottomRight: _isExpanded ? Radius.zero : Radius.circular(widget.isTablet ? 16 : 12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red[300],
                    size: ResponsiveHelpers.getResponsiveIconSize(
                      widget.screenWidth, 
                      widget.screenHeight, 
                      isGameOver, 
                      widget.isTablet, 
                      widget.isLandscape, 
                      widget.status
                    ) * 0.25,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isExpanded 
                        ? 'phaser.defeatReasonTitle'.tr()
                        : 'phaser.defeatReasonPrefix'.tr() + ' ${widget.data['message'] ?? 'phaser.defeatDefault'.tr()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelpers.getResponsiveFontSize(
                          widget.screenWidth, 
                          widget.screenHeight, 
                          isGameOver, 
                          widget.isTablet, 
                          'reason', 
                          widget.status
                        ),
                      ),
                      maxLines: _isExpanded ? 1 : (widget.isLandscape ? 1 : 2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Custom expand/collapse button with text
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'phaser.collapse'.tr() : 'phaser.expand'.tr(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: widget.isTablet ? 11 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white70,
                            size: widget.isTablet ? 18 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content with landscape optimization
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: _isExpanded ? 1.0 : 0.0,
              child: _isExpanded 
                ? Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      widget.isTablet ? 16 : 12,
                      8,
                      widget.isTablet ? 16 : 12,
                      widget.isTablet ? 16 : 12,
                    ),
                    child: widget.isLandscape 
                      ? _buildLandscapeLayout()
                      : _buildPortraitLayout(),
                  )
                : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    final isGameOver = widget.status == 'LOSE';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Main reason
        Expanded(
          flex: 2,
          child: Container(
            padding: EdgeInsets.all(widget.isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
              border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[300],
                      size: widget.isTablet ? 18 : 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'phaser.errorDetails'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.isTablet ? 13 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '${widget.data['message'] ?? 'phaser.defeatDefault'.tr()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelpers.getResponsiveFontSize(
                      widget.screenWidth, 
                      widget.screenHeight, 
                      isGameOver, 
                      widget.isTablet, 
                      'reason', 
                      widget.status
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.data['collectedBatteries'] != null) ...[
          SizedBox(width: 12),
          // Right side - Progress info
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(widget.isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
                border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.battery_charging_full,
                        color: Colors.orange[300],
                        size: widget.isTablet ? 18 : 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'phaser.progress'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.isTablet ? 13 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'phaser.batteriesCollected'.tr(namedArgs: {'count': '${widget.data['collectedBatteries']}'}),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: widget.isTablet ? 12 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPortraitLayout() {
    final isGameOver = widget.status == 'LOSE';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(widget.isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.data['message'] ?? 'phaser.defeatDefault'.tr()}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveHelpers.getResponsiveFontSize(
                    widget.screenWidth, 
                    widget.screenHeight, 
                    isGameOver, 
                    widget.isTablet, 
                    'reason', 
                    widget.status
                  ),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.data['collectedBatteries'] != null) ...[
                SizedBox(height: widget.isTablet ? 12 : 10),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isTablet ? 12 : 10,
                    vertical: widget.isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(widget.isTablet ? 12 : 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.battery_charging_full,
                        color: Colors.orange[300],
                        size: widget.isTablet ? 16 : 14,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'phaser.progressWithBatteries'.tr(namedArgs: {'count': '${widget.data['collectedBatteries']}'}),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: widget.isTablet ? 12 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
