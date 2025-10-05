import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/order_model.dart';
import 'package:ottobit/services/order_service.dart';
import 'package:ottobit/routes/app_routes.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  String _errorMessage = '';
  PagedOrders? _paged;
  int? _status;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final resp = await _orderService.getOrders(
        page: 1,
        size: 10,
        status: _status,
        fromDate: _from,
        toDate: _to,
      );
      if (!mounted) return;
      setState(() {
        _paged = resp;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
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
    final orders = _paged?.items ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(),
        const SizedBox(height: 12),
        if (orders.isEmpty)
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
                Expanded(child: Text('Không có đơn hàng', style: TextStyle(color: Colors.grey[700]))),
              ],
            ),
          )
        else
          ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          itemBuilder: (context, index) {
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
                      Text('${o.items.length} items', style: TextStyle(color: Colors.grey[700])),
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
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Pending')),
                      DropdownMenuItem(value: 1, child: Text('Paid')),
                      DropdownMenuItem(value: 2, child: Text('Failed')),
                      DropdownMenuItem(value: 3, child: Text('Cancelled')),
                      DropdownMenuItem(value: 4, child: Text('Refunded')),
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
                      decoration: const InputDecoration(labelText: 'From'),
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
                      decoration: const InputDecoration(labelText: 'To'),
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
                      _load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
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
      case 1: return 'Paid';
      case 2: return 'Failed';
      case 3: return 'Cancelled';
      case 4: return 'Refunded';
      case 0:
      default:
        return 'Pending';
    }
  }
}


