import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/order_model.dart';
import 'package:ottobit/services/order_service.dart';
import 'package:ottobit/routes/app_routes.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _loading = true;
  String _error = '';
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final o = await _orderService.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() { _order = o; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error.isNotEmpty) {
      return Center(
        child: Column(children: [
          const SizedBox(height: 24),
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: Text('common.retry'.tr())),
        ]),
      );
    }
    final o = _order!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${o.id.substring(0,8)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(o.createdAt), style: const TextStyle(color: Colors.white70)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(16)),
                child: Text(_statusText(o.status), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...o.items.map((it) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                it.courseImageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            title: Text(it.courseTitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(it.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w700)),
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.courseDetail,
                arguments: {
                  'courseId': it.courseId,
                  'hideEnroll': true,
                },
              );
            },
          ),
        )),
      ],
    );
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


