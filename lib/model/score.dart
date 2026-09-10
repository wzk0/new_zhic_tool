class Score {
  const Score({
    required this.courseName,
    required this.courseCode,
    required this.courseProperty,
    required this.grade,
    required this.credits,
    required this.gp,
    required this.passed,
  });

  final String courseName;

  final String courseCode;

  final String courseProperty;

  final String grade;

  final double credits;

  final double gp;

  final bool passed;

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      courseName: json['courseName']?.toString() ?? '未知课程',

      courseCode: json['courseCode']?.toString() ?? '',

      courseProperty: json['courseProperty']?.toString() ?? '',

      grade: json['gaGrade']?.toString() ?? '-',

      credits: (json['credits'] as num?)?.toDouble() ?? 0,

      gp: (json['gp'] as num?)?.toDouble() ?? 0,

      passed: json['passed'] == true,
    );
  }
}
