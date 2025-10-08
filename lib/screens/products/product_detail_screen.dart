import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/product_model.dart';
import 'package:ottobit/models/robot_image_model.dart';
import 'package:ottobit/models/component_model.dart';
import 'package:ottobit/services/product_service.dart';
import 'package:ottobit/services/image_service.dart';
import 'package:ottobit/services/component_service.dart';
import 'package:ottobit/services/course_robot_service.dart';
import 'package:ottobit/models/course_robot_model.dart';
import 'package:ottobit/widgets/ui/notifications.dart';
import 'package:ottobit/widgets/products/product_image_gallery.dart';
import 'package:ottobit/widgets/products/product_info_section.dart';
import 'package:ottobit/widgets/products/technical_specs_section.dart';
import 'package:ottobit/widgets/products/requirements_section.dart';
import 'package:ottobit/widgets/products/age_range_section.dart';
import 'package:ottobit/widgets/products/brand_info_section.dart';
import 'package:ottobit/widgets/products/related_components_section.dart';
import 'package:ottobit/widgets/products/related_courses_section.dart';
import 'package:ottobit/widgets/products/component_card.dart';

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
  final CourseRobotService _courseRobotService = CourseRobotService();
  Product? _product;
  List<RobotImageItem> _images = [];
  List<Component> _components = [];
  List<CourseRobot> _relatedCourses = [];
  bool _isLoading = true;
  bool _isLoadingImages = false;
  bool _isLoadingComponents = false;
  bool _isLoadingCourses = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
    _loadComponents();
    _loadImages();
    _loadRelatedCourses();
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

  Future<void> _loadRelatedCourses() async {
    if (widget.productType != 'robot') return;
    
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final response = await _courseRobotService.getCourseRobots();
      if (mounted) {
        // Filter courses that use this robot
        final relatedCourses = response.data?.items
            .where((courseRobot) => courseRobot.robotId == widget.productId)
            .toList() ?? [];
        
        setState(() {
          _relatedCourses = relatedCourses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
        print('Failed to load related courses: $e');
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
          // Product Image Gallery
          ProductImageGallery(
            productImageUrl: _product!.imageUrl,
            images: _images,
            isLoadingImages: _isLoadingImages,
          ),
          const SizedBox(height: 24),
          
          // Product Info
          ProductInfoSection(product: _product!),
          const SizedBox(height: 24),
          
          // Technical Specs
          TechnicalSpecsSection(product: _product!),
          const SizedBox(height: 24),
          
          // Requirements
          RequirementsSection(product: _product!),
          const SizedBox(height: 24),
          
          // Age Range
          AgeRangeSection(product: _product!),
          const SizedBox(height: 24),
          
          // Brand Info
          BrandInfoSection(product: _product!),
          const SizedBox(height: 24),
          
          // Related Components
          RelatedComponentsSection(
            components: _components,
            isLoadingComponents: _isLoadingComponents,
            onComponentTap: _showComponentDetail,
          ),
          const SizedBox(height: 24),
          
          // Related Courses (only for robots)
          if (widget.productType == 'robot') ...[
            RelatedCoursesSection(
              relatedCourses: _relatedCourses,
              isLoadingCourses: _isLoadingCourses,
              onCourseTap: _navigateToCourse,
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }


  void _showComponentDetail(Component component) {
    showDialog(
      context: context,
      builder: (context) => ComponentDetailDialog(component: component),
    );
  }

  void _navigateToCourse(String courseId) {
    Navigator.pushNamed(
      context,
      '/course-detail',
      arguments: courseId,
    );
  }



}

