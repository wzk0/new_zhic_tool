import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:new_zhic_tool/model/training.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 培养方案总汇总

class TrainingSummary {
  const TrainingSummary({
    required this.completedCount,
    required this.completedCredits,
    required this.incompleteCount,
    required this.incompleteCredits,
    required this.totalCount,
    required this.totalCredits,
  });

  /// 已完成课程数量
  final int completedCount;

  /// 已完成课程学分
  final double completedCredits;

  /// 未完成课程数量
  final int incompleteCount;

  /// 未完成课程学分
  final double incompleteCredits;

  /// 总课程数量
  final int totalCount;

  /// 总学分
  final double totalCredits;
}

/// 一级模块汇总

class TrainingModuleSummary {
  const TrainingModuleSummary({
    required this.completedCount,
    required this.completedCredits,
    required this.incompleteCount,
    required this.incompleteCredits,
    required this.totalCount,
    required this.totalCredits,
  });

  /// 已完成课程数量
  final int completedCount;

  /// 已完成课程学分
  final double completedCredits;

  /// 未完成课程数量
  final int incompleteCount;

  /// 未完成课程学分
  final double incompleteCredits;

  /// 本模块课程总数量
  final int totalCount;

  /// 本模块课程总学分
  final double totalCredits;
}

/// 培养方案 Service

class TrainingService {
  TrainingService._();

  static final TrainingService instance = TrainingService._();

  static const String _cookieKey = 'cookies';

  // Cookie

  /// 获取当前登录 Cookie
  Future<String?> _getCookies() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_cookieKey);
  }

  /// 构造 WebView 请求 Header
  Future<Map<String, String>> getHeaders() async {
    final cookie = await _getCookies();

    return {
      'Accept': 'application/json, text/plain, */*',
      'User-Agent': 'Mozilla/5.0',
      if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
    };
  }

  // HTML 解析

  /// 解析培养方案 HTML
  ///
  /// HTML
  ///
  /// depth-1
  ///   ↓
  /// depth-2
  ///   ↓
  /// depth-3
  ///   ↓
  /// courses
  ///
  /// 使用递归解析，因此支持更多层级。
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

  // 培养方案总汇总

  /// 计算整个培养方案的汇总数据
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

  // 一级模块汇总

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

  // 子模块递归汇总

  TrainingModuleSummary _calculateSubModuleSummary(TrainingSubModule module) {
    var completedCount = 0;
    var incompleteCount = 0;

    var completedCredits = 0.0;
    var incompleteCredits = 0.0;

    // 当前模块课程

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

    // 子模块

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

  // 完成状态

  bool _isCompleted(String status) {
    final normalized = status
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\s+'), '')
        .trim();

    return normalized == '通过';
  }

  // 学分解析

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

  // 一级模块

  TrainingModule _parseModule(Element module) {
    final nameElement = module.querySelector('.module-name');

    final signElement = module.querySelector('.m-title .title-sign');

    final name = nameElement?.text.trim() ?? '';

    final sign = signElement?.text.trim() ?? '';

    final subModules = _parseDirectSubModules(module);

    debugPrint(
      '一级模块：$name，'
      '二级模块：${subModules.length}',
    );

    return TrainingModule(name: name, sign: sign, subModules: subModules);
  }

  // 递归解析子模块

  /// 解析当前模块的直接子模块。
  ///
  /// 注意：
  ///
  /// 不能直接使用：
  ///
  /// getElementsByClassName('module-tpl depth-3')
  ///
  /// 因为它会查找所有后代节点。
  ///
  /// 这里通过：
  ///
  /// .m-content
  ///   ↓
  /// .c-children
  ///   ↓
  /// children
  ///
  /// 只获取当前层级的直接子模块。
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

  // 递归子模块

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

  // 获取当前模块直接 m-content

  Element? _getDirectContent(Element module) {
    for (final child in module.children) {
      if (child.classes.contains('m-content')) {
        return child;
      }
    }

    return null;
  }

  // 获取当前层级直接 c-children

  Element? _getDirectChildrenContainer(Element content) {
    for (final child in content.children) {
      if (child.classes.contains('c-children')) {
        return child;
      }
    }

    return null;
  }

  // 获取当前层级直接课程表

  Element? _getDirectCourseTable(Element content) {
    for (final child in content.children) {
      if (child.localName == 'table' && child.classes.contains('c-table')) {
        return child;
      }
    }

    return null;
  }

  // 判断模块元素

  bool _isModuleElement(Element element) {
    return element.classes.contains('module-tpl');
  }

  // 课程

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

  // 清理课程名称

  String _getCourseName(Element column) {
    final dataText = column.attributes['data-text'];

    if (dataText != null && dataText.trim().isNotEmpty) {
      return dataText.trim();
    }

    var name = column.text.replaceAll('\u00a0', ' ').trim();

    // 去掉：
    //
    // 1. 课程名称
    // 2. 1. 课程名称
    // 3. 2.课程名称

    name = name.replaceFirst(RegExp(r'^\d+\.\s*'), '');

    return name.trim();
  }
}
