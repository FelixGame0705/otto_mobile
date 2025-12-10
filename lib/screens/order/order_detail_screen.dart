import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/order_model.dart';
import 'package:ottobit/services/order_service.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/screens/home/home_screen.dart';
import 'package:ottobit/utils/api_error_handler.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  bool _loading = true;
  bool _processing = false;
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
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      setState(() { _error = friendly; _loading = false; });
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('order.cancelConfirm'.tr()),
        content: Text('order.cancelMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('order.cancel'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() { _processing = true; });

    try {
      await _orderService.cancelOrder(_order!.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('order.cancelledMessage'.tr()),
          backgroundColor: const Color(0xFF48BB78),
        ),
      );
      
      // Reload order to get updated status
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() { _processing = false; });
      
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendly),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _continuePayment() async {
    if (_order == null || _order!.paymentTransactions.isEmpty) return;

    setState(() { _processing = true; });

    try {
      final paymentTxId = _order!.paymentTransactions.first.id;
      final returnUrl = 'https://ottobit.vn/payment/success';
      final cancelUrl = 'https://ottobit.vn/payment/cancel';
      
      final payUrl = await _orderService.initiatePayOS(
        paymentTransactionId: paymentTxId,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      );
      
      if (!mounted) return;
      
      await Navigator.of(context).pushNamed(
        AppRoutes.paymentWebview,
        arguments: {
          'paymentUrl': payUrl,
          'returnUrl': returnUrl,
          'cancelUrl': cancelUrl,
          'amount': _order!.total,
          'description': 'Pay order ${_order!.id}',
        },
      );

      // Reload order after payment attempt
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() { _processing = false; });
      
      final isEnglish = context.locale.languageCode == 'en';
      final friendly = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendly),
          backgroundColor: Colors.red,
        ),
      );
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          const SizedBox(height: 16),
          
          // Action buttons based on order status
          if (_canCancel(o.status) || _canContinuePayment(o.status)) ...[
            Row(
              children: [
                if (_canCancel(o.status)) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _cancelOrder,
                      icon: _processing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cancel_outlined),
                      label: Text('order.cancel'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // if (_canContinuePayment(o.status)) ...[
                //   Expanded(
                //     child: ElevatedButton.icon(
                //       onPressed: _processing ? null : _continuePayment,
                //       icon: _processing 
                //         ? const SizedBox(
                //             width: 16,
                //             height: 16,
                //             child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                //           )
                //         : const Icon(Icons.payment),
                //       label: Text('order.continuePayment'.tr()),
                //       style: ElevatedButton.styleFrom(
                //         backgroundColor: const Color(0xFF8B5CF6),
                //         foregroundColor: Colors.white,
                //         padding: const EdgeInsets.symmetric(vertical: 12),
                //       ),
                //     ),
                //   ),
                // ],
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Order items
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
                ).then((_) {
                  // Refresh cart count when returning from course detail
                  HomeScreen.refreshCartCount(context);
                });
              },
            ),
          )),
        ],
      ),
    );
  }

  bool _canCancel(int status) {
    // Can cancel if order is pending (status 0)
    return status == 0 && !_processing;
  }

  bool _canContinuePayment(int status) {
    // Can continue payment if order is pending (status 0) and has payment transactions
    return status == 0 && _order?.paymentTransactions.isNotEmpty == true && !_processing;
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


