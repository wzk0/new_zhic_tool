class TrainingModule {
  const TrainingModule({
    required this.name,
    required this.sign,
    required this.subModules,
  });

  final String name;

  final String sign;

  final List<TrainingSubModule> subModules;
}

class TrainingSubModule {
  const TrainingSubModule({
    required this.name,
    required this.sign,
    this.courses = const [],
    this.subModules = const [],
  });

  final String name;

  final String sign;

  final List<TrainingCourse> courses;

  final List<TrainingSubModule> subModules;
}

class TrainingCourse {
  const TrainingCourse({
    required this.name,
    required this.code,
    required this.semester,
    required this.nature,
    required this.credits,
    required this.score,
    required this.gpa,
    required this.status,
  });

  final String name;

  final String code;

  final String semester;

  final String nature;

  final String credits;

  final String score;

  final String gpa;

  final String status;
}
