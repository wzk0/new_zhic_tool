class Course {
  final String name;
  final String room;
  final int weekday;
  final int startUnit;
  final int endUnit;
  final List<String> teachers;
  final String id;
  final String classType;
  final int credits;
  final String building;
  final String startTime;
  final String endTime;

  const Course({
    required this.name,
    required this.room,
    required this.weekday,
    required this.startUnit,
    required this.endUnit,
    this.teachers = const [],
    required this.id,
    required this.classType,
    required this.credits,
    required this.building,
    required this.startTime,
    required this.endTime,
  }) : assert(weekday >= 1 && weekday <= 7),
       assert(startUnit >= 1),
       assert(endUnit >= 1),
       assert(startUnit <= endUnit);

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: _string(json['courseCode'], fallback: '未知ID'),
      name: _string(json['courseName'] ?? json['name'], fallback: '未知课程'),
      room: _string(json['room'], fallback: '未知地点'),
      weekday: _toInt(json['weekday'], fallback: 1),
      startUnit: _toInt(json['startUnit'], fallback: 1),
      endUnit: _toInt(json['endUnit'], fallback: 1),
      teachers: _parseTeachers(json['teachers']),
      classType: _string(json['courseType']['name'], fallback: '未知类型'),
      credits: _toInt(json['credits'], fallback: 1),
      building: _string(json['building'], fallback: '未知楼宇'),
      startTime: _string(json['startTime'], fallback: '未知时间'),
      endTime: _string(json['endTime'], fallback: '未知时间'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': name,
      'room': room,
      'weekday': weekday,
      'startUnit': startUnit,
      'endUnit': endUnit,
      'teachers': teachers,
    };
  }

  Course? normalized({int totalUnits = 12}) {
    final normalizedWeekday = weekday.clamp(1, 7);
    final normalizedStart = startUnit.clamp(1, totalUnits);
    final normalizedEnd = endUnit.clamp(1, totalUnits);

    if (normalizedStart > normalizedEnd) {
      return null;
    }

    return Course(
      id: id,
      name: name.trim().isEmpty ? '未知课程' : name.trim(),
      room: room.trim().isEmpty ? '未知地点' : room.trim(),
      weekday: normalizedWeekday,
      startUnit: normalizedStart,
      endUnit: normalizedEnd,
      teachers: List.unmodifiable(teachers),
      classType: classType,
      credits: credits,
      building: building,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Course copyWith({
    String? id,
    String? name,
    String? room,
    int? weekday,
    int? startUnit,
    int? endUnit,
    List<String>? teachers,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      weekday: weekday ?? this.weekday,
      startUnit: startUnit ?? this.startUnit,
      endUnit: endUnit ?? this.endUnit,
      teachers: teachers ?? this.teachers,
      classType: classType,
      credits: credits,
      building: building,
      startTime: startTime,
      endTime: endTime,
    );
  }

  static String _string(dynamic value, {required String fallback}) {
    final result = value?.toString().trim();

    if (result == null || result.isEmpty) {
      return fallback;
    }

    return result;
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _parseTeachers(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }

    return const [];
  }

  @override
  String toString() {
    return 'Course('
        'id: $id, '
        'name: $name, '
        'room: $room, '
        'weekday: $weekday, '
        'startUnit: $startUnit, '
        'endUnit: $endUnit, '
        'teachers: $teachers'
        ')';
  }
}
