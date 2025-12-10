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
  final ScrollController _robotScroll = ScrollController();
  final ScrollController _componentScroll = ScrollController();
  final List<RobotItem> _robots = [];
  final List<Component> _components = [];
  int _robotPageIndex = 1;
  int _robotTotalPages = 1;
  bool _robotLoadingMore = false;
  bool _robotHasMore = true;
  int _componentPageIndex = 1;
  int _componentTotalPages = 1;
  bool _componentLoadingMore = false;
  bool _componentHasMore = true;

  // Filters
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _minAgeCtrl = TextEditingController();
  final TextEditingController _maxAgeCtrl = TextEditingController();
  // Slider states
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
    _robotScroll.addListener(() {
      if (_robotScroll.position.pixels >= _robotScroll.position.maxScrollExtent - 200) {
        _loadMoreRobots();
      }
    });
    _componentScroll.addListener(() {
      if (_componentScroll.position.pixels >= _componentScroll.position.maxScrollExtent - 200) {
        _loadMoreComponents();
      }
    });
    // Initialize controllers from sliders so current API calls keep working
    _minAgeCtrl.text = _ageRange.start.round().toString();
    _maxAgeCtrl.text = _ageRange.end.round().toString();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _robotScroll.dispose();
    _componentScroll.dispose();
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
          inStock: _inStock,
          orderBy: _orderBy,
          orderDirection: _orderDirection,
        ),
      ]);

      setState(() {
        _robotPage = (futures[0] as dynamic).data;
        _componentPage = (futures[1] as dynamic).data;
        _robots
          ..clear()
          ..addAll(_robotPage?.items ?? []);
        _components
          ..clear()
          ..addAll(_componentPage?.items ?? []);
        _robotPageIndex = 1;
        _robotTotalPages = _robotPage?.totalPages ?? 1;
        _robotHasMore = _robotPageIndex < _robotTotalPages;
        _componentPageIndex = 1;
        _componentTotalPages = _componentPage?.totalPages ?? 1;
        _componentHasMore = _componentPageIndex < _componentTotalPages;
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
          minAge: int.tryParse(_minAgeCtrl.text.trim()),
          maxAge: int.tryParse(_maxAgeCtrl.text.trim()),
          inStock: _inStock,
          orderBy: _orderBy,
          orderDirection: _orderDirection,
        );
        setState(() {
          _robotPage = res.data;
          _robots
            ..clear()
            ..addAll(_robotPage?.items ?? []);
          _robotPageIndex = 1;
          _robotTotalPages = _robotPage?.totalPages ?? 1;
          _robotHasMore = _robotPageIndex < _robotTotalPages;
          _loading = false;
        });
      } else {
        // Load components
        final res = await _componentService.getComponents(
          page: 1,
          size: 10,
          searchTerm: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          inStock: _inStock,
          orderBy: _orderBy,
          orderDirection: _orderDirection,
        );
        setState(() {
          _componentPage = res.data;
          _components
            ..clear()
            ..addAll(_componentPage?.items ?? []);
          _componentPageIndex = 1;
          _componentTotalPages = _componentPage?.totalPages ?? 1;
          _componentHasMore = _componentPageIndex < _componentTotalPages;
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

  Future<void> _loadMoreRobots() async {
    if (_robotLoadingMore || !_robotHasMore || _selectedTabIndex != 0) return;
    setState(() => _robotLoadingMore = true);
    _robotPageIndex++;
    try {
      final res = await _robotService.getRobots(
        page: _robotPageIndex,
        size: 10,
        searchTerm: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        minAge: int.tryParse(_minAgeCtrl.text.trim()),
        maxAge: int.tryParse(_maxAgeCtrl.text.trim()),
        inStock: _inStock,
        orderBy: _orderBy,
        orderDirection: _orderDirection,
      );
      setState(() {
        _robotPage = res.data;
        _robots.addAll(_robotPage?.items ?? []);
        _robotTotalPages = _robotPage?.totalPages ?? _robotTotalPages;
        _robotHasMore = _robotPageIndex < _robotTotalPages;
      });
    } catch (_) {}
    if (mounted) setState(() => _robotLoadingMore = false);
  }

  Future<void> _loadMoreComponents() async {
    if (_componentLoadingMore || !_componentHasMore || _selectedTabIndex != 1) return;
    setState(() => _componentLoadingMore = true);
    _componentPageIndex++;
    try {
      final res = await _componentService.getComponents(
        page: _componentPageIndex,
        size: 10,
        searchTerm: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        inStock: _inStock,
        orderBy: _orderBy,
        orderDirection: _orderDirection,
      );
      setState(() {
        _componentPage = res.data;
        _components.addAll(_componentPage?.items ?? []);
        _componentTotalPages = _componentPage?.totalPages ?? _componentTotalPages;
        _componentHasMore = _componentPageIndex < _componentTotalPages;
      });
    } catch (_) {}
    if (mounted) setState(() => _componentLoadingMore = false);
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
          icon: const Icon(Icons.tune, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          tooltip: 'store.filters'.tr(),
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

    final items = _robots;
    if (items.isEmpty) {
      return Center(child: Text('resource.empty'.tr()));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        controller: _robotScroll,
        padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 4 : 8, vertical: screenWidth < 360 ? 4 : 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          childAspectRatio: aspect,
          crossAxisSpacing: screenWidth < 360 ? 4 : 8,
          mainAxisSpacing: screenWidth < 360 ? 4 : 8,
        ),
        itemCount: items.length + (_robotLoadingMore ? 1 : 0) + (!_robotHasMore && items.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length && _robotLoadingMore) {
            return const Center(child: CircularProgressIndicator());
          }
          if (index == items.length + (_robotLoadingMore ? 1 : 0) && !_robotHasMore && items.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('challenges.allShown'.tr(), style: TextStyle(color: Colors.grey[600])),
              ),
            );
          }
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

    final items = _components;
    if (items.isEmpty) {
      return Center(child: Text('resource.empty'.tr()));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        controller: _componentScroll,
        padding: EdgeInsets.symmetric(horizontal: screenWidth < 360 ? 4 : 8, vertical: screenWidth < 360 ? 4 : 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCount,
          childAspectRatio: aspect,
          crossAxisSpacing: screenWidth < 360 ? 4 : 8,
          mainAxisSpacing: screenWidth < 360 ? 4 : 8,
        ),
        itemCount: items.length + (_componentLoadingMore ? 1 : 0) + (!_componentHasMore && items.isNotEmpty ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length && _componentLoadingMore) {
            return const Center(child: CircularProgressIndicator());
          }
          if (index == items.length + (_componentLoadingMore ? 1 : 0) && !_componentHasMore && items.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('challenges.allShown'.tr(), style: TextStyle(color: Colors.grey[600])),
              ),
            );
          }
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF17a64b).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Color(0xFF17a64b)),
                  const SizedBox(width: 8),
                  Text(
                    'store.filters'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
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
                  activeColor: const Color(0xFF17a64b),
                  inactiveColor: const Color(0xFF17a64b).withOpacity(0.2),
                  min: 0,
                  max: 25,
                  divisions: 25,
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
                Switch(
                  value: _inStock,
                  onChanged: (v) => setState(() => _inStock = v),
                ),
                Text('store.inStock'.tr()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadBoth,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text('store.apply'.tr(), style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17a64b),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _searchCtrl.clear();
                      _brandCtrl.clear();
                      _minAgeCtrl.clear();
                      _maxAgeCtrl.clear();
                      setState(() {
                        _inStock = false;
                        _orderBy = 'Name';
                        _orderDirection = 'ASC';
                        _ageRange = const RangeValues(6, 18);
                      });
                      _loadBoth();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('store.reset'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF17a64b),
                      side: const BorderSide(color: Color(0xFF17a64b)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
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


