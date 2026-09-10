class Exam {
  const Exam({
    required this.courseName,
    required this.time,
    required this.location,
    required this.type,
    required this.status,
    required this.isFinished,
  });

  final String courseName;

  final String time;

  final String location;

  final String type;

  final String status;

  final bool isFinished;

  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      courseName: map['courseName']?.toString() ?? '',
      time: map['time']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      type: map['type']?.toString() ?? '考试',
      status: map['status']?.toString() ?? '',
      isFinished: map['isFinished'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseName': courseName,
      'time': time,
      'location': location,
      'type': type,
      'status': status,
      'isFinished': isFinished,
    };
  }
}
