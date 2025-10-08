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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
  // Slider states
  RangeValues _priceRange = const RangeValues(0, 1000);
  RangeValues _ageRange = const RangeValues(6, 18);
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
    _loadBoth(); // Load both robots and components initially
    // Initialize controllers from sliders so current API calls keep working
    _minPriceCtrl.text = _priceRange.start.round().toString();
    _maxPriceCtrl.text = _priceRange.end.round().toString();
    _minAgeCtrl.text = _ageRange.start.round().toString();
    _maxAgeCtrl.text = _ageRange.end.round().toString();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadBoth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load both robots and components in parallel
      final futures = await Future.wait([
        _robotService.getRobots(
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
        ),
        _componentService.getComponents(
          page: 1,
          size: 10,
          searchTerm: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          minPrice: int.tryParse(_minPriceCtrl.text.trim()),
          maxPrice: int.tryParse(_maxPriceCtrl.text.trim()),
          inStock: _inStock,
          orderBy: _orderBy,
          orderDirection: _orderDirection,
        ),
      ]);

      setState(() {
        _robotPage = (futures[0] as dynamic).data;
        _componentPage = (futures[1] as dynamic).data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
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
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final int gridCount = _calculateCrossAxisCount(screenWidth);
    final double aspect = _calculateChildAspectRatio(screenWidth);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: screenWidth < 420 ? screenWidth * 0.9 : 320,
        child: SafeArea(
          child: SingleChildScrollView(child: _buildFilterBar(screenWidth)),
        ),
      ),
      appBar: AppBar(
        title: Text('store.title'.tr()),
        backgroundColor: const Color(0xFF00ba4a),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        bottom: TabBar(
          controller: _tabController!,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.smart_toy_outlined), text: 'store.robots'.tr()),
            Tab(icon: const Icon(Icons.extension), text: 'store.components'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildRobotsTab(gridCount, aspect, screenWidth),
          _buildComponentsTab(gridCount, aspect, screenWidth),
        ],
      ),
    );
  }

  Widget _buildRobotsTab(int gridCount, double aspect, double screenWidth) {
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
        padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 4 : 8, vertical: screenWidth < 360 ? 4 : 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          childAspectRatio: aspect,
          crossAxisSpacing: screenWidth < 360 ? 4 : 8,
          mainAxisSpacing: screenWidth < 360 ? 4 : 8,
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

  Widget _buildComponentsTab(int gridCount, double aspect, double screenWidth) {
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
        padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 4 : 8, vertical: screenWidth < 360 ? 4 : 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          childAspectRatio: aspect,
          crossAxisSpacing: screenWidth < 360 ? 4 : 8,
          mainAxisSpacing: screenWidth < 360 ? 4 : 8,
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

  int _calculateCrossAxisCount(double width) {
    if (width < 360) return 1; // very small phones
    if (width < 600) return 2; // phones
    if (width < 900) return 3; // small tablets / landscape phones
    if (width < 1200) return 4; // tablets
    if (width < 1600) return 5; // small desktops
    return 6; // large desktops
  }

  double _calculateChildAspectRatio(double width) {
    if (width < 360) return 0.85;
    if (width < 600) return 0.68;
    if (width < 900) return 0.7;
    if (width < 1200) return 0.75;
    if (width < 1600) return 0.78;
    return 0.8;
  }

  Widget _buildFilterBar(double screenWidth) {
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
            if (screenWidth < 420) ...[
              Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'store.search'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _brandCtrl,
                    decoration: InputDecoration(
                      hintText: 'store.brand'.tr(),
                      isDense: true,
                      prefixIcon: const Icon(Icons.sell_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ] else ...[
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
            ],
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('store.price'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_priceRange.start.round()} - ${_priceRange.end.round()}'),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  labels: RangeLabels('${_priceRange.start.round()}', '${_priceRange.end.round()}'),
                  onChanged: (v) {
                    setState(() {
                      _priceRange = v;
                      _minPriceCtrl.text = v.start.round().toString();
                      _maxPriceCtrl.text = v.end.round().toString();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('store.age'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${_ageRange.start.round()} - ${_ageRange.end.round()}'),
                  ],
                ),
                RangeSlider(
                  values: _ageRange,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  labels: RangeLabels('${_ageRange.start.round()}', '${_ageRange.end.round()}'),
                  onChanged: (v) {
                    setState(() {
                      _ageRange = v;
                      _minAgeCtrl.text = v.start.round().toString();
                      _maxAgeCtrl.text = v.end.round().toString();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (screenWidth < 420) ...[
              Column(
                children: [
                  DropdownButtonFormField<String>(
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
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
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
                ],
              ),
            ] else ...[
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
            ],
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
                  onPressed: _loadBoth,
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
                    _loadBoth();
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
      stockQuantity: 0, // Remove stock display
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
      stockQuantity: 0, // Remove stock display
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


