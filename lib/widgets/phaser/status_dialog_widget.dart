import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/features/phaser/phaser_bridge.dart';
import 'package:ottobit/services/submission_service.dart';
import 'responsive_helpers.dart';
import 'action_button_widget.dart';
import 'defeat_reason_widget.dart';

class StatusDialogWidget extends StatefulWidget {
  final String status;
  final String title;
  final Color color;
  final Map<String, dynamic> data;
  final PhaserBridge? bridge;
  final String? challengeId;
  final String? codeJson;
  final VoidCallback onPlayAgain;
  final VoidCallback onClose;
  final VoidCallback? onSimulation;

  const StatusDialogWidget({
    super.key,
    required this.status,
    required this.title,
    required this.color,
    required this.data,
    this.bridge,
    this.challengeId,
    this.codeJson,
    required this.onPlayAgain,
    required this.onClose,
    this.onSimulation,
  });

  @override
  State<StatusDialogWidget> createState() => _StatusDialogWidgetState();
}

class _StatusDialogWidgetState extends State<StatusDialogWidget> {
  final SubmissionService _submissionService = SubmissionService();
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    debugPrint('🔍 Submit attempt - ChallengeId: ${widget.challengeId}, CodeJson: ${widget.codeJson}');
    
    if (widget.challengeId == null || widget.challengeId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('phaser.missingChallengeId'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (widget.codeJson == null || widget.codeJson!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('phaser.missingCodeData'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate stars from the victory data
      final dynamicCardScore = widget.data['cardScore'] ?? (widget.data['details'] is Map<String, dynamic> ? widget.data['details']['cardScore'] : null);
      double normalizedScore;
      if (dynamicCardScore is num) {
        normalizedScore = dynamicCardScore.toDouble();
      } else {
        final rawScore = widget.data['score'];
        if (rawScore is num) {
          final s = rawScore.toDouble();
          normalizedScore = s <= 1.0 ? s : (s / 100.0);
        } else {
          normalizedScore = 0.0;
        }
      }
      int stars = (normalizedScore * 3).ceil();
      if (stars < 1) stars = 1;
      if (stars > 3) stars = 3;

      final response = await _submissionService.createSubmission(
        challengeId: widget.challengeId!,
        codeJson: widget.codeJson!,
        star: stars,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
        
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('phaser.submissionFailed'.tr(args: [e.toString()])),
            backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGameOver = widget.status == 'LOSE';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 16,
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth > 1200 
              ? 60 
              : screenWidth > 900 
                ? 50 
                : screenWidth > 600 
                  ? 40 
                  : screenWidth > 500 
                    ? 32  // Samsung A23 (720px) - tăng padding để dialog nhỏ hơn
                  : screenWidth > 400 
                    ? 24 
                    : 16,
            vertical: screenHeight > 1200 
              ? (isGameOver ? 40 : 50)
              : screenHeight > 900 
                ? (isGameOver ? 30 : 40)
                : screenHeight > 800 
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
                  gradient: ResponsiveHelpers.getStatusGradient(widget.status),
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.3),
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
              final iconSize = ResponsiveHelpers.getResponsiveIconSize(screenWidth, screenHeight, isGameOver, isTablet, isLandscape, widget.status);
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
                    ResponsiveHelpers.getStatusIcon(widget.status),
                    color: widget.color,
                    size: iconInnerSize,
                  ),
                ),
              );
            },
          ),
          SizedBox(
            height: screenWidth > 1200 
              ? (isLandscape ? 16 : 24)
              : screenWidth > 600 
                ? (isLandscape ? 12 : 20)
                : screenWidth > 500
                  ? (isLandscape ? 8 : 12)  // Giảm spacing cho Samsung A23
                : (isLandscape ? 10 : 16),
          ),
          // Title
          Text(
            widget.status == 'LOSE' ? 'phaser.gameOverTitle'.tr() : widget.title,
            style: TextStyle(
              fontSize: widget.status == 'VICTORY' 
                ? ResponsiveHelpers.getResponsiveFontSize(screenWidth, screenHeight, isGameOver, isTablet, 'title', widget.status) * (screenWidth > 500 && screenWidth <= 800 ? 0.90 : 0.85)
                : ResponsiveHelpers.getResponsiveFontSize(screenWidth, screenHeight, isGameOver, isTablet, 'title', widget.status),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            height: widget.status == 'VICTORY'
              ? (screenWidth > 1200 
                ? 24
                : screenWidth > 600 
                  ? 20
                  : screenWidth > 500
                    ? 12  // Giảm spacing cho Samsung A23
                  : screenWidth > 400
                    ? 16
                    : 12)
              : (screenWidth > 1200 
                ? 16
                : screenWidth > 600 
                  ? 12
                  : 8),
          ),
          // Status badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 1200 
                ? 24
                : screenWidth > 600 
                  ? 20 
                  : screenWidth > 500
                    ? 14  // Giảm padding cho Samsung A23
                  : screenWidth > 400 
                    ? 16 
                    : 12,
              vertical: screenWidth > 1200 
                ? 10
                : screenWidth > 600 
                  ? 8 
                  : screenWidth > 500
                    ? 5  // Giảm padding cho Samsung A23
                  : screenWidth > 400 
                    ? 6 
                    : 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              widget.status,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelpers.getResponsiveFontSize(screenWidth, screenHeight, isGameOver, isTablet, 'status', widget.status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth, double screenHeight, bool isTablet, bool isLandscape, bool isGameOver, BuildContext context) {
    if (widget.status == 'VICTORY') {
      // For VICTORY, use a responsive height container without scroll
      // Tính toán height dựa trên star size và padding để tránh overflow
      double starSize;
      if (screenWidth > 1200) {
        starSize = isLandscape ? 32.0 : 42.0;
      } else if (screenWidth > 900) {
        starSize = isLandscape ? 28.0 : 38.0;
      } else if (screenWidth > 600) {
        starSize = isLandscape ? 24.0 : 36.0;
      } else if (screenWidth > 500) {
        // Samsung A23 (720px) và các màn hình tương tự - tăng sao lên để dễ nhìn hơn
        starSize = isLandscape ? 24.0 : 36.0;
      } else if (screenWidth > 400) {
        starSize = isLandscape ? 20.0 : 30.0;
      } else {
        starSize = isLandscape ? 18.0 : 26.0;
      }
      
      // Tính height dựa trên star size + padding (star size + glow effect + padding)
      // Giảm padding để tránh overflow trên Samsung A23
      double topPadding = screenWidth > 1200 
        ? 24 
        : screenWidth > 600 
          ? 20 
          : screenWidth > 500
            ? 12  // Giảm từ 18 xuống 12
          : screenWidth > 400 
            ? 16 
            : 12;
      double bottomPadding = screenWidth > 1200
        ? (isLandscape ? 8 : 12)
        : screenWidth > 600
          ? (isLandscape ? 6 : 10)
          : screenWidth > 500
            ? (isLandscape ? 3 : 6)  // Giảm từ 5/9 xuống 3/6
          : screenWidth > 400
            ? (isLandscape ? 4 : 8)
            : (isLandscape ? 2 : 6);
      
      // Height = star size + glow effect (8px) + top padding + bottom padding + extra space
      // Giảm extra space để tránh overflow trên màn hình nhỏ
      double extraSpace = isLandscape ? 1 : 2;  // Giảm từ 2/4 xuống 1/2
      double calculatedHeight = starSize + 8 + topPadding + bottomPadding + extraSpace;
      
      // Giới hạn height tối đa để tránh overflow - giảm mạnh cho Samsung A23
      double maxHeight;
      if (screenWidth > 1200) {
        maxHeight = isLandscape ? 50 : 80;
      } else if (screenWidth > 900) {
        maxHeight = isLandscape ? 45 : 75;
      } else if (screenWidth > 600) {
        maxHeight = isLandscape ? 40 : 70;
      } else if (screenWidth > 500) {
        // Samsung A23 (720px) - giảm height để tránh overflow (36 + 8 + 12 + 6 + 2 = 64)
        maxHeight = isLandscape ? 32 : 64;
      } else if (screenWidth > 400) {
        maxHeight = isLandscape ? 32 : 55;
      } else {
        maxHeight = isLandscape ? 28 : 48;
      }
      
      // Sử dụng giá trị nhỏ hơn để tránh overflow
      double height = calculatedHeight < maxHeight ? calculatedHeight : maxHeight;
      
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: height,
          maxHeight: height,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth > 1200 
            ? 32 
            : screenWidth > 600 
              ? 24 
              : screenWidth > 400 
                ? 16 
                : 12,
          vertical: 0, // Sử dụng top và bottom riêng
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: topPadding,
            bottom: bottomPadding,
          ),
          child: _buildStarsSection(isTablet, isLandscape, screenWidth),
        ),
      );
    }
    
    return Flexible(
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'content'),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.status == 'LOSE') ...[
                DefeatReasonWidget(
                  data: widget.data,
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  status: widget.status,
                ),
              ],
              
              // Only show details for non-Game Over or if user wants to see them
              if (!isGameOver && widget.status != 'VICTORY') ...[
                SizedBox(height: isTablet ? 20 : 16),
                
                // Expandable details section
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      'phaser.details'.tr(),
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
                          const JsonEncoder.withIndent('  ').convert(widget.data),
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

  Widget _buildStarsSection(bool isTablet, bool isLandscape, double screenWidth) {
    final dynamicCardScore = widget.data['cardScore'] ?? (widget.data['details'] is Map<String, dynamic> ? widget.data['details']['cardScore'] : null);
    double normalizedScore;
    if (dynamicCardScore is num) {
      normalizedScore = dynamicCardScore.toDouble();
    } else {
      final rawScore = widget.data['score'];
      if (rawScore is num) {
        final s = rawScore.toDouble();
        normalizedScore = s <= 1.0 ? s : (s / 100.0);
      } else {
        normalizedScore = 0.0;
      }
    }
    int stars = (normalizedScore * 3).ceil();
    if (stars < 1) stars = 1;
    if (stars > 3) stars = 3;

    // Responsive star size
    double starSize;
    if (screenWidth > 1200) {
      starSize = isLandscape ? 32.0 : 42.0;
    } else if (screenWidth > 900) {
      starSize = isLandscape ? 28.0 : 38.0;
    } else if (screenWidth > 600) {
      starSize = isLandscape ? 24.0 : 36.0;
    } else if (screenWidth > 500) {
      // Samsung A23 (720px) và các màn hình tương tự - tăng kích thước sao
      starSize = isLandscape ? 24.0 : 36.0;
    } else if (screenWidth > 400) {
      starSize = isLandscape ? 20.0 : 30.0;
    } else {
      starSize = isLandscape ? 18.0 : 26.0;
    }

    // Responsive spacing between stars
    double starSpacing;
    if (screenWidth > 1200) {
      starSpacing = 16.0;
    } else if (screenWidth > 600) {
      starSpacing = 12.0;
    } else if (screenWidth > 500) {
      // Samsung A23 (720px) - tăng spacing một chút cho sao lớn hơn
      starSpacing = 10.0;
    } else if (screenWidth > 400) {
      starSpacing = 8.0;
    } else {
      starSpacing = 6.0;
    }

    return SizedBox(
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star rating with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                final filled = index < stars;
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, starValue, child) {
                    return Transform.scale(
                      scale: filled ? starValue : 0.8,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: starSpacing / 2),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow effect for filled stars
                            if (filled)
                              Container(
                                width: starSize + 8,
                                height: starSize + 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.6),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            // Star icon
                            Icon(
                              filled ? Icons.star : Icons.star_border,
                              color: filled ? Colors.amber : Colors.amber.withOpacity(0.3),
                              size: starSize,
                            ),
                            // Sparkle effect for filled stars
                            if (filled && starValue > 0.8)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (context, sparkleValue, child) {
                                    return Transform.scale(
                                      scale: sparkleValue,
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                        size: starSize * 0.3,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions(double screenWidth, double screenHeight, bool isTablet, bool isLandscape, bool isGameOver) {
    if (widget.status == 'VICTORY' || widget.status == 'LOSE') {
      final basePad = ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'actions');
      
      // Responsive top padding (khoảng cách giữa stars và buttons)
      double topPadding;
      if (widget.status == 'VICTORY') {
        // Khoảng cách cho Victory dialog (giữa stars và buttons) - giảm cho Samsung A23
        if (screenWidth > 1200) {
          topPadding = isLandscape ? 28 : 44;
        } else if (screenWidth > 900) {
          topPadding = isLandscape ? 24 : 38;
        } else if (screenWidth > 600) {
          topPadding = isLandscape ? 20 : 32;
        } else if (screenWidth > 500) {
          // Samsung A23 (720px) - giảm padding để tránh overflow
          topPadding = isLandscape ? 16 : 24;
        } else if (screenWidth > 400) {
          topPadding = isLandscape ? 18 : 28;
        } else {
          topPadding = isLandscape ? 16 : 24;
        }
      } else {
        // Khoảng cách cho Defeat dialog
        topPadding = 0;
      }
      
      final tightTopPad = EdgeInsets.only(
        left: basePad.left,
        right: basePad.right,
        bottom: basePad.bottom,
        top: topPadding,
      );
      return Container(
        padding: tightTopPad,
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
                text: widget.status == 'VICTORY' 
                  ? (_isSubmitting ? 'phaser.submitting'.tr() : 'phaser.submit'.tr())
                  : 'phaser.playAgain'.tr(),
                icon: widget.status == 'VICTORY' 
                  ? (_isSubmitting ? Icons.hourglass_empty : Icons.upload)
                  : Icons.refresh,
                textColor: Colors.white,
                backgroundColor: widget.color.withOpacity(0.15),
                isTablet: isTablet,
                isLandscape: isLandscape,
                onPressed: _isSubmitting 
                  ? () {} // Disabled state
                  : (widget.status == 'VICTORY' 
                      ? _handleSubmit
                      : () {
                          widget.onPlayAgain();
                        }),
              ),
            ),
            SizedBox(
              width: screenWidth > 1200 
                ? 16
                : screenWidth > 600 
                  ? 12 
                  : screenWidth > 400 
                    ? 10 
                    : 8,
            ),
            if (widget.onSimulation != null && widget.status == 'VICTORY') ...[
              Expanded(
                child: ActionButtonWidget(
                  text: 'phaser.simulation'.tr(),
                  icon: null,
                  textColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  isTablet: isTablet,
                  isLandscape: isLandscape,
                  onPressed: () {
                    try {
                      widget.onSimulation!();
                    } finally {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              SizedBox(
                width: screenWidth > 1200 
                  ? 16
                  : screenWidth > 600 
                    ? 12 
                    : screenWidth > 400 
                      ? 10 
                      : 8,
              ),
            ],
            Expanded(
              child: ActionButtonWidget(
                text: 'phaser.close'.tr(),
                icon: Icons.close,
                textColor: Colors.white70,
                backgroundColor: Colors.white.withOpacity(0.1),
                isTablet: isTablet,
                isLandscape: isLandscape,
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      );
    } else if (widget.status != 'VICTORY' && widget.status != 'LOSE') {
      // Actions for other dialogs (READY, ERROR, etc.)
      return Container(
        padding: ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'actions'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ActionButtonWidget(
              text: 'phaser.close'.tr(),
              icon: Icons.close,
              textColor: Colors.white70,
              backgroundColor: Colors.white.withOpacity(0.1),
              isTablet: isTablet,
              isLandscape: isLandscape,
              onPressed: widget.onClose,
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  }
}
