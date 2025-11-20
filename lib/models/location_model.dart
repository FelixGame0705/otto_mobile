class Province {
  final String code;
  final String name;
  final List<Ward> wards;

  Province({
    required this.code,
    required this.name,
    required this.wards,
  });

  factory Province.fromJson(Map<String, dynamic> json) {
    final wardsJson = (json['wards'] as List?) ?? const [];
    return Province(
      code: json['province_code']?.toString() ?? '',
      name: json['province_name']?.toString() ?? '',
      wards: wardsJson.map((w) => Ward.fromJson(w as Map<String, dynamic>)).toList(),
    );
  }
}

class Ward {
  final String code;
  final String name;

  Ward({
    required this.code,
    required this.name,
  });

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(
      code: json['ward_code']?.toString() ?? '',
      name: json['ward_name']?.toString() ?? '',
    );
  }
}

