import 'dart:convert';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/model/semester_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _remoteUrl =
      'https://gitee.com/thdbd/zhanghuan_data/raw/main/semester.json';

  static const String _cacheKey = 'semester_configs_cache';
  static const String _selectedSemesterKey = 'selected_semester_id';
  Future<List<SemesterConfig>> fetchConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          throw const FormatException('学期配置格式错误');
        }
        final configs = decoded
            .whereType<Map>()
            .map(
              (item) =>
                  SemesterConfig.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((item) => item.id.isNotEmpty && item.startDate.isNotEmpty)
            .toList();
        if (configs.isEmpty) {
          throw const FormatException('没有有效的学期配置');
        }
        await prefs.setString(_cacheKey, response.body);
        debugShow('获取学期配置成功, 共 ${configs.length} 个学期');
        return configs;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e, stackTrace) {
      debugShow('远程学期配置获取失败: $e');
      debugShow(stackTrace.toString());
      Fluttertoast.showToast(msg: '学期配置获取失败, 正在使用本地缓存');
    }
    final cachedData = prefs.getString(_cacheKey);
    if (cachedData != null && cachedData.isNotEmpty) {
      try {
        final decoded = jsonDecode(cachedData);
        if (decoded is List) {
          final configs = decoded
              .whereType<Map>()
              .map(
                (item) =>
                    SemesterConfig.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.id.isNotEmpty && item.startDate.isNotEmpty)
              .toList();
          if (configs.isNotEmpty) {
            debugShow(
              '从本地缓存恢复学期配置, '
              '共 ${configs.length} 个学期',
            );
            return configs;
          }
        }
      } catch (e, stackTrace) {
        debugShow('学期配置缓存解析失败: $e');
        debugShow(stackTrace.toString());
      }
    }
    debugShow('使用内置学期配置');
    return _fallbackConfigs;
  }

  Future<bool> saveSelectedSemester(String semesterId) async {
    final prefs = await SharedPreferences.getInstance();
    final result = await prefs.setString(_selectedSemesterKey, semesterId);
    debugShow(
      '保存当前学期: '
      '$semesterId, result=$result',
    );
    return result;
  }

  Future<String?> getSelectedSemesterId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedSemesterKey);
    debugShow('读取保存的学期: $id');
    return id;
  }

  static const List<SemesterConfig> _fallbackConfigs = [
    SemesterConfig(name: '2026-2027-1 上学期', id: '84', startDate: '2026-09-07'),
    SemesterConfig(name: '2025-2026-2 下学期', id: '83', startDate: '2026-03-09'),
    SemesterConfig(name: '2025-2026-1 上学期', id: '82', startDate: '2025-09-08'),
    SemesterConfig(name: '2024-2025-2 下学期', id: '81', startDate: '2025-03-03'),
    SemesterConfig(name: '2024-2025-1 上学期', id: '61', startDate: '2024-09-02'),
    SemesterConfig(name: '2023-2024-2 下学期', id: '42', startDate: '2024-03-04'),
    SemesterConfig(name: '2023-2024-1 上学期', id: '41', startDate: '2023-09-04'),
  ];
}
