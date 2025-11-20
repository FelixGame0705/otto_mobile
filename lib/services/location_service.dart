import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:ottobit/models/location_model.dart';

class LocationService {
  LocationService._();

  static final LocationService _instance = LocationService._();
  static LocationService get instance => _instance;

  List<Province>? _cache;

  Future<List<Province>> getProvinces() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/js/provinces_wards.json');
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    _cache = jsonList.map((e) => Province.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }
}

