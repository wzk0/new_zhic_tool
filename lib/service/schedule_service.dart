import 'dart:convert';

import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/model/course.dart';
import 'package:new_zhic_tool/model/student_info.dart';
import 'package:new_zhic_tool/service/network_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleData {
  const ScheduleData({
    this.studentInfo = const StudentInfo(),
    this.coursesByWeek = const {},
    this.fromCache = false,
  });

  final StudentInfo studentInfo;

  final Map<int, List<Course>> coursesByWeek;

  /// 是否来自本地缓存。
  final bool fromCache;
}

class ScheduleService {
  ScheduleService({NetworkService? network})
    : _network = network ?? NetworkService.instance;

  final NetworkService _network;

  static const String _baseUrl =
      'https://eams.tjzhic.edu.cn/student/for-std/course-table/semester';

  /// 以后可以把这里替换成用户设置。
  static const Duration scheduleTimeout = Duration(seconds: 8);

  static const String _cachePrefix = 'schedule_cache_';

  /// 获取指定学期课表。
  ///
  /// 优先联网：
  ///
  /// 1. 网络请求成功 → 使用最新数据并保存缓存
  /// 2. 网络请求失败 / 超时 → 使用本地缓存
  /// 3. 没有缓存 → 抛出原始异常
  Future<ScheduleData> fetchSchedule({
    required String semesterId,
    Duration? timeout,
  }) async {
    final url = '$_baseUrl/$semesterId/print-data';

    final requestTimeout = timeout ?? scheduleTimeout;

    debugShow('开始获取学期 $semesterId 课程');

    try {
      final data = await _network.get(
        url,
        queryParameters: {'semesterId': semesterId, 'hasExperiment': 'true'},
        timeout: requestTimeout,
        withCookies: true,
      );

      debugShow('学期 $semesterId 网络课表获取成功');

      // 网络成功后立即保存原始 JSON。
      await _saveCache(semesterId, data);

      debugShow('学期 $semesterId 课表缓存保存成功');

      return _parseSchedule(data, fromCache: false);
    } catch (e, stackTrace) {
      debugShow('学期 $semesterId 网络获取失败: $e');

      debugShow(stackTrace.toString());

      // 网络失败以后尝试读取缓存。
      final cachedData = await _loadCache(semesterId);

      if (cachedData != null) {
        debugShow('学期 $semesterId 使用本地缓存');

        return _parseSchedule(cachedData, fromCache: true);
      }

      debugShow('学期 $semesterId 没有可用缓存');

      // 没有缓存，继续抛出原始网络异常。
      rethrow;
    }
  }

  /// 保存服务器返回的原始 JSON。
  Future<void> _saveCache(String semesterId, dynamic data) async {
    if (data is! Map<String, dynamic>) {
      debugShow('缓存跳过：服务器数据不是 JSON Object');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final key = _cacheKey(semesterId);

      final jsonString = jsonEncode(data);

      await prefs.setString(key, jsonString);

      debugShow('课表缓存写入成功: $key');
    } catch (e, stackTrace) {
      // 缓存失败不能影响正常显示课表。
      debugShow('课表缓存保存失败: $e');

      debugShow(stackTrace.toString());
    }
  }

  /// 读取指定学期缓存。
  Future<dynamic> _loadCache(String semesterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final key = _cacheKey(semesterId);

      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final data = jsonDecode(jsonString);

      if (data is! Map<String, dynamic>) {
        debugShow('缓存数据格式错误: $key');
        return null;
      }

      return data;
    } catch (e, stackTrace) {
      debugShow('读取课表缓存失败: $e');

      debugShow(stackTrace.toString());

      return null;
    }
  }

  String _cacheKey(String semesterId) {
    return '$_cachePrefix$semesterId';
  }

  ScheduleData _parseSchedule(dynamic data, {required bool fromCache}) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('课表数据格式错误：根节点不是 JSON Object');
    }

    final studentTableVms = data['studentTableVms'];

    if (studentTableVms is! List || studentTableVms.isEmpty) {
      debugShow('课表数据中没有 studentTableVms');

      return ScheduleData(fromCache: fromCache);
    }

    final student = studentTableVms.first;

    if (student is! Map) {
      throw const FormatException('studentTableVms 数据格式错误');
    }

    final studentMap = Map<String, dynamic>.from(student);

    final studentInfo = StudentInfo.fromJson(studentMap);

    final activities = studentMap['activities'];

    if (activities is! List) {
      debugShow('课表数据中没有 activities');

      return ScheduleData(studentInfo: studentInfo, fromCache: fromCache);
    }

    final coursesByWeek = <int, List<Course>>{};

    for (var week = 1; week <= 20; week++) {
      coursesByWeek[week] = [];
    }

    for (final activity in activities) {
      if (activity is! Map) {
        continue;
      }

      final weekIndexes = activity['weekIndexes'];

      if (weekIndexes is! List) {
        continue;
      }

      final weeks = weekIndexes
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .where((week) => week >= 1 && week <= 20)
          .toSet();

      if (weeks.isEmpty) {
        continue;
      }

      try {
        final course = Course.fromJson(Map<String, dynamic>.from(activity));

        final normalized = course.normalized();

        if (normalized == null) {
          continue;
        }

        for (final week in weeks) {
          coursesByWeek[week]!.add(normalized);
        }
      } catch (e, stackTrace) {
        debugShow('解析单节课程失败: $e');

        debugShow(stackTrace.toString());
      }
    }

    for (final entry in coursesByWeek.entries) {
      debugShow(
        '第 ${entry.key} 周，共 '
        '${entry.value.length} 节课程'
        '${fromCache ? '（缓存）' : ''}',
      );
    }

    debugShow(
      '学生信息: '
      'name=${studentInfo.name}, '
      'code=${studentInfo.code}, '
      'department=${studentInfo.department}, '
      'adminClass=${studentInfo.adminClass}',
    );

    return ScheduleData(
      studentInfo: studentInfo,
      coursesByWeek: coursesByWeek,
      fromCache: fromCache,
    );
  }
}
