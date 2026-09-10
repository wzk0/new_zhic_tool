import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:new_zhic_tool/model/training.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingSummary {
  const TrainingSummary({
    required this.completedCount,
    required this.completedCredits,
    required this.incompleteCount,
    required this.incompleteCredits,
    required this.totalCount,
    required this.totalCredits,
  });

  final int completedCount;

  final double completedCredits;

  final int incompleteCount;

  final double incompleteCredits;

  final int totalCount;

  final double totalCredits;
}

class TrainingModuleSummary {
  const TrainingModuleSummary({
    required this.completedCount,
    required this.completedCredits,
    required this.incompleteCount,
    required this.incompleteCredits,
    required this.totalCount,
    required this.totalCredits,
  });

  final int completedCount;

  final double completedCredits;

  final int incompleteCount;

  final double incompleteCredits;

  final int totalCount;

  final double totalCredits;
}

class TrainingService {
  TrainingService._();

  static final TrainingService instance = TrainingService._();

  static const String _cookieKey = 'cookies';

  Future<String?> _getCookies() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_cookieKey);
  }

  Future<Map<String, String>> getHeaders() async {
    final cookie = await _getCookies();

    return {
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': 'Mozilla/5.0',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  List<TrainingModule> parseHtml(String html) {
    final document = html_parser.parse(html);

    final modules = document.getElementsByClassName('module-tpl depth-1');

    final result = <TrainingModule>[];

    for (final module in modules) {
      result.add(_parseModule(module));
    }

    debugPrint('成功解析出 ${result.length} 个一级模块');

    return result;
  }

  TrainingSummary calculateSummary(List<TrainingModule> trainings) {
    var completedCount = 0;
    var incompleteCount = 0;

    var completedCredits = 0.0;
    var incompleteCredits = 0.0;

    for (final module in trainings) {
      final summary = calculateModuleSummary(module);

      completedCount += summary.completedCount;
      incompleteCount += summary.incompleteCount;

      completedCredits += summary.completedCredits;
      incompleteCredits += summary.incompleteCredits;
    }

    return TrainingSummary(
      completedCount: completedCount,
      completedCredits: completedCredits,
      incompleteCount: incompleteCount,
      incompleteCredits: incompleteCredits,
      totalCount: completedCount + incompleteCount,
      totalCredits: completedCredits + incompleteCredits,
    );
  }

  TrainingModuleSummary calculateModuleSummary(TrainingModule module) {
    var completedCount = 0;
    var incompleteCount = 0;

    var completedCredits = 0.0;
    var incompleteCredits = 0.0;

    for (final subModule in module.subModules) {
      final summary = _calculateSubModuleSummary(subModule);

      completedCount += summary.completedCount;
      incompleteCount += summary.incompleteCount;

      completedCredits += summary.completedCredits;
      incompleteCredits += summary.incompleteCredits;
    }

    return TrainingModuleSummary(
      completedCount: completedCount,
      completedCredits: completedCredits,
      incompleteCount: incompleteCount,
      incompleteCredits: incompleteCredits,
      totalCount: completedCount + incompleteCount,
      totalCredits: completedCredits + incompleteCredits,
    );
  }

  TrainingModuleSummary _calculateSubModuleSummary(TrainingSubModule module) {
    var completedCount = 0;
    var incompleteCount = 0;

    var completedCredits = 0.0;
    var incompleteCredits = 0.0;

    for (final course in module.courses) {
      final credits = _parseCredits(course.credits);

      if (_isCompleted(course.status)) {
        completedCount++;
        completedCredits += credits;
      } else {
        incompleteCount++;
        incompleteCredits += credits;
      }
    }

    for (final subModule in module.subModules) {
      final summary = _calculateSubModuleSummary(subModule);

      completedCount += summary.completedCount;
      incompleteCount += summary.incompleteCount;

      completedCredits += summary.completedCredits;
      incompleteCredits += summary.incompleteCredits;
    }

    return TrainingModuleSummary(
      completedCount: completedCount,
      completedCredits: completedCredits,
      incompleteCount: incompleteCount,
      incompleteCredits: incompleteCredits,
      totalCount: completedCount + incompleteCount,
      totalCredits: completedCredits + incompleteCredits,
    );
  }

  bool _isCompleted(String status) {
    final normalized = status
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();

    return normalized == '通过';
  }

  double _parseCredits(String credits) {
    final normalized = credits
        .replaceAll('\u00a0', ' ')
        .replaceAll(',', '.')
        .trim();

    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(normalized);

    if (match == null) {
      return 0;
    }

    return double.tryParse(match.group(0)!) ?? 0;
  }

  TrainingModule _parseModule(Element module) {
    final nameElement = module.querySelector('.module-name');

    final signElement = module.querySelector('.m-title .title-sign');

    final name = nameElement?.text.trim() ?? '';

    final sign = signElement?.text.trim() ?? '';

    final subModules = _parseDirectSubModules(module);

    debugPrint(
      '一级模块：$name, '
      '二级模块：${subModules.length}',
    );

    return TrainingModule(name: name, sign: sign, subModules: subModules);
  }

  List<TrainingSubModule> _parseDirectSubModules(Element module) {
    final result = <TrainingSubModule>[];

    final content = _getDirectContent(module);

    if (content == null) {
      return result;
    }

    final childrenContainer = _getDirectChildrenContainer(content);

    if (childrenContainer == null) {
      return result;
    }

    for (final child in childrenContainer.children) {
      if (!_isModuleElement(child)) {
        continue;
      }

      result.add(_parseSubModule(child));
    }

    return result;
  }

  TrainingSubModule _parseSubModule(Element module) {
    final nameElement = module.querySelector('.m-title .module-name');

    final signElement = module.querySelector('.m-title .title-sign');

    final name = nameElement?.text.trim() ?? '';

    final sign = signElement?.text.trim() ?? '';

    final content = _getDirectContent(module);

    final courses = <TrainingCourse>[];

    if (content != null) {
      final table = _getDirectCourseTable(content);

      if (table != null) {
        final rows = table.querySelectorAll('tbody > tr');

        for (final row in rows) {
          final course = _parseCourse(row);

          if (course != null) {
            courses.add(course);
          }
        }
      }
    }

    final subModules = _parseDirectSubModules(module);

    debugPrint(
      '模块：$name | '
      '课程：${courses.length} 门 | '
      '子模块：${subModules.length} 个',
    );

    return TrainingSubModule(
      name: name,
      sign: sign,
      courses: courses,
      subModules: subModules,
    );
  }

  Element? _getDirectContent(Element module) {
    for (final child in module.children) {
      if (child.classes.contains('m-content')) {
        return child;
      }
    }

    return null;
  }

  Element? _getDirectChildrenContainer(Element content) {
    for (final child in content.children) {
      if (child.classes.contains('c-children')) {
        return child;
      }
    }

    return null;
  }

  Element? _getDirectCourseTable(Element content) {
    for (final child in content.children) {
      if (child.localName == 'table' && child.classes.contains('c-table')) {
        return child;
      }
    }

    return null;
  }

  bool _isModuleElement(Element element) {
    return element.classes.contains('module-tpl');
  }

  TrainingCourse? _parseCourse(Element row) {
    final columns = row.getElementsByTagName('td');

    /*
     * 当前页面课程表结构：
     *
     * 0 课程名称
     * 1 课程代码
     * 2 学期
     * 3 性质
     * 4 学分
     * 5 成绩
     * 6 绩点
     * 7 系统检查情况
     * 8 最终检查情况
     * 9 备注
     *
     * 实际课程完成状态优先使用：
     *
     * 最终检查情况
     */

    if (columns.length < 8) {
      return null;
    }

    String getText(int index) {
      return columns[index].text.replaceAll('\u00a0', ' ').trim();
    }

    final statusIndex = columns.length >= 9 ? 8 : 7;

    final course = TrainingCourse(
      name: _getCourseName(columns[0]),
      code: getText(1),
      semester: getText(2),
      nature: getText(3),
      credits: getText(4),
      score: getText(5),
      gpa: getText(6),
      status: getText(statusIndex),
    );

    debugPrint(
      '课程：${course.name} | '
      '学分：${course.credits} | '
      '状态：${course.status}',
    );

    return course;
  }

  String _getCourseName(Element column) {
    final dataText = column.attributes['data-text'];

    if (dataText != null && dataText.trim().isNotEmpty) {
      return dataText.trim();
    }

    var name = column.text.replaceAll('\u00a0', ' ').trim();

    name = name.replaceFirst(RegExp(r'^\d+\.\s*'), '');

    return name.trim();
  }
}
