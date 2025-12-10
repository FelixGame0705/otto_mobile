import 'package:flutter/material.dart';
import 'package:ottobit/models/product_model.dart';
import 'package:ottobit/routes/app_routes.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final String productType; // 'robot' or 'component'

  const ProductCard({
    super.key, 
    required this.product, 
    this.onTap,
    this.productType = 'robot',
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.productDetail,
        arguments: {
          'productId': product.id,
          'productType': productType,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final outerGap = _clamp(screenWidth * 0.015, 4, 12);
    final radius = _clamp(screenWidth * 0.03, 8, 14);
    final contentHPad = _clamp(screenWidth * 0.025, 8, 14);
    final contentVPad = _clamp(screenWidth * 0.015, 6, 10);
    final smallGap = _clamp(screenWidth * 0.012, 4, 8);

    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        margin: EdgeInsets.all(outerGap),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image top
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildProductImage(),
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: contentHPad, vertical: contentVPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                  SizedBox(height: smallGap),
                  Text(
                    product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProductImage() {
    final imageUrl = product.imageUrl;
    
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.trim().isEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Icon(Icons.smart_toy_outlined, color: Color(0xFF9CA3AF), size: 36),
        ),
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFFF3F4F6),
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 36),
          ),
        );
      },
    );
  }

  double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
