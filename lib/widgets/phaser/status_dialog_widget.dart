import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:otto_mobile/features/phaser/phaser_bridge.dart';
import 'package:otto_mobile/services/submission_service.dart';
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
        const SnackBar(
          content: Text('Missing challenge ID. Cannot submit without a valid challenge.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (widget.codeJson == null || widget.codeJson!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing code data. Please create some blocks first.'),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          SizedBox(height: isTablet ? 20 : (isLandscape ? 12 : 16)),
          // Title
          Text(
            widget.title,
            style: TextStyle(
              fontSize: ResponsiveHelpers.getResponsiveFontSize(screenWidth, screenHeight, isGameOver, isTablet, 'title', widget.status),
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
      // For VICTORY, use a fixed height container without scroll
      return Container(
        width: double.infinity,
        height: isTablet ? 70 : (isLandscape ? 40 : 60),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: isTablet ? 12 : 8,
        ),
        child: _buildStarsSection(isTablet, isLandscape),
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

  Widget _buildStarsSection(bool isTablet, bool isLandscape) {
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Star rating with animation
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final filled = index < stars;
                final starSize = isTablet ? 36.0 : (isLandscape ? 24.0 : 30.0);
                
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, starValue, child) {
                    return Transform.scale(
                      scale: filled ? starValue : 0.8,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 8),
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
    );
  }

  Widget _buildActions(double screenWidth, double screenHeight, bool isTablet, bool isLandscape, bool isGameOver) {
    if (widget.status == 'VICTORY' || widget.status == 'LOSE') {
      final basePad = ResponsiveHelpers.getResponsivePadding(screenWidth, screenHeight, isTablet, isGameOver, 'actions');
      final tightTopPad = EdgeInsets.only(
        left: basePad.left,
        right: basePad.right,
        bottom: basePad.bottom,
        top: 0,
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
                  ? (_isSubmitting ? 'Submitting...' : 'Submit')
                  : 'Play Again',
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
                          if (widget.bridge != null) {
                            widget.bridge!.restartScene();
                          }
                          widget.onPlayAgain();
                        }),
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
              text: 'Close',
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
