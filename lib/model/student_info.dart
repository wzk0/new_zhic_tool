class StudentInfo {
  const StudentInfo({
    this.name = '',
    this.code = '',
    this.department = '',
    this.adminClass = '',
  });

  final String name;
  final String code;
  final String department;
  final String adminClass;

  String get info {
    final parts = [
      department,
      adminClass,
    ].where((e) => e.trim().isNotEmpty).toList();

    return parts.join(' · ');
  }

  String get avatarText {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(trimmed.length - 1);
  }

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      name: json['name']?.toString().trim() ?? '',
      code: json['code']?.toString().trim() ?? '',
      department: json['department']?.toString().trim() ?? '',
      adminClass: json['adminclass']?.toString().trim() ?? '',
    );
  }
}
