import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/activation_code_model.dart';
import 'package:ottobit/services/activation_code_service.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:intl/intl.dart';

class MyRobotsScreen extends StatefulWidget {
  const MyRobotsScreen({super.key});

  @override
  State<MyRobotsScreen> createState() => _MyRobotsScreenState();
}

class _MyRobotsScreenState extends State<MyRobotsScreen> {
  final ActivationCodeService _service = ActivationCodeService();
  final ScrollController _scroll = ScrollController();

  List<MyActivationCode> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = '';
      if (refresh) {
        _page = 1;
        _items.clear();
        _hasMore = true;
      }
    });
    try {
      final response = await _service.getMyActivationCodes(
        status: 2, // Only activated robots
        pageNumber: _page,
        pageSize: 10,
      );
      if (mounted) {
        setState(() {
          if (refresh) {
            _items = response.data.items;
          } else {
            _items.addAll(response.data.items);
          }
          _totalPages = response.data.totalPages;
          _hasMore = _page < _totalPages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error.isNotEmpty ? _error : 'profile.robots.loadFailed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _page++;
    await _load();
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.robots.title'.tr()),
        backgroundColor: const Color(0xFF17a64b),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty && _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error.isNotEmpty ? _error : 'profile.robots.loadFailed'.tr(),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _load(refresh: true),
                          icon: const Icon(Icons.refresh),
                          label: Text('common.retry'.tr()),
                        ),
                      ],
                    ),
                  )
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'profile.robots.noRobots'.tr(),
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          if (index == _items.length && _loadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (index < _items.length) {
                            final robot = _items[index];
                            final isExpired = robot.expiresAt.isBefore(DateTime.now());
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: isExpired
                                      ? Colors.grey.shade300
                                      : const Color(0xFF17a64b).withOpacity(0.1),
                                  radius: 28,
                                  child: Icon(
                                    Icons.smart_toy,
                                    color: isExpired ? Colors.grey : const Color(0xFF17a64b),
                                    size: 28,
                                  ),
                                ),
                                title: Text(
                                  robot.robotName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.code,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          robot.code,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'profile.robots.activatedAt'.tr(namedArgs: {'date': _formatDate(robot.usedAt ?? robot.createdAt)}),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (!isExpired) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            size: 14,
                                            color: Colors.green[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'profile.robots.expiresAt'.tr(namedArgs: {'date': _formatDate(robot.expiresAt)}),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            size: 14,
                                            color: Colors.red[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'profile.robots.expired'.tr(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[400],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.productDetail,
                                    arguments: {
                                      'productId': robot.robotId,
                                      'productType': 'robot',
                                    },
                                  );
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _items.length + (_loadingMore ? 1 : 0),
                      ),
      ),
    );
  }
}

