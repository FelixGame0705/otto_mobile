import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/blog_comment_model.dart';

class CommentCard extends StatelessWidget {
  final BlogComment comment;
  final String? currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CommentCard({
    super.key,
    required this.comment,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  bool get canEdit => currentUserId != null && currentUserId == comment.userId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and actions
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF17a64b),
                child: Text(
                  (comment.userName?.isNotEmpty == true 
                      ? comment.userName![0].toUpperCase()
                      : 'U'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // User name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.userName ?? 'news.anonymous'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons (only for own comments)
              if (canEdit) ...[
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text('news.editComment'.tr()),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.red[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'news.deleteComment'.tr(),
                            style: TextStyle(color: Colors.red[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Comment content
          Text(
            comment.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
          
          // Show "edited" indicator if comment was updated
          if (comment.updatedAt != comment.createdAt) ...[
            const SizedBox(height: 8),
            Text(
              'news.edited'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
