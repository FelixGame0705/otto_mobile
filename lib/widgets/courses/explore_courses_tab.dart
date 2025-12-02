import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ottobit/models/course_model.dart';
import 'package:intl/intl.dart';
import 'package:ottobit/services/course_service.dart';
import 'package:ottobit/widgets/courses/course_search_bar.dart';
import 'package:ottobit/widgets/courses/course_card.dart';
import 'package:ottobit/utils/api_error_handler.dart';
class ExploreCoursesTab extends StatefulWidget {
  const ExploreCoursesTab({super.key});

  @override
  State<ExploreCoursesTab> createState() => _ExploreCoursesTabState();
}

class _ExploreCoursesTabState extends State<ExploreCoursesTab> {
  static const int _defaultSortBy = 1; // CreatedAt
  static const int _defaultSortDirection = 1; // Descending

  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double _priceSliderMin = 0;
  static const double _priceSliderMax = 10000000;
  static const int _priceSliderDivisions = 100;

  List<Course> _courses = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  String _searchTerm = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  int? _minPrice;
  int? _maxPrice;
  int? _selectedType;
  int _sortBy = _defaultSortBy;
  int _sortDirection = _defaultSortDirection;
  int? _draftType;
  int _draftSortBy = _defaultSortBy;
  int _draftSortDirection = _defaultSortDirection;
  RangeValues _draftPriceRange =
      const RangeValues(_priceSliderMin, _priceSliderMax);

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _filtersActive =>
      _minPrice != null ||
      _maxPrice != null ||
      _selectedType != null ||
      _sortBy != _defaultSortBy ||
      _sortDirection != _defaultSortDirection;

  Future<void> _loadCourses({bool isRefresh = false}) async {
    final bool isLoadMore = !isRefresh && _currentPage > 1;
    setState(() {
      // Only show the full-screen loader on initial load or explicit refresh
      _isLoading = !isLoadMore;
      _errorMessage = '';
      if (isRefresh) {
        _currentPage = 1;
        _courses.clear();
        _hasMoreData = true;
      }
    });

    try {
      final response = await _courseService.getCourses(
        searchTerm: _searchTerm.isNotEmpty ? _searchTerm : null,
        pageNumber: _currentPage,
        pageSize: 10,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        type: _selectedType,
        sortBy: _sortBy,
        sortDirection: _sortDirection,
      );

      if (!mounted) return;
      setState(() {
        final items = response.data?.items ?? [];
        if (isRefresh) {
          _courses = items;
        } else {
          _courses.addAll(items);
        }
        _totalPages = response.data?.totalPages ?? 1;
        _hasMoreData = _currentPage < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiErrorMapper.fromException(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreCourses() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadCourses();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCourses();
    }
  }

  void _handleSearch() {
    // Use the tracked search term from onChanged to trigger the search
    _loadCourses(isRefresh: true);
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _searchTerm = value.trim();
    });
  }

  void _handleClearSearch() {
    _searchController.clear();
    _searchTerm = '';
    _loadCourses(isRefresh: true);
  }

  void _openFilterSheet() {
    _draftType = _selectedType;
    _draftSortBy = _sortBy;
    _draftSortDirection = _sortDirection;
    final double start =
        (_minPrice ?? _priceSliderMin.toInt()).toDouble().clamp(
              _priceSliderMin,
              _priceSliderMax,
            );
    final double end =
        (_maxPrice ?? _priceSliderMax.toInt()).toDouble().clamp(
              _priceSliderMin,
              _priceSliderMax,
            );
    _draftPriceRange = RangeValues(start, end);
    _scaffoldKey.currentState?.openDrawer();
  }

  int _calculateCrossAxisCount(double width, Orientation orientation) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return orientation == Orientation.landscape ? 3 : 2;
  }

  double _calculateChildAspectRatio(double width, Orientation orientation) {
    if (width >= 1200) return 0.75;
    if (width >= 900) return 0.67;
    if (width >= 600) return 0.73;
    return orientation == Orientation.landscape ? 0.65 : 0.49;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildFilterDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openFilterSheet,
                    icon: Icon(
                      Icons.tune,
                      color:
                          _filtersActive ? Colors.white : const Color(0xFF17a64b),
                    ),
                    label: const SizedBox.shrink(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _filtersActive ? const Color(0xFF17a64b) : Colors.white,
                      elevation: _filtersActive ? 2 : 0,
                      side: BorderSide(
                        color: _filtersActive
                            ? const Color(0xFF17a64b)
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CourseSearchBar(
                    searchTerm: _searchTerm,
                    controller: _searchController,
                    onSearchChanged: _handleSearchChanged,
                    onSearchPressed: _handleSearch,
                    onClearPressed: _handleClearSearch,
                    margin: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('${'common.error'.tr()}: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCourses(isRefresh: true),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }
    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('common.notFound'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final orientation = mediaQuery.orientation;
    final int crossAxisCount = _calculateCrossAxisCount(screenWidth, orientation);
    final double childAspectRatio = _calculateChildAspectRatio(screenWidth, orientation);
    final EdgeInsets gridPadding = EdgeInsets.symmetric(
      horizontal: screenWidth >= 900 ? 24 : screenWidth >= 600 ? 20 : 12,
    );

    return GridView.builder(
      controller: _scrollController,
      padding: gridPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _courses.length + (_isLoadingMore ? 1 : 0) + (!_hasMoreData && _courses.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _courses.length && _isLoadingMore) {
          return const Center(child: CircularProgressIndicator());
        }
        if (index == _courses.length + (_isLoadingMore ? 1 : 0) && !_hasMoreData && _courses.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('courses.allShown'.tr(), style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
            ),
          );
        }
        if (index < _courses.length) {
          final course = _courses[index];
          return CourseGridCard(course: course);
        }
        return const SizedBox.shrink();
      },
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final intValue = value.round();
    final formatted = formatter.format(intValue);
    return '$formatted ₫';
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: StatefulBuilder(
          builder: (context, setDrawerState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                          'Bộ lọc khóa học',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Khoảng giá (VNĐ)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatCurrency(_draftPriceRange.start),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          _formatCurrency(_draftPriceRange.end),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Theme(
                    data: Theme.of(context).copyWith(
                      sliderTheme: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF17a64b),
                        inactiveTrackColor: const Color(0xFF17a64b).withOpacity(0.2),
                        thumbColor: const Color(0xFF17a64b),
                        overlayColor: const Color(0x3317a64b),
                        valueIndicatorColor: const Color(0xFF17a64b),
                      ),
                    ),
                    child: RangeSlider(
                      values: _draftPriceRange,
                      min: _priceSliderMin,
                      max: _priceSliderMax,
                      divisions: _priceSliderDivisions,
                      labels: RangeLabels(
                        _formatCurrency(_draftPriceRange.start),
                        _formatCurrency(_draftPriceRange.end),
                      ),
                      onChanged: (values) => setDrawerState(() {
                        _draftPriceRange = values;
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loại khóa học',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả'),
                        selected: _draftType == null,
                        onSelected: (_) => setDrawerState(() => _draftType = null),
                      ),
                      ChoiceChip(
                        label: const Text('Miễn phí'),
                        selected: _draftType == 1,
                        onSelected: (_) => setDrawerState(() => _draftType = 1),
                      ),
                      ChoiceChip(
                        label: const Text('Trả phí'),
                        selected: _draftType == 2,
                        onSelected: (_) => setDrawerState(() => _draftType = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sắp xếp theo',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _draftSortBy,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Tiêu đề')),
                      DropdownMenuItem(value: 1, child: Text('Ngày tạo')),
                    ],
                    onChanged: (value) =>
                        setDrawerState(() => _draftSortBy = value ?? _defaultSortBy),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Thứ tự',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _draftSortDirection,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Tăng dần')),
                      DropdownMenuItem(value: 1, child: Text('Giảm dần')),
                    ],
                    onChanged: (value) => setDrawerState(
                        () => _draftSortDirection = value ?? _defaultSortDirection),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setDrawerState(() {
                              _draftPriceRange = const RangeValues(
                                _priceSliderMin,
                                _priceSliderMax,
                              );
                              _draftType = null;
                              _draftSortBy = _defaultSortBy;
                              _draftSortDirection = _defaultSortDirection;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Đặt lại'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF17a64b),
                            side: const BorderSide(color: Color(0xFF17a64b)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final int startValue =
                                _draftPriceRange.start.round();
                            final int endValue = _draftPriceRange.end.round();
                            setState(() {
                              _minPrice = startValue > 0 ? startValue : null;
                              _maxPrice = endValue < _priceSliderMax
                                  ? endValue
                                  : null;
                              _selectedType = _draftType;
                              _sortBy = _draftSortBy;
                              _sortDirection = _draftSortDirection;
                            });
                            Navigator.of(context).pop();
                            _loadCourses(isRefresh: true);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Áp dụng'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF17a64b),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

