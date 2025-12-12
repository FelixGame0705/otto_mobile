import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/order_model.dart';
import 'package:ottobit/services/order_service.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  String _errorMessage = '';
  final ScrollController _scroll = ScrollController();
  final List<OrderModel> _orders = [];
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  int? _status;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    final bool isLoadMore = !refresh && _page > 1;
    setState(() {
      _isLoading = !isLoadMore;
      _errorMessage = '';
      if (refresh) {
        _page = 1;
        _orders.clear();
        _hasMore = true;
      }
    });
    try {
      final resp = await _orderService.getOrders(
        page: _page,
        size: 10,
        status: _status,
        fromDate: _from,
        toDate: _to,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _orders
            ..clear()
            ..addAll(resp.items);
        } else {
          _orders.addAll(resp.items);
        }
        _totalPages = resp.totalPages;
        _hasMore = _page < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      setState(() {
        _errorMessage = friendly;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _page++;
    await _load();
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'order.title'.tr(),
      showAppBar: true,
      gradientColors: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: Text('common.retry'.tr())),
          ],
        ),
      );
    }
    final orders = _orders;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (orders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(child: Text('orders.empty'.tr(), style: TextStyle(color: Colors.grey[700]))),
              ],
            ),
          )
        else
          ListView.builder(
          shrinkWrap: true,
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: orders.length + (_loadingMore ? 1 : 0) + (!_hasMore && orders.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == orders.length && _loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (index == orders.length + (_loadingMore ? 1 : 0) && !_hasMore && orders.isNotEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('orders.allShown'.tr(), style: TextStyle(color: Colors.grey[600])),
                ),
              );
            }
            final o = orders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#${o.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(o.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(_statusText(o.status),
                          style: TextStyle(color: _statusColor(o.status), fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('orders.itemsCount'.tr(namedArgs: {'count': '${o.items.length}'}), style: TextStyle(color: Colors.grey[700])),
                      Text(o.formattedTotal, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.orderDetail,
                  arguments: o.id,
                ),
              ),
            );
          },
          ),
      ],
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _status,
                    decoration: InputDecoration(labelText: 'orders.filter.status'.tr()),
                    items: [
                      DropdownMenuItem(value: 0, child: Text('order.status.pending'.tr())),
                      DropdownMenuItem(value: 1, child: Text('order.status.paid'.tr())),
                      DropdownMenuItem(value: 2, child: Text('order.status.failed'.tr())),
                      DropdownMenuItem(value: 3, child: Text('order.status.cancelled'.tr())),
                      DropdownMenuItem(value: 4, child: Text('order.status.refunded'.tr())),
                    ],
                    onChanged: (v) => setState(() => _status = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _from ?? DateTime.now().subtract(const Duration(days: 7)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _from = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'orders.filter.from'.tr()),
                      child: Text(_from != null ? DateFormat('dd/MM/yyyy').format(_from!) : '--/--/----'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _to ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) setState(() => _to = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'orders.filter.to'.tr()),
                      child: Text(_to != null ? DateFormat('dd/MM/yyyy').format(_to!) : '--/--/----'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() { _status = null; _from = null; _to = null; });
                      _load(refresh: true);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('orders.filter.reset'.tr(), style: const TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _load(refresh: true),
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    label: Text('orders.filter.apply'.tr(), style: const TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1: return const Color(0xFF16A34A); // Paid
      case 2: return const Color(0xFFDC2626); // Failed
      case 3: return const Color(0xFF6B7280); // Cancelled
      case 4: return const Color(0xFF0EA5E9); // Refunded
      case 0:
      default:
        return const Color(0xFFF59E0B); // Pending
    }
  }

  String _statusText(int status) {
    switch (status) {
      case 1: return 'order.status.paid'.tr();
      case 2: return 'order.status.failed'.tr();
      case 3: return 'order.status.cancelled'.tr();
      case 4: return 'order.status.refunded'.tr();
      case 0:
      default:
        return 'order.status.pending'.tr();
    }
  }
}


