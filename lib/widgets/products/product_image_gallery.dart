import 'package:flutter/material.dart';
import 'package:ottobit/models/robot_image_model.dart';

class ProductImageGallery extends StatefulWidget {
  final String? productImageUrl;
  final List<RobotImageItem> images;
  final bool isLoadingImages;

  const ProductImageGallery({
    super.key,
    this.productImageUrl,
    required this.images,
    required this.isLoadingImages,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProductImage(),
        const SizedBox(height: 12),
        _buildImageGallery(),
      ],
    );
  }

  Widget _buildProductImage() {
    final List<String> gallery = [];
    final productImageUrl = widget.productImageUrl;
    
    if (productImageUrl != null && productImageUrl.isNotEmpty && productImageUrl.trim().isNotEmpty) {
      gallery.add(productImageUrl);
    }
    if (widget.images.isNotEmpty) {
      gallery.addAll(widget.images.map((e) => e.url).where((url) => url.isNotEmpty));
    }

    if (gallery.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFF3F4F6),
        ),
        child: const Center(
          child: Icon(Icons.smart_toy_outlined, color: Color(0xFF9CA3AF), size: 64),
        ),
      );
    }

    return _ImagePager(urls: gallery);
  }

  Widget _buildImageGallery() {
    if (widget.isLoadingImages) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final img = widget.images[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              img.url,
              height: 90,
              width: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 90,
                width: 120,
                color: const Color(0xFFF3F4F6),
                child: const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImagePager extends StatefulWidget {
  final List<String> urls;
  const _ImagePager({required this.urls});

  @override
  State<_ImagePager> createState() => _ImagePagerState();
}

class _ImagePagerState extends State<_ImagePager> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = widget.urls[i];
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF), size: 64),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.urls.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.urls.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 10 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF111827) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
      ],
    );
  }
}
