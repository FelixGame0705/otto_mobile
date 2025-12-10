class RobotImageItem {
  final String id;
  final String robotId;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String robotName;

  RobotImageItem({
    required this.id,
    required this.robotId,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.robotName,
  });

  factory RobotImageItem.fromJson(Map<String, dynamic> json) {
    return RobotImageItem(
      id: (json['id'] as String?) ?? '',
      robotId: (json['robotId'] as String?) ?? '',
      url: (json['url'] as String?) ?? '',
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
      isDeleted: (json['isDeleted'] as bool?) ?? false,
      robotName: (json['robotName'] as String?) ?? '',
    );
  }
}

class RobotImagePage {
  final int size;
  final int page;
  final int total;
  final int totalPages;
  final List<RobotImageItem> items;

  RobotImagePage({
    required this.size,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory RobotImagePage.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return RobotImagePage(
      size: (json['size'] as int?) ?? 0,
      page: (json['page'] as int?) ?? 1,
      total: (json['total'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ?? 0,
      items: itemsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => RobotImageItem.fromJson(e))
          .toList(),
    );
  }
}


