import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/cart_model.dart';
import 'package:ottobit/services/cart_service.dart';
import 'package:ottobit/services/order_service.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/screens/home/home_screen.dart';
import 'package:ottobit/utils/api_error_handler.dart';
import 'dart:convert';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final CartSummary? cartSummary;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    this.cartSummary,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  
  bool _isProcessing = false;
  String _paymentMethod = 'bank_transfer';
  String _discountCode = '';
  bool _hasVoucherDiscount = false;
  CartSummary? _currentCartSummary;

  final TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCartSummary();
  }

  Future<void> _loadCartSummary() async {
    try {
      final summary = await _cartService.getCartSummary();
      if (mounted) {
        setState(() {
          _currentCartSummary = summary.data;
          // Check if voucher discount exists (has voucher code)
          _hasVoucherDiscount = summary.data?.voucherCode != null && 
                                summary.data!.voucherCode!.isNotEmpty &&
                                (summary.data?.voucherDiscountAmount ?? 0) > 0;
          _discountCode = summary.data?.voucherCode ?? '';
          if (_hasVoucherDiscount && _discountCode.isNotEmpty) {
            _discountController.text = _discountCode;
          }
        });
      }
    } catch (e) {
      print('Failed to load cart summary: $e');
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount() async {
    if (_discountController.text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _cartService.applyDiscount(_discountController.text);
      
      if (mounted) {
        // Refresh cart summary to get updated pricing
        await _loadCartSummary();
        
        setState(() {
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.discountApplied'.tr()),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeDiscount() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await _cartService.removeDiscount();
      
      if (mounted) {
        // Refresh cart summary to get updated pricing
        await _loadCartSummary();
        
        setState(() {
          _discountController.clear();
          _isProcessing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.discountRemoved'.tr()),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processOrder() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Validate cart before processing
      await _cartService.validateCart();
      // Create order from cart
      final summary = widget.cartSummary;
      String? cartId;
      if (summary != null) {
        cartId = summary.cartId;
      } else {
        // Fallback: fetch summary to get cartId
        final s = await _cartService.getCartSummary();
        cartId = s.data?.cartId;
      }
      if (cartId == null || cartId.isEmpty) {
        throw Exception('Cart is empty or missing');
      }

      final order = await _orderService.createOrder(cartId: cartId);

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Try initiating PayOS payment
        final paymentTxId = (order.paymentTransactions.isNotEmpty) ? order.paymentTransactions.first.id : '';
        if (paymentTxId.isNotEmpty) {
          final returnUrl = 'https://ottobit.vn/payment/success';
          final cancelUrl = 'https://ottobit.vn/payment/cancel';
          final payUrl = await _orderService.initiatePayOS(
            paymentTransactionId: paymentTxId,
            returnUrl: returnUrl,
            cancelUrl: cancelUrl,
          );
          if (!mounted) return;
          final result = await Navigator.of(context).pushNamed(
            AppRoutes.paymentWebview,
            arguments: {
              'paymentUrl': payUrl,
              'returnUrl': returnUrl,
              'cancelUrl': cancelUrl,
              'amount': order.total,
              'description': 'Pay order ${order.id}',
            },
          );

          // Handle return/cancel from webview
          if (mounted) {
            // Always refresh cart count
            HomeScreen.refreshCartCount(context);
            // Navigate to orders list regardless of result
            Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
            
            // Only show success message if payment was successful
            if (result != null && result is Map && result['result'] == 'success') {
              final messenger = ScaffoldMessenger.maybeOf(context);
              messenger?.showSnackBar(
                SnackBar(
                  content: Text('order.success'.tr()),
                  backgroundColor: const Color(0xFF48BB78),
                ),
              );
            }
            // If cancelled or other result, don't show success message
          }
        } else {
          // Fallback: no payment needed
          HomeScreen.refreshCartCount(context);
          Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            SnackBar(
              content: Text('order.success'.tr()),
              backgroundColor: const Color(0xFF48BB78),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
        setState(() {
          _isProcessing = false;
        });
        
        final isEnglish = context.locale.languageCode == 'en';
      bool handled = false;
        
        // Check for VOU_012 error and show dialog
        final errorStr = e.toString();
        if (errorStr.contains('VOU_012') || errorStr.contains('Voucher đã đạt giới hạn')) {
          // Try to extract error code from JSON if available
          try {
            final cleanedError = errorStr.replaceFirst(RegExp(r'Exception:\s*', caseSensitive: false), '').trim();
            final errorJson = jsonDecode(cleanedError);
            if (errorJson['errorCode'] == 'VOU_012') {
              final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
            if (mounted) {
              _showVoucherErrorDialog(friendlyMsg);
            }
            handled = true;
            }
          } catch (_) {
            // If parsing fails, check string directly
            if (errorStr.contains('VOU_012')) {
              final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
            if (mounted) {
              _showVoucherErrorDialog(friendlyMsg);
            }
            handled = true;
          }
        }
      }
      
      // Check for CART_009 error or cart items updated error
      if (!handled) {
        final lowerErrorStr = errorStr.toLowerCase();
        if (errorStr.contains('CART_009') || 
            errorStr.contains('Cart items have been updated') ||
            errorStr.contains('please recalculate cart before checkout') ||
            lowerErrorStr.contains('giỏ hàng đã được cập nhật') ||
            lowerErrorStr.contains('vui lòng tính toán lại giỏ hàng')) {
          // Try to extract error code from JSON if available
          try {
            final cleanedError = errorStr.replaceFirst(RegExp(r'Exception:\s*', caseSensitive: false), '').trim();
            final errorJson = jsonDecode(cleanedError);
            if (errorJson['errorCode'] == 'CART_009') {
              final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
              if (mounted) {
                _showPriceChangedDialog(friendlyMsg);
            }
              handled = true;
          }
          } catch (_) {
            // If parsing fails, check string directly or translated message
            if (errorStr.contains('CART_009') || 
                errorStr.contains('Cart items have been updated') ||
                errorStr.contains('please recalculate cart before checkout') ||
                lowerErrorStr.contains('giỏ hàng đã được cập nhật') ||
                lowerErrorStr.contains('vui lòng tính toán lại giỏ hàng')) {
              final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
              if (mounted) {
                _showPriceChangedDialog(friendlyMsg);
              }
              handled = true;
            }
          }
        }
      }
      
      // Legacy: Check for price changed error (backward compatibility)
      if (!handled) {
        final lowerErrorStr = errorStr.toLowerCase();
        if (lowerErrorStr.contains('price has changed for course') || 
            lowerErrorStr.contains('giá khóa học đã thay đổi')) {
          final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
          if (mounted) {
            _showPriceChangedDialog(friendlyMsg);
          }
          handled = true;
        }
      }
      
      // Only show SnackBar if error was not handled by dialog
      if (!handled && mounted) {
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
        }
      }
    }
  }

  void _showVoucherErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text('order.voucherInvalid'.tr())),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showPriceChangedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text('order.priceChanged'.tr())),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to cart screen to see updated prices
              Navigator.of(context).pop();
            },
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _recalculateAndReload();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
            child: Text('order.updateCart'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _recalculateAndReload() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Recalculate cart
      await _cartService.recalculateCart();
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Navigate back to cart screen to show updated prices
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('order.cartUpdated'.tr()),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        final isEnglish = context.locale.languageCode == 'en';
        final errorMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int get _subtotal => _currentCartSummary?.subtotal ?? 
    widget.cartItems.fold(0, (sum, item) => sum + item.finalPrice);

  int get _courseDiscountTotal => _currentCartSummary?.courseDiscountTotal ?? 0;
  
  int get _voucherDiscountAmount => _currentCartSummary?.voucherDiscountAmount ?? 0;

  int get _total => _currentCartSummary?.total ?? 
    (_subtotal - _courseDiscountTotal - _voucherDiscountAmount);

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    ) + ' VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'order.title'.tr(),
      showAppBar: true,
      gradientColors: const [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('order.title'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('${widget.cartItems.length} ${'items'.tr()}', style: TextStyle(color: Colors.grey[700])),
                    ],
                  )
                ],
              ),
            ),
            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'order.summary'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...widget.cartItems.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              item.courseImageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.courseTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  item.formattedPrice,
                                  style: const TextStyle(color: Color(0xFF1A202C), fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('order.subtotal'.tr()),
                        Text(_formatPrice(_subtotal)),
                      ],
                    ),
                    if (_courseDiscountTotal > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('cart.courseDiscount'.tr()),
                          Text(
                            '-${_formatPrice(_courseDiscountTotal)}',
                            style: const TextStyle(color: Color(0xFF48BB78)),
                          ),
                        ],
                      ),
                    ],
                    if (_hasVoucherDiscount && _voucherDiscountAmount > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentCartSummary?.voucherCode != null && _currentCartSummary!.voucherCode!.isNotEmpty
                                ? 'cart.voucherDiscountWithCode'.tr(args: [_currentCartSummary!.voucherCode!])
                                : 'cart.voucherDiscount'.tr(),
                          ),
                          Text(
                            '-${_formatPrice(_voucherDiscountAmount)}',
                            style: const TextStyle(color: Color(0xFF48BB78)),
                          ),
                        ],
                      ),
                    ],
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'order.total'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatPrice(_total),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Discount Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'order.discountCode'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            decoration: InputDecoration(
                              hintText: 'order.enterDiscountCode'.tr(),
                              border: const OutlineInputBorder(),
                              enabled: !_hasVoucherDiscount,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (!_hasVoucherDiscount)
                          ElevatedButton(
                            onPressed: _isProcessing ? null : _applyDiscount,
                            child: _isProcessing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text('order.apply'.tr()),
                          )
                        else
                          OutlinedButton(
                            onPressed: _isProcessing ? null : _removeDiscount,
                            child: Text('order.remove'.tr()),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Payment Method
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'order.paymentMethod'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<String>(
                      title: Text('order.bankTransfer'.tr()),
                      subtitle: Text('order.bankTransferDesc'.tr()),
                      value: 'bank_transfer',
                      groupValue: _paymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Place Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processOrder,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessing ? 'order.processing'.tr() : 'order.placeOrder'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
