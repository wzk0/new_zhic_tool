import 'package:http/http.dart' as http;
import 'package:new_zhic_tool/model/score.dart';
import 'package:new_zhic_tool/service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScoreService {
  ScoreService._();

  static final ScoreService instance = ScoreService._();

  Future<List<Score>> getScores({required String semesterId}) async {
    final businessId = await _getStudentBusinessId();

    if (businessId == null) {
      throw Exception('无法获取业务ID，请尝试重新登入');
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

  Future<String?> _getStudentBusinessId() async {
    const url = 'https://eams.tjzhic.edu.cn/student/for-std/grade/sheet/';

    final prefs = await SharedPreferences.getInstance();

    final cookies = prefs.getString('cookies')?.replaceAll('"', '');

    final client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url))
        ..followRedirects = false
        ..headers['Cookie'] = cookies ?? ''
        ..headers['User-Agent'] = 'Mozilla/5.0';

      final streamedResponse = await client.send(request);

      final response = await http.Response.fromStream(streamedResponse);

      final location = response.headers['location'];

      if (location != null) {
        final id = _extractId(location);

        if (id != null) {
          return id;
        }
      }

      final finalUrl = response.request?.url.toString() ?? '';

      return _extractId(finalUrl);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String? _extractId(String url) {
    final regExp = RegExp(r'/(\d+)(?:\?|$)');

    final match = regExp.firstMatch(url);

    return match?.group(1);
  }
}
