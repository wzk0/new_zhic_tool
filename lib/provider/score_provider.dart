import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/model/score.dart';
import 'package:new_zhic_tool/service/score_service.dart';

final scoreProvider = FutureProvider.autoDispose.family<List<Score>, String>((
  ref,
  semesterId,
) async {
  return ScoreService.instance.getScores(semesterId: semesterId);
});
