import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/blog_comment_model.dart';
import 'package:ottobit/services/blog_service.dart';
import 'package:ottobit/widgets/news/comment_card.dart';
import 'package:ottobit/widgets/news/comment_input_widget.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class CommentsSection extends StatefulWidget {
  final String blogId;
  final String? currentUserId;

  const CommentsSection({
    super.key,
    required this.blogId,
    this.currentUserId,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final BlogService _blogService = BlogService();
  final ScrollController _scrollController = ScrollController();
  
  List<BlogComment> _comments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  BlogComment? _editingComment;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final response = await _blogService.getBlogComments(
        blogId: widget.blogId,
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        setState(() {
          _comments = response.data?.items ?? [];
          _hasMore = _currentPage < (response.data?.totalPages ?? 0);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final errorMsg = ApiErrorMapper.fromException(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  Future<void> _refreshComments() async {
    try {
      final response = await _blogService.getBlogComments(
        blogId: widget.blogId,
        page: 1,
        size: 10,
      );

      if (mounted) {
        setState(() {
          _comments = response.data?.items ?? [];
          _currentPage = 1;
          _hasMore = _currentPage < (response.data?.totalPages ?? 0);
        });
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ApiErrorMapper.fromException(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await _blogService.getBlogComments(
        blogId: widget.blogId,
        page: _currentPage,
        size: 10,
      );

      if (mounted) {
        setState(() {
          _comments.addAll(response.data?.items ?? []);
          _hasMore = _currentPage < (response.data?.totalPages ?? 0);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final errorMsg = ApiErrorMapper.fromException(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  Future<void> _submitComment(String content) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_editingComment != null) {
        // Update existing comment
        await _blogService.updateComment(
          commentId: _editingComment!.id,
          content: content,
        );
        
        // Reload comments to get updated data from server
        await _refreshComments();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('news.commentUpdated'.tr())),
        );
      } else {
        // Create new comment
        await _blogService.createComment(
          blogId: widget.blogId,
          content: content,
        );
        
        // Reload comments to get fresh data from server
        await _refreshComments();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('news.commentPosted'.tr())),
        );
      }
    } catch (e) {
      final errorMsg = ApiErrorMapper.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _editingComment = null; // Clear editing state
        });
      }
    }
  }

  Future<void> _deleteComment(BlogComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('news.deleteComment'.tr()),
        content: Text('news.deleteCommentConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('news.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _blogService.deleteComment(commentId: comment.id);
        
        // Reload comments to get fresh data from server
        await _refreshComments();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('news.commentDeleted'.tr())),
        );
      } catch (e) {
        final errorMsg = ApiErrorMapper.fromException(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    }
  }

  void _editComment(BlogComment comment) {
    setState(() {
      _editingComment = comment;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingComment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Icon(
                Icons.comment_outlined,
                color: const Color(0xFF17a64b),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'news.comments'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF17a64b).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _comments.length.toString(),
                  style: TextStyle(
                    color: const Color(0xFF17a64b),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Comment input
        CommentInputWidget(
          key: ValueKey(_editingComment?.id ?? 'new'),
          hintText: 'news.writeComment'.tr(),
          initialValue: _editingComment?.content,
          onSubmit: _submitComment,
          onCancel: _cancelEdit,
          isLoading: _isSubmitting,
        ),
        
        const SizedBox(height: 16),
        
        // Comments list
        if (_comments.isEmpty && !_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'news.noComments'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'news.beFirstToComment'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= _comments.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final comment = _comments[index];
              return CommentCard(
                comment: comment,
                currentUserId: widget.currentUserId,
                onEdit: () => _editComment(comment),
                onDelete: () => _deleteComment(comment),
              );
            },
          ),
      ],
    );
  }
}
