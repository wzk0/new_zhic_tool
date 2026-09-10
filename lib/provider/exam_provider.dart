import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/model/exam.dart';
import 'package:new_zhic_tool/service/exam_service.dart';

final examProvider = FutureProvider.autoDispose.family<List<Exam>, String>((
  ref,
  semesterId,
) async {
  return ExamService.instance.getExams(semesterId);
});
