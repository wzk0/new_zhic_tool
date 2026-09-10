class SemesterConfig {
  final String name;
  final String id;
  final String startDate;

  const SemesterConfig({
    required this.name,
    required this.id,
    required this.startDate,
  });

  factory SemesterConfig.fromJson(Map<String, dynamic> json) {
    return SemesterConfig(
      name: _string(json['name'], fallback: '未知学期'),
      id: _string(json['id'], fallback: ''),
      startDate: _string(json['startDate'], fallback: ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'id': id, 'startDate': startDate};
  }

  SemesterConfig copyWith({String? name, String? id, String? startDate}) {
    return SemesterConfig(
      name: name ?? this.name,
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
    );
  }

  static String _string(dynamic value, {required String fallback}) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return fallback;
    }

    return result;
  }

  @override
  String toString() {
    return 'SemesterConfig('
        'name: $name, '
        'id: $id, '
        'startDate: $startDate'
        ')';
  }
}
