import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/layout/app_scaffold.dart';
import 'package:ottobit/models/cart_model.dart';
import 'package:ottobit/services/cart_service.dart';
import 'package:ottobit/routes/app_routes.dart';
import 'package:ottobit/screens/home/home_screen.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartChanged;
  
  const CartScreen({super.key, this.onCartChanged});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  
  List<CartItem> _cartItems = [];
  CartSummary? _cartSummary;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isRemoving = false;
  int? _removingIndex;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    // Refresh cart count in home screen when leaving cart
    HomeScreen.refreshCartCount(context);
    super.dispose();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Load cart items and summary in parallel
      final itemsResponse = await _cartService.getCartItems();
      final summaryResponse = await _cartService.getCartSummary();

      if (mounted) {
        setState(() {
          _cartItems = itemsResponse.data ?? [];
          _cartSummary = summaryResponse.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeItem(int index) async {
    if (index >= _cartItems.length) return;

    final item = _cartItems[index];
    setState(() {
      _isRemoving = true;
      _removingIndex = index;
    });

    try {
      await _cartService.removeFromCart(item.courseId);
      
      if (mounted) {
        setState(() {
          _cartItems.removeAt(index);
          _isRemoving = false;
          _removingIndex = null;
        });
        
        // Reload summary to update totals
        _loadCart();
        
        // Refresh cart count in home screen
        HomeScreen.refreshCartCount(context);
        widget.onCartChanged?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.itemRemoved'.tr()),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRemoving = false;
          _removingIndex = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.removeError'.tr() + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cart.clearCartTitle'.tr()),
        content: Text('cart.clearCartMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('common.confirm'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _cartService.deleteCart();
      
      if (mounted) {
        setState(() {
          _cartItems.clear();
          _cartSummary = null;
        });
        
        // Refresh cart count in home screen
        HomeScreen.refreshCartCount(context);
        widget.onCartChanged?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.cartCleared'.tr()),
            backgroundColor: const Color(0xFF48BB78),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cart.clearError'.tr() + ': $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _proceedToCheckout() {
    if (_cartItems.isEmpty) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.checkout,
      arguments: {
        'cartItems': _cartItems,
        'cartSummary': _cartSummary,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'cart.title'.tr(),
      showAppBar: true,
      gradientColors: const [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4299E1)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'common.error'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCart,
              icon: const Icon(Icons.refresh),
              label: Text('common.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'cart.empty'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'cart.emptyMessage'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore),
              label: Text('cart.browseCourses'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('cart.title'.tr(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${_cartItems.length} ${'items'.tr()} • ${_cartSummary?.formattedTotal ?? ''}',
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _loadCart,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text('common.retry'.tr()),
              )
            ],
          ),
        ),
        // Cart Items (non-scrollable; parent scrolls)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _cartItems.length,
          itemBuilder: (context, index) {
            final item = _cartItems[index];
            final isRemoving = _isRemoving && _removingIndex == index;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.courseImageUrl,
                        width: 88,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 88,
                          height: 56,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.courseTitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(item.courseDescription, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.formattedPrice,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A202C))),
                              isRemoving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : TextButton.icon(
                                      onPressed: () => _removeItem(index),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      label: Text('cart.removeItem'.tr(), style: const TextStyle(color: Colors.red)),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Cart Summary and Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Summary
              if (_cartSummary != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('cart.subtotal'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white70)),
                    Text(_cartSummary!.formattedSubtotal,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                if (_cartSummary!.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('cart.discount'.tr(), style: const TextStyle(fontSize: 16, color: Colors.white70)),
                      Text('-${_cartSummary!.formattedDiscountAmount}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
                const Divider(color: Colors.white12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('cart.total'.tr(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(_cartSummary!.formattedTotal,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cartItems.isEmpty ? null : _clearCart,
                      icon: const Icon(Icons.clear_all),
                      label: Text('cart.clearCart'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        backgroundColor: Colors.white10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _cartItems.isEmpty ? null : _proceedToCheckout,
                      icon: const Icon(Icons.payment),
                      label: Text('cart.checkout'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
