import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:ottobit/models/course_rating_model.dart';
import 'package:ottobit/services/course_rating_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CourseRatingWidget extends StatefulWidget {
  final String courseId;
  final String? currentStudentId;

  const CourseRatingWidget({
    super.key,
    required this.courseId,
    this.currentStudentId,
  });

  @override
  State<CourseRatingWidget> createState() => _CourseRatingWidgetState();
}

class _CourseRatingWidgetState extends State<CourseRatingWidget> {
  final CourseRatingService _ratingService = CourseRatingService();
  final ScrollController _scrollController = ScrollController();
  
  List<CourseRating> _ratings = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  CourseRating? _userRating;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRatings();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRatings();
    }
  }

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final response = await _ratingService.getCourseRatings(
        courseId: widget.courseId,
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        setState(() {
          _ratings = response.data?.items ?? [];
          _hasMore = _currentPage < (response.data?.totalPages ?? 0);
          _isLoading = false;
        });
      }

      // Load my rating using the dedicated endpoint for accurate ownership
      await _loadMyRating();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  Future<void> _loadMyRating() async {
    try {
      final myResp = await _ratingService.getMyRating(courseId: widget.courseId);
      if (!mounted) return;
      setState(() {
        _userRating = myResp.data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _userRating = null;
      });
    }
  }

  Future<void> _loadMoreRatings() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await _ratingService.getCourseRatings(
        courseId: widget.courseId,
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        setState(() {
          _ratings.addAll(response.data?.items ?? []);
          _hasMore = _currentPage < (response.data?.totalPages ?? 0);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  // _findUserRating deprecated; using _loadMyRating instead

  void _showRatingDialog({CourseRating? existingRating}) {
    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        courseId: widget.courseId,
        existingRating: existingRating,
        onSubmit: () {
          _loadRatings(); // Reload ratings after submit
        },
      ),
    );
  }

  Future<void> _deleteRating() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('course.deleteRating'.tr()),
        content: Text('course.confirmDeleteRating'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _ratingService.deleteRating(courseId: widget.courseId);
        _loadRatings(); // Reload ratings after delete
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('course.ratingDeleted'.tr())),
        );
      } catch (e) {
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'course.rating'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // User Rating Section
          if (widget.currentStudentId != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'course.yourRating'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_userRating != null) ...[
                    Row(
                      children: [
                        _buildStarRating(_userRating!.stars, false),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _userRating!.comment.isNotEmpty 
                                ? _userRating!.comment 
                                : 'course.noComment'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showRatingDialog(existingRating: _userRating),
                          icon: const Icon(Icons.edit, size: 16, color: Color(0xFF17A64B)),
                          label: Text('course.updateRating'.tr(), style: TextStyle(color: Color(0xFF17A64B))),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _deleteRating,
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          label: Text('course.deleteRating'.tr()),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      'course.noRating'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showRatingDialog(),
                      icon: const Icon(Icons.star, size: 16),
                      label: Text('course.rateCourse'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4299E1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // All Ratings Section
          Text(
            'course.allRatings'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Ratings List
          if (_ratings.isEmpty && !_isLoading)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'course.noRating'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ratings.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _ratings.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                final rating = _ratings[index];
                return _RatingCard(
                  rating: rating,
                  currentStudentId: widget.currentStudentId,
                  onRefresh: _loadRatings,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int stars, bool interactive) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: const Color(0xFFF6AD55),
          size: 20,
        );
      }),
    );
  }
}

class _RatingCard extends StatelessWidget {
  final CourseRating rating;
  final String? currentStudentId;
  final VoidCallback? onRefresh;

  const _RatingCard({
    required this.rating,
    this.currentStudentId,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.stars ? Icons.star : Icons.star_border,
                    color: const Color(0xFFF6AD55),
                    size: 16,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${rating.stars} ${'course.stars'.tr()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(rating.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.4,
              ),
            ),
          ],
          
          // Edit/Delete buttons for user's own ratings
          if (currentStudentId != null && rating.studentId == currentStudentId) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(context),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text('course.updateRating'.tr()),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: Text('course.deleteRating'.tr()),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _RatingDialog(
        courseId: rating.courseId,
        existingRating: rating,
        onSubmit: () {
          onRefresh?.call();
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('course.deleteRating'.tr()),
        content: Text('course.confirmDeleteRating'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteRating(context);
            },
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRating(BuildContext context) async {
    try {
      final ratingService = CourseRatingService();
      await ratingService.deleteRating(courseId: rating.courseId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('course.ratingDeleted'.tr())),
      );
      
      onRefresh?.call();
    } catch (e) {
      final isEnglish = context.locale.languageCode == 'en';
      final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }
}

class _RatingDialog extends StatefulWidget {
  final String courseId;
  final CourseRating? existingRating;
  final VoidCallback onSubmit;

  const _RatingDialog({
    required this.courseId,
    this.existingRating,
    required this.onSubmit,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  final CourseRatingService _ratingService = CourseRatingService();
  final TextEditingController _commentController = TextEditingController();
  int _selectedStars = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _selectedStars = widget.existingRating!.stars;
      _commentController.text = widget.existingRating!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('course.selectStars'.tr())),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.existingRating != null) {
        // Update existing rating
        await _ratingService.updateRating(
          courseId: widget.courseId,
          stars: _selectedStars,
          comment: _commentController.text.trim(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('course.ratingUpdated'.tr())),
        );
      } else {
        // Create new rating
        await _ratingService.createRating(
          courseId: widget.courseId,
          stars: _selectedStars,
          comment: _commentController.text.trim(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('course.ratingSubmitted'.tr())),
        );
      }
      
      Navigator.of(context).pop();
      widget.onSubmit();
    } catch (e) {
      final isEnglish = context.locale.languageCode == 'en';
      final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(widget.existingRating != null 
          ? 'course.updateRating'.tr() 
          : 'course.rateCourse'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star Rating
          Text(
            'course.selectStars'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStars = index + 1;
                  });
                },
                child: Icon(
                  index < _selectedStars ? Icons.star : Icons.star_border,
                  color: const Color(0xFFF6AD55),
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          
          // Comment Field
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'course.ratingComment'.tr(),
              hintText: 'course.ratingCommentHint'.tr(),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text('common.cancel'.tr(), style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitRating,
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF17A64B)),
          child: _isSubmitting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingRating != null 
                  ? 'course.updateRating'.tr() 
                  : 'course.submitRating'.tr(), style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
