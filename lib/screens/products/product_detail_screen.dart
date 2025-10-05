import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/product_model.dart';
import 'package:ottobit/models/robot_image_model.dart';
import 'package:ottobit/models/component_model.dart';
import 'package:ottobit/services/product_service.dart';
import 'package:ottobit/services/image_service.dart';
import 'package:ottobit/services/component_service.dart';
import 'package:ottobit/widgets/ui/notifications.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productType;

  const ProductDetailScreen({
    super.key, 
    required this.productId,
    this.productType = 'robot',
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final ImageService _imageService = ImageService();
  final ComponentService _componentService = ComponentService();
  Product? _product;
  List<RobotImageItem> _images = [];
  List<Component> _components = [];
  bool _isLoading = true;
  bool _isLoadingImages = false;
  bool _isLoadingComponents = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
    _loadComponents();
    _loadImages();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _productService.getProductDetail(
        widget.productId, 
        productType: widget.productType,
      );
      if (mounted) {
        setState(() {
          _product = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
        showErrorToast(context, _errorMessage);
      }
    }
  }

  Future<void> _loadImages() async {
    setState(() { _isLoadingImages = true; });
    try {
      final productId = widget.productId;
      final res = await _imageService.getRobotImages(robotId: productId);
      if (!mounted) return;
      setState(() {
        _images = res.items;
        _isLoadingImages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingImages = false; });
    }
  }

  Future<void> _loadComponents() async {
    setState(() {
      _isLoadingComponents = true;
    });

    try {
      final response = await _componentService.getComponents(
        page: 1,
        size: 10,
        searchTerm: _product?.name, // Search for components related to this product
        inStock: true,
        orderBy: 'Name',
        orderDirection: 'ASC',
      );
      
      if (mounted) {
        setState(() {
          _components = response.data?.items ?? [];
          _isLoadingComponents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingComponents = false;
        });
        print('Failed to load components: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('product.detail'.tr()),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadProductDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'common.error'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProductDetail,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_product == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy_outlined, color: Colors.grey, size: 64),
            const SizedBox(height: 16),
            Text(
              'product.notFound'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          _buildProductImage(),
          const SizedBox(height: 12),
          _buildImageGallery(),
          const SizedBox(height: 24),
          
          // Product Info
          _buildProductInfo(),
          const SizedBox(height: 24),
          
          // Technical Specs
          _buildTechnicalSpecs(),
          const SizedBox(height: 24),
          
          // Requirements
          _buildRequirements(),
          const SizedBox(height: 24),
          
          // Age Range
          _buildAgeRange(),
          const SizedBox(height: 24),
          
          // Stock Info
          _buildStockInfo(),
          const SizedBox(height: 24),
          
          // Related Components
          _buildRelatedComponents(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    final List<String> gallery = [];
    if (_product?.imageUrl != null && _product!.imageUrl!.isNotEmpty) {
      gallery.add(_product!.imageUrl!);
    }
    if (_images.isNotEmpty) {
      gallery.addAll(_images.map((e) => e.url));
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
    if (_isLoadingImages) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final img = _images[index];
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

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _product!.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _product!.model,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _formatCurrency(_product!.price),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _product!.description,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF374151),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalSpecs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.technicalSpecs'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            _product!.technicalSpecs,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.requirements'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            _product!.requirements,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRange() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'product.minAge'.tr(),
            '${_product!.minAge}',
            Icons.child_care,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'product.maxAge'.tr(),
            '${_product!.maxAge}',
            Icons.elderly,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'product.stock'.tr(),
            '${_product!.stockQuantity}',
            Icons.inventory,
            const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'product.brand'.tr(),
            _product!.brand,
            Icons.business,
            const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedComponents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'product.relatedComponents'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingComponents)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_components.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 48),
                const SizedBox(height: 12),
                Text(
                  'product.noComponents'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _components.length,
              itemBuilder: (context, index) {
                final component = _components[index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildComponentCard(component),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildComponentCard(Component component) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () {
          // Navigate to component detail or show component info
          _showComponentDetail(component);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Component Image
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFF3F4F6),
                ),
                child: component.imageUrl != null && component.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          component.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                      ),
              ),
              const SizedBox(height: 8),
              // Component Name
              Text(
                component.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Component Price
              Text(
                _formatCurrency(component.price),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 4),
              // Stock
              Text(
                'product.stockQuantity'.tr(namedArgs: {'quantity': component.stockQuantity.toString()}),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComponentDetail(Component component) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(component.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (component.imageUrl != null && component.imageUrl!.isNotEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: const Color(0xFFF3F4F6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      component.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.extension, color: Color(0xFF9CA3AF), size: 32),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                component.description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              Text(
                '${'product.price'.tr()}: ${_formatCurrency(component.price)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 8),
              Text(
                '${'product.stock'.tr()}: ${component.stockQuantity}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              if (component.specifications.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${'product.specifications'.tr()}:',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  component.specifications,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.close'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Add to cart or selection logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${'product.addedToCart'.tr()}: ${component.name}'),
                  backgroundColor: const Color(0xFF48BB78),
                ),
              );
            },
            child: Text('product.addToCart'.tr()),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      buffer.write(s[i]);
      if (idx > 1 && idx % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()} đ';
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
