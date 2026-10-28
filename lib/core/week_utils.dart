import 'package:new_zhic_tool/core/debug.dart';

/// 根据学期开始日期计算 [now] 所在的周次(从 1 开始, 上限 [maxWeek])。
///
/// 与"当前正在查看的周次"无关, 用于判断今天落在第几周。
int currentWeekOf(String? startDate, {DateTime? now, int maxWeek = 20}) {
  if (startDate == null || startDate.isEmpty) {
    return 1;
  }

  try {
    final start = DateTime.parse(startDate);
    final today = now ?? DateTime.now();
    final startDay = DateTime(start.year, start.month, start.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final difference = todayDay.difference(startDay).inDays;

    if (difference < 0) {
      return 1;
    }

    return (difference ~/ 7 + 1).clamp(1, maxWeek);
  } catch (e) {
    debugShow('计算当前周失败: $e');
    return 1;
  }
}
