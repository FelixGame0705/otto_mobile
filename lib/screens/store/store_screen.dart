import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/robot_model.dart';
import 'package:ottobit/models/product_model.dart';
import 'package:ottobit/models/component_model.dart';
import 'package:ottobit/services/robot_service.dart';
import 'package:ottobit/services/component_service.dart';
import 'package:ottobit/widgets/products/product_card.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  final RobotService _robotService = RobotService();
  final ComponentService _componentService = ComponentService();
  RobotPageData? _robotPage;
  ComponentListResponse? _componentPage;
  bool _loading = true;
  String? _error;
  int _selectedTabIndex = 0; // 0 = robots, 1 = components
  TabController? _tabController;

  // Filters
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _minPriceCtrl = TextEditingController();
  final TextEditingController _maxPriceCtrl = TextEditingController();
  final TextEditingController _minAgeCtrl = TextEditingController();
  final TextEditingController _maxAgeCtrl = TextEditingController();
  bool _inStock = false;
  String _orderBy = 'Name';
  String _orderDirection = 'ASC';
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController!.index;
        });
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_selectedTabIndex == 0) {
        // Load robots
        final res = await _robotService.getRobots(
          page: 1,
          size: 10,
          searchTerm: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
          minPrice: int.tryParse(_minPriceCtrl.text.trim()),
          maxPrice: int.tryParse(_maxPriceCtrl.text.trim()),
          minAge: int.tryParse(_minAgeCtrl.text.trim()),
          maxAge: int.tryParse(_maxAgeCtrl.text.trim()),
          inStock: _inStock,
          orderBy: _orderBy,
          orderDirection: _orderDirection,
        );
        setState(() {
          _robotPage = res.data;
          _loading = false;
        });
      } else {
        // Load components
        final res = await _componentService.getComponents(
          page: 1,
          size: 10,
          searchTerm: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          minPrice: int.tryParse(_minPriceCtrl.text.trim()),
          maxPrice: int.tryParse(_maxPriceCtrl.text.trim()),
          inStock: _inStock,
          orderBy: _orderBy,
          orderDirection: _orderDirection,
        );
        setState(() {
          _componentPage = res.data;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = _buildFilterBar();

    if (_tabController == null) {
      return Column(
        children: [
          filter,
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        filter,
        // Tab Bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController!,
            labelColor: const Color(0xFF00ba4a),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF00ba4a),
            tabs: [
              Tab(
                icon: const Icon(Icons.smart_toy_outlined),
                text: 'store.robots'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.extension),
                text: 'store.components'.tr(),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [
              _buildRobotsTab(),
              _buildComponentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRobotsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    final items = _robotPage?.items ?? [];
    if (items.isEmpty) {
      return Center(child: Text('resource.empty'.tr()));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final robot = items[index];
          final product = _convertRobotToProduct(robot);
          return ProductCard(
            product: product,
            productType: 'robot',
          );
        },
      ),
    );
  }

  Widget _buildComponentsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    final items = _componentPage?.items ?? [];
    if (items.isEmpty) {
      return Center(child: Text('resource.empty'.tr()));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final component = items[index];
          final product = _convertComponentToProduct(component);
          return ProductCard(
            product: product,
            productType: 'component',
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Material(
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          children: [
            // Header row with collapse/expand
            Row(
              children: [
                const Icon(Icons.tune, size: 18),
                const SizedBox(width: 6),
                Text('store.filters'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  icon: Icon(_showFilters ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showFilters ? 'store.collapse'.tr() : 'store.expand'.tr()),
                ),
              ],
            ),
            if (_showFilters) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'store.search'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _brandCtrl,
                    decoration: InputDecoration(
                      hintText: 'store.brand'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.sell_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'store.priceMin'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'store.priceMax'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.attach_money),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAgeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'store.ageMin'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.child_care_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxAgeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'store.ageMax'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.child_care_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _orderBy,
                    items: [
                      DropdownMenuItem(value: 'Name', child: Text('store.sort.name'.tr())),
                      DropdownMenuItem(value: 'Price', child: Text('store.sort.price'.tr())),
                      DropdownMenuItem(value: 'CreatedAt', child: Text('store.sort.created'.tr())),
                    ],
                    onChanged: (v) => setState(() => _orderBy = v ?? 'Name'),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _orderDirection,
                    items: [
                      DropdownMenuItem(value: 'ASC', child: Text('store.asc'.tr())),
                      DropdownMenuItem(value: 'DESC', child: Text('store.desc'.tr())),
                    ],
                    onChanged: (v) => setState(() => _orderDirection = v ?? 'ASC'),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Switch(
                        value: _inStock,
                        onChanged: (v) => setState(() => _inStock = v),
                      ),
                      Text('store.inStock'.tr()),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.filter_list),
                  label: Text('store.apply'.tr()),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _brandCtrl.clear();
                    _minPriceCtrl.clear();
                    _maxPriceCtrl.clear();
                    _minAgeCtrl.clear();
                    _maxAgeCtrl.clear();
                    setState(() {
                      _inStock = false;
                      _orderBy = 'Name';
                      _orderDirection = 'ASC';
                    });
                    _load();
                  },
                  child: Text('store.reset'.tr()),
                )
              ],
            )
            ]
          ],
        ),
      ),
    );
  }

  Product _convertRobotToProduct(RobotItem robot) {
    return Product(
      id: robot.id,
      name: robot.name,
      model: robot.model,
      brand: robot.brand,
      description: robot.description ?? '',
      imageUrl: robot.imageUrl,
      price: robot.price,
      stockQuantity: robot.stockQuantity,
      technicalSpecs: robot.technicalSpecs ?? '',
      requirements: robot.requirements ?? '',
      minAge: robot.minAge,
      maxAge: robot.maxAge,
      createdAt: robot.createdAt,
      updatedAt: robot.updatedAt,
      isDeleted: robot.isDeleted,
      imagesCount: robot.imagesCount,
      courseRobotsCount: robot.courseRobotsCount,
      studentRobotsCount: robot.studentRobotsCount,
    );
  }

  Product _convertComponentToProduct(Component component) {
    return Product(
      id: component.id,
      name: component.name,
      model: 'Type ${component.type}',
      brand: 'Component',
      description: component.description,
      imageUrl: component.imageUrl,
      price: component.price,
      stockQuantity: component.stockQuantity,
      technicalSpecs: component.specifications,
      requirements: '',
      minAge: 0,
      maxAge: 99,
      createdAt: component.createdAt,
      updatedAt: component.updatedAt,
      isDeleted: component.isDeleted,
      imagesCount: component.imagesCount,
      courseRobotsCount: 0,
      studentRobotsCount: 0,
    );
  }
}


