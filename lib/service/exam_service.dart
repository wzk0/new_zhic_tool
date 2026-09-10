import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:new_zhic_tool/model/exam.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamService {
  ExamService._();
  static final ExamService instance = ExamService._();
  static const String _cookieKey = 'cookies';
  Future<String> _getStudentBusinessId() async {
    const url = 'https://eams.tjzhic.edu.cn/student/for-std/grade/sheet/';
    final prefs = await SharedPreferences.getInstance();
    final cookies = prefs.getString(_cookieKey)?.replaceAll('"', '');
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..followRedirects = false
        ..headers['Cookie'] = cookies ?? '';

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
      final id = _extractId(finalUrl);
      if (id != null) {
        return id;
      }
      throw Exception('无法获取业务ID');
    } finally {
      client.close();
    }
  }

  String? _extractId(String url) {
    final regExp = RegExp(r'/(\d+)$|/(\d+)\?');

    final match = regExp.firstMatch(url);

    return match?.group(1) ?? match?.group(2);
  }

  Future<List<Exam>> getExams(String semesterId) async {
    final businessId = await _getStudentBusinessId();

    final prefs = await SharedPreferences.getInstance();

    final cookies = prefs.getString(_cookieKey)?.replaceAll('"', '');

    final uri = Uri.parse(
      'https://eams.tjzhic.edu.cn/student/for-std/'
      'exam-arrange/info/$businessId',
    ).replace(queryParameters: {'semester': semesterId});

    final response = await http.get(
      uri,
      headers: {'Cookie': cookies ?? '', 'User-Agent': 'Mozilla/5.0'},
    );

    if (response.statusCode != 200) {
      throw Exception('服务器响应错误: ${response.statusCode}');
    }

    return _parseHtml(response.body);
  }

  List<Exam> _parseHtml(String htmlBody) {
    final document = parse(htmlBody);
    final exams = <Exam>[];
    final rows = document
        .querySelectorAll('tbody tr')
        .where((row) => !row.classes.contains('tr-empty'));

    for (final row in rows) {
      final cells = row.querySelectorAll('td');

      if (cells.length < 3) {
        continue;
      }
      final time = cells[0].querySelector('.time')?.text.trim() ?? '';
      final locationNodes = cells[0].querySelectorAll('div:not(.time) span');

      final location = locationNodes
          .map((e) => e.text.trim())
          .where((text) => text.isNotEmpty)
          .join(' ');
      final courseName =
          cells[1]
              .querySelector('span[style*="font-weight: bold"]')
              ?.text
              .trim() ??
          '';
      final type = cells[1].querySelector('.tag-span')?.text.trim() ?? '考试';
      final status = cells[2].text.trim();
      final isFinished = row.classes.contains('finished') || status == '已结束';

      exams.add(
        Exam(
          courseName: courseName,
          time: time,
          location: location,
          type: type,
          status: status,
          isFinished: isFinished,
        ),
      );
    }

    return exams;
  }
}
