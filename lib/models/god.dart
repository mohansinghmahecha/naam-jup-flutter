// lib/models/god.dart
class God {
  final String id;
  String name;
  int sessionCount;
  int totalCount;

  God({
    required this.id,
    required this.name,
    this.sessionCount = 0,
    this.totalCount = 0,
  });

  factory God.fromJson(Map<String, dynamic> json) {
    return God(
      id: json['id'] as String,
      name: json['name'] as String,
      sessionCount: (json['sessionCount'] ?? 0) as int,
      totalCount: (json['totalCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sessionCount': sessionCount,
    'totalCount': totalCount,
  };
}
