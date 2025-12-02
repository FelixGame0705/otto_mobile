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
  final _formKey = GlobalKey<FormState>();
  
  bool _isProcessing = false;
  String _paymentMethod = 'bank_transfer';
  String _discountCode = '';
  bool _hasDiscount = false;
  int _discountAmount = 0;
  CartSummary? _currentCartSummary;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCartSummary();
  }

  void _loadUserInfo() {
    // In a real app, you would load this from user profile
    _fullNameController.text = 'Test User';
    _emailController.text = 'user@ottobit.com';
    _phoneController.text = '0123456789';
    _addressController.text = '123 Main Street, Ho Chi Minh City';
  }

  Future<void> _loadCartSummary() async {
    try {
      final summary = await _cartService.getCartSummary();
      if (mounted) {
        setState(() {
          _currentCartSummary = summary.data;
          _discountAmount = summary.data?.discountAmount ?? 0;
          _hasDiscount = _discountAmount > 0;
        });
      }
    } catch (e) {
      print('Failed to load cart summary: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _applyDiscount() async {
    if (_discountController.text.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _cartService.applyDiscount(_discountController.text);
      
      if (mounted) {
        setState(() {
          _hasDiscount = true;
          _discountCode = _discountController.text;
          _discountAmount = response.data?.discountAmount ?? 0;
          _isProcessing = false;
        });
        
        // Refresh cart summary to get updated pricing
        await _loadCartSummary();
        
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
        setState(() {
          _hasDiscount = false;
          _discountCode = '';
          _discountAmount = 0;
          _discountController.clear();
          _isProcessing = false;
        });
        
        // Refresh cart summary to get updated pricing
        await _loadCartSummary();
        
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
    if (!_formKey.currentState!.validate()) return;

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
              ScaffoldMessenger.of(context).showSnackBar(
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('order.success'.tr()),
              backgroundColor: const Color(0xFF48BB78),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        final isEnglish = context.locale.languageCode == 'en';
        
        // Check for VOU_012 error and show dialog
        final errorStr = e.toString();
        if (errorStr.contains('VOU_012') || errorStr.contains('Voucher đã đạt giới hạn')) {
          // Try to extract error code from JSON if available
          try {
            final cleanedError = errorStr.replaceFirst(RegExp(r'Exception:\s*', caseSensitive: false), '').trim();
            final errorJson = jsonDecode(cleanedError);
            if (errorJson['errorCode'] == 'VOU_012') {
              final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
              _showVoucherErrorDialog(friendlyMsg);
              return;
            }
          } catch (_) {
            // If parsing fails, check string directly
            if (errorStr.contains('VOU_012')) {
              final friendlyMsg = ApiErrorMapper.fromException(e, isEnglish: isEnglish);
              _showVoucherErrorDialog(friendlyMsg);
              return;
            }
          }
        }
        
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

  int get _subtotal => _currentCartSummary?.subtotal ?? widget.cartItems.fold(0, (sum, item) => sum + item.unitPrice);
  int get _total => _currentCartSummary?.total ?? (_subtotal - _discountAmount);

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
      child: Form(
        key: _formKey,
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
                      if (_hasDiscount) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('order.discount'.tr() + ' ($_discountCode)'),
                            Text(
                              '-${_formatPrice(_discountAmount)}',
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
                                enabled: !_hasDiscount,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!_hasDiscount)
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
              
              // Customer Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'order.customerInfo'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'order.fullName'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'order.fullNameRequired'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'order.email'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'order.emailRequired'.tr();
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'order.emailInvalid'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'order.phone'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'order.phoneRequired'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'order.address'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'order.addressRequired'.tr();
                          }
                          return null;
                        },
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
                      RadioListTile<String>(
                        title: Text('order.cod'.tr()),
                        subtitle: Text('order.codDesc'.tr()),
                        value: 'cod',
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
      ),
    );
  }
}
