import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CommentInputWidget extends StatefulWidget {
  final String hintText;
  final String? initialValue;
  final Function(String) onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const CommentInputWidget({
    super.key,
    required this.hintText,
    this.initialValue,
    required this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _isExpanded = true;
      _hasText = widget.initialValue!.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSubmit(text);
      if (widget.initialValue == null) {
        // Only clear if it's a new comment, not editing
        _controller.clear();
        setState(() {
          _isExpanded = false;
        });
        _focusNode.unfocus();
      }
    }
  }

  void _handleCancel() {
    if (widget.initialValue != null) {
      // If editing, restore original value
      _controller.text = widget.initialValue!;
      setState(() {
        _hasText = widget.initialValue!.trim().isNotEmpty;
      });
    } else {
      // If new comment, clear and collapse
      _controller.clear();
      setState(() {
        _isExpanded = false;
        _hasText = false;
      });
    }
    _focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded ? const Color(0xFF17a64b) : Colors.grey[300]!,
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
        children: [
          // Text input
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: _isExpanded ? 4 : 1,
            onTap: () {
              if (!_isExpanded) {
                setState(() {
                  _isExpanded = true;
                });
              }
            },
            onChanged: (value) {
              setState(() {
                _hasText = value.trim().isNotEmpty;
                if (value.isNotEmpty && !_isExpanded) {
                  _isExpanded = true;
                }
              });
            },
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 8,
              ),
            ),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          
          // Action buttons (only show when expanded)
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                TextButton(
                  onPressed: widget.isLoading ? null : _handleCancel,
                  child: Text(
                    'common.cancel'.tr(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Submit button
                ElevatedButton(
                  onPressed: widget.isLoading 
                      ? null 
                      : (_hasText ? _handleSubmit : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17a64b),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.initialValue != null 
                              ? 'news.updateComment'.tr()
                              : 'news.postComment'.tr(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
