import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class StoreFilterDrawer extends StatefulWidget {
  final TextEditingController searchController;
  final TextEditingController brandController;
  final TextEditingController minAgeController;
  final TextEditingController maxAgeController;
  final RangeValues ageRange;
  final bool inStock;
  final String orderBy;
  final String orderDirection;
  final bool showFilters;
  final VoidCallback onApply;
  final VoidCallback onReset;
  final Function(RangeValues) onAgeRangeChanged;
  final Function(bool) onInStockChanged;
  final Function(String) onOrderByChanged;
  final Function(String) onOrderDirectionChanged;

  const StoreFilterDrawer({
    super.key,
    required this.searchController,
    required this.brandController,
    required this.minAgeController,
    required this.maxAgeController,
    required this.ageRange,
    required this.inStock,
    required this.orderBy,
    required this.orderDirection,
    required this.showFilters,
    required this.onApply,
    required this.onReset,
    required this.onAgeRangeChanged,
    required this.onInStockChanged,
    required this.onOrderByChanged,
    required this.onOrderDirectionChanged,
  });

  @override
  State<StoreFilterDrawer> createState() => _StoreFilterDrawerState();
}

class _StoreFilterDrawerState extends State<StoreFilterDrawer> {
  late RangeValues _ageRange;
  late String _orderBy;
  late String _orderDirection;

  @override
  void initState() {
    super.initState();
    _ageRange = widget.ageRange;
    _orderBy = widget.orderBy;
    _orderDirection = widget.orderDirection;
  }

  @override
  void didUpdateWidget(StoreFilterDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ageRange != widget.ageRange) {
      _ageRange = widget.ageRange;
    }
    if (oldWidget.orderBy != widget.orderBy) {
      _orderBy = widget.orderBy;
    }
    if (oldWidget.orderDirection != widget.orderDirection) {
      _orderDirection = widget.orderDirection;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Material(
      elevation: 1,
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
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
                      'store.filters'.tr(),
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
              if (widget.showFilters) ...[
                const SizedBox(height: 24),
                Text(
                  'store.searchAndBrand'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (screenWidth < 420) ...[
                  Column(
                    children: [
                      TextField(
                        controller: widget.searchController,
                        decoration: InputDecoration(
                          hintText: 'store.search'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFF17a64b)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: widget.brandController,
                        decoration: InputDecoration(
                          hintText: 'store.brand'.tr(),
                          prefixIcon: const Icon(Icons.sell_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFF17a64b)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.searchController,
                          decoration: InputDecoration(
                            hintText: 'store.search'.tr(),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF17a64b)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: widget.brandController,
                          decoration: InputDecoration(
                            hintText: 'store.brand'.tr(),
                            prefixIcon: const Icon(Icons.sell_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF17a64b)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'store.age'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: _ageRange,
                      activeColor: const Color(0xFF17a64b),
                      inactiveColor: const Color(0xFF17a64b).withOpacity(0.2),
                      min: 1,
                      max: 100,
                      divisions: 100,
                      labels: RangeLabels(
                        '${_ageRange.start.round()}',
                        '${_ageRange.end.round()}',
                      ),
                      onChanged: (v) {
                        setState(() {
                          _ageRange = v;
                          widget.minAgeController.text = v.start.round().toString();
                          widget.maxAgeController.text = v.end.round().toString();
                        });
                        widget.onAgeRangeChanged(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'store.sortBy'.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
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
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _orderBy = v);
                            widget.onOrderByChanged(v);
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFF17a64b)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _orderDirection,
                        items: [
                          DropdownMenuItem(value: 'ASC', child: Text('store.asc'.tr())),
                          DropdownMenuItem(value: 'DESC', child: Text('store.desc'.tr())),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _orderDirection = v);
                            widget.onOrderDirectionChanged(v);
                          }
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(color: Color(0xFF17a64b)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _orderBy = v);
                              widget.onOrderByChanged(v);
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF17a64b)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _orderDirection,
                          items: [
                            DropdownMenuItem(value: 'ASC', child: Text('store.asc'.tr())),
                            DropdownMenuItem(value: 'DESC', child: Text('store.desc'.tr())),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _orderDirection = v);
                              widget.onOrderDirectionChanged(v);
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                              borderSide: BorderSide(color: Color(0xFF17a64b)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onReset,
                        icon: const Icon(Icons.refresh),
                        label: Text('store.reset'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF17a64b),
                          side: const BorderSide(color: Color(0xFF17a64b)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onApply,
                        icon: const Icon(Icons.check),
                        label: Text('store.apply'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF17a64b),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

