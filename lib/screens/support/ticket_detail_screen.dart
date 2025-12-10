import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/assistance_ticket_model.dart';
import 'package:ottobit/services/assistance_ticket_service.dart';
import 'dart:async';
import 'package:signalr_core/signalr_core.dart';
import 'package:ottobit/utils/constants.dart';
import 'package:ottobit/services/storage_service.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class TicketDetailScreen extends StatefulWidget {
  final AssistanceTicket ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final AssistanceTicketService _service = AssistanceTicketService();
  List<AssistanceMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  // Pagination state for lazy loading older messages
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  int _ratingScore = 0;
  final TextEditingController _ratingCommentController = TextEditingController();
  bool _submittingRating = false;
  bool _hasExistingRating = false;
  HubConnection? _hub;
  bool _peerTyping = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    _attachScrollListener();
    _loadMessages(initial: true);
    _loadExistingRating();
    _initHub();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _ratingCommentController.dispose();
    _leaveHub();
    super.dispose();
  }

  Future<void> _loadExistingRating() async {
    if (!(widget.ticket.status == 3 || widget.ticket.status == 4)) return;
    try {
      final res = await _service.getRatingByTicketId(widget.ticket.id);
      final rating = res.data;
      if (rating != null && mounted) {
        setState(() {
          _ratingScore = rating.score;
          _ratingCommentController.text = rating.comment ?? '';
          _hasExistingRating = true;
        });
      }
    } catch (_) {
      // ignore: rating may not exist yet
    }
  }

  void _attachScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final atTop = _scrollController.position.pixels <= 64;
      final hasMore = _currentPage < _totalPages;
      if (atTop && hasMore && !_isLoadingMore && !_isLoading) {
        _loadOlderMessages();
      }
    });
  }

  Future<void> _loadMessages({bool initial = false}) async {
    if (initial) setState(() => _isLoading = true);

    try {
      final response = await _service.getTicketMessages(
        ticketId: widget.ticket.id,
        page: 1,
        pageSize: _pageSize,
        orderBy: 'createdAt',
      );

      if (mounted) {
        setState(() {
          final items = response.data?.items ?? [];
          items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _messages = items;
          _totalPages = response.data?.totalPages ?? 1;
          _currentPage = 1;
          _isLoading = false;
        });
        
        // Scroll to bottom after a delay
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients && _messages.isNotEmpty) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ticket.messages.errorLoadingMessages'.tr() + ': $errorMsg')),
        );
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMore) return;
    if (!mounted) return;
    if (_currentPage >= _totalPages) return;

    setState(() => _isLoadingMore = true);

    final beforeMax = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final beforePixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    try {
      final nextPage = _currentPage + 1;
      final response = await _service.getTicketMessages(
        ticketId: widget.ticket.id,
        page: nextPage,
        pageSize: _pageSize,
        orderBy: 'createdAt',
      );

      final older = response.data?.items ?? [];
      older.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      setState(() {
        _messages = [...older, ..._messages];
        _currentPage = nextPage;
        _totalPages = response.data?.totalPages ?? _totalPages;
      });

      // Preserve the user's current viewport position after prepending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        final afterMax = _scrollController.position.maxScrollExtent;
        final delta = afterMax - beforeMax;
        final target = beforePixels + delta;
        _scrollController.jumpTo(target);
      });
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ticket.messages.errorLoadingMessages'.tr() + ': $errorMsg')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final request = CreateMessageRequest(
        ticketId: widget.ticket.id,
        content: _messageController.text.trim(),
      );

      await _service.createMessage(request);

      if (mounted) {
        _messageController.clear();
        _sendTyping(false);
        // Optimistic scroll; messages will arrive via SignalR
        Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ticket.messages.errorSendingMessage'.tr() + ': $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _initHub() async {
    try {
      final token = await StorageService.getToken();
      final hub = HubConnectionBuilder()
          .withUrl(
            AppConstants.assistanceHubUrl,
            HttpConnectionOptions(
              accessTokenFactory: token == null ? null : () async => token,
            ),
          )
          .withAutomaticReconnect()
          .build();

      hub.on('MessageReceived', (args) {
        if (!mounted) return;
        if (args == null || args.isEmpty) return;
        final dynamic payload = args.first;
        if (payload is Map<String, dynamic>) {
          final normalized = _normalizeMessage(payload);
          final msg = AssistanceMessage.fromJson(normalized);
          if (msg.ticketId != widget.ticket.id) return;
          setState(() {
            _messages.add(msg);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });
          _scrollToBottom();
        }
      });

      hub.on('UserTyping', (args) {
        if (!mounted) return;
        final isTyping = args != null && args.isNotEmpty && args.first == true;
        setState(() => _peerTyping = isTyping);
      });

      await hub.start();
      await hub.invoke('JoinTicketGroup', args: [widget.ticket.id]);
      setState(() => _hub = hub);
    } catch (_) {
      // silent fail; fallback to polling via API
    }
  }

  Future<void> _leaveHub() async {
    try {
      if (_hub != null) {
        await _hub!.invoke('LeaveTicketGroup', args: [widget.ticket.id]);
        await _hub!.stop();
      }
    } catch (_) {}
  }

  Map<String, dynamic> _normalizeMessage(Map<String, dynamic> src) {
    String pickS(String a, String b) => (src[a] ?? src[b]) as String;
    bool pickB(String a, String b) => (src[a] ?? src[b]) as bool? ?? false;
    dynamic pick(String a, String b) => src[a] ?? src[b];
    return {
      'id': pickS('id', 'Id'),
      'ticketId': pickS('ticketId', 'TicketId'),
      'studentId': pickS('studentId', 'StudentId'),
      'content': pickS('content', 'Content'),
      'isFromStudent': pickB('isFromStudent', 'IsFromStudent'),
      'createdAt': pick('createdAt', 'CreatedAt')?.toString(),
      'updatedAt': pick('updatedAt', 'UpdatedAt')?.toString(),
      'studentName': (pick('studentName', 'StudentName') ?? '').toString(),
      'studentEmail': (pick('studentEmail', 'StudentEmail') ?? '').toString(),
    };
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _onInputChanged(String _) {
    _sendTyping(true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 1), () => _sendTyping(false));
  }

  Future<void> _sendTyping(bool isTyping) async {
    try {
      if (_hub?.state == HubConnectionState.connected) {
        await _hub!.invoke('Typing', args: [widget.ticket.id, isTyping]);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('ticket.ticketDetails'.tr()),
        backgroundColor: const Color(0xFF17a64b),
      ),
      body: Column(
        children: [
          // Ticket info header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.ticket.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(widget.ticket.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(widget.ticket.status),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _getStatusText(widget.ticket.status),
                        style: TextStyle(
                          color: _getStatusColor(widget.ticket.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.ticket.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.ticket.courseName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rating section (shown when ticket resolved or closed)
          if (widget.ticket.status == 3 || widget.ticket.status == 4)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ticket.rating.title'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ticket.rating.subtitle'.tr(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isFilled = _ratingScore >= starIndex;
                      return IconButton(
                        icon: Icon(
                          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFFFB020),
                          size: 28,
                        ),
                        onPressed: _hasExistingRating
                            ? null
                            : () {
                          setState(() {
                            _ratingScore = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ratingCommentController,
                    decoration: InputDecoration(
                      hintText: 'ticket.rating.commentHint'.tr(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_hasExistingRating,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submittingRating || _hasExistingRating ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF17a64b),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _submittingRating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_hasExistingRating ? 'ticket.rating.submitted'.tr() : 'ticket.rating.submit'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          
          // Comments/Messages section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ticket.messages.noMessages'.tr(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ticket.messages.startConversation'.tr(),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildComment(message);
                        },
                      ),
          ),

          // Message input - Only allow messaging when status is 2 (inProgress)
          if (widget.ticket.status == 2)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'ticket.messages.writeMessage'.tr(),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: _onInputChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF17a64b),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_peerTyping)
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ticket.messages.typing'.tr(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComment(AssistanceMessage message) {
    final isMe = message.isFromStudent;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.support_agent, size: 14, color: Colors.white),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF17a64b) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isMe ? 12 : 2),
                      bottomRight: Radius.circular(isMe ? 2 : 12),
                    ),
                    border: isMe ? null : Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : const Color(0xFF2D3748),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(message.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF17a64b),
              child: const Icon(Icons.person, size: 14, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return 'ticket.status.open'.tr();
      case 2:
        return 'ticket.status.inProgress'.tr();
      case 3:
        return 'ticket.status.resolved'.tr();
      case 4:
        return 'ticket.status.closed'.tr();
      default:
        return 'ticket.status.open'.tr();
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        if (minutes < 1) return 'ticket.messages.justNow'.tr();
        return 'ticket.messages.minutesAgo'.tr(namedArgs: {'n': '${minutes}'});
      }
      return 'ticket.messages.hoursAgo'.tr(namedArgs: {'n': '${difference.inHours}'});
    } else if (difference.inDays == 1) {
      return 'ticket.messages.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'ticket.messages.daysAgo'.tr(namedArgs: {'n': '${difference.inDays}'});
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _submitRating() async {
    if (_ratingScore <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ticket.rating.selectStars'.tr())),
      );
      return;
    }

    setState(() {
      _submittingRating = true;
    });

    try {
      final req = CreateAssistanceRatingRequest(
        ticketId: widget.ticket.id,
        score: _ratingScore,
        comment: _ratingCommentController.text.trim().isEmpty
            ? null
            : _ratingCommentController.text.trim(),
      );
      await _service.createRating(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ticket.rating.success'.tr())),
      );
      setState(() {
        // Optionally lock the form after submit
      });
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ticket.rating.error'.tr(args: [errorMsg]))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submittingRating = false;
        });
      }
    }
  }
}

