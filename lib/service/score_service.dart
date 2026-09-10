import 'package:new_zhic_tool/model/score.dart';
import 'package:new_zhic_tool/service/network_service.dart';

class ScoreService {
  ScoreService._();

  static final ScoreService instance = ScoreService._();

  Future<List<Score>> getScores({required String semesterId}) async {
    final businessId = await NetworkService.instance.getStudentBusinessId();
    if (businessId == null) {
      throw Exception('无法获取业务ID, 请尝试重新登入');
    }
    final url =
        'https://eams.tjzhic.edu.cn/student/for-std/grade/sheet/info/$businessId';
    final response = await NetworkService.instance.get(
      url,
      queryParameters: {'semester': semesterId},
      withCookies: true,
    );
    if (response is! Map<String, dynamic>) {
      throw Exception('成绩数据格式异常');
    }
    final semesterId2studentGrades = response['semesterId2studentGrades'];
    if (semesterId2studentGrades is! Map) {
      return [];
    }
    final data = semesterId2studentGrades[semesterId];
    if (data == null) {
      return [];
    }
    if (data is! List) {
      throw Exception('成绩数据格式异常');
    }
    return data
        .whereType<Map>()
        .map((item) => Score.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
