import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/course.dart';
import 'package:new_zhic_tool/widget/bottomsheet_widget.dart';

class ClassWidget extends StatelessWidget {
  const ClassWidget({
    super.key,
    this.courses = const [],
    this.captureKey,
    this.currentWeek = 1,
    this.semesterStartDate,
  });

  final List<Course> courses;

  final GlobalKey? captureKey;

  final int currentWeek;

  final String? semesterStartDate;

  static const int totalUnits = 12;

  static const List<String> weekDays = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static const List<String> times = [
    '08:00',
    '09:25',
    '09:50',
    '11:15',
    '12:00',
    '13:30',
    '14:55',
    '15:05',
    '16:30',
    '17:15',
    '18:00',
    '19:25',
  ];

  Future<ui.Image> capture({double pixelRatio = 3.0}) async {
    final context = captureKey?.currentContext;

    if (context == null) {
      throw StateError('ClassWidget 尚未完成渲染, 无法截图.');
    }

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('captureKey 没有绑定到 RenderRepaintBoundary.');
    }

    return renderObject.toImage(pixelRatio: pixelRatio);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = _getMondayForWeek(now);

    final validCourses = courses
        .map((course) => course.normalized(totalUnits: totalUnits))
        .whereType<Course>()
        .toList();

    final todayWeekday = now.weekday;

    final content = SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeColumn(context, now: now),

          const SizedBox(width: 4),

          for (int i = 0; i < 7; i++)
            Expanded(
              child: _buildDayColumn(
                context,
                weekday: i + 1,
                date: monday.add(Duration(days: i)),
                courses: validCourses,
                isToday: (i + 1) == todayWeekday,
              ),
            ),
        ],
      ),
    );

    if (captureKey != null) {
      return RepaintBoundary(key: captureKey, child: content);
    }

    return content;
  }

  DateTime _getMondayForWeek(DateTime now) {
    if (semesterStartDate != null && semesterStartDate!.isNotEmpty) {
      try {
        final start = DateTime.parse(semesterStartDate!);
        final startDay = DateTime(start.year, start.month, start.day);

        final int daysToSubtract = startDay.weekday - 1;
        final baseMonday = startDay.subtract(Duration(days: daysToSubtract));

        final targetMonday = baseMonday.add(
          Duration(days: (currentWeek - 1) * 7),
        );
        return targetMonday;
      } catch (e) {
        debugShow('解析学期开始日期失败: $e');
      }
    }

    final day = DateTime(now.year, now.month, now.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  int? _getCurrentUnit(DateTime now) {
    final currentMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i < times.length; i++) {
      final start = _parseTime(times[i]);

      final startMinutes = start.hour * 60 + start.minute;

      final endMinutes = i + 1 < times.length
          ? _parseTime(times[i + 1]).hour * 60 + _parseTime(times[i + 1]).minute
          : 24 * 60;

      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        return i + 1;
      }
    }

    return null;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');

    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Widget _buildTimeColumn(BuildContext context, {required DateTime now}) {
    final colorScheme = Theme.of(context).colorScheme;

    final currentUnit = _getCurrentUnit(now);

    return SizedBox(
      width: 32,
      child: Column(
        children: [
          const SizedBox(height: 38),

          Expanded(
            child: Column(
              children: List.generate(totalUnits, (index) {
                final unit = index + 1;
                final isCurrent = unit == currentUnit;

                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        isCurrent
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  borderRadius: .all(.circular(6)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    right: 4,
                                    top: 1,
                                    bottom: 1,
                                  ),
                                  child: Text(
                                    unit.toString(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isCurrent
                                              ? colorScheme.tertiary
                                              : colorScheme.primary,
                                          fontWeight: isCurrent
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                  ),
                                ),
                              )
                            : Text(
                                unit.toString(),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isCurrent
                                          ? colorScheme.tertiary
                                          : colorScheme.primary,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                        Text(
                          times[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrent
                                ? colorScheme.tertiary
                                : colorScheme.outline,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context, {
    required int weekday,
    required DateTime date,
    required List<Course> courses,
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final dayCourses =
        courses.where((course) => course.weekday == weekday).toList()
          ..sort((a, b) {
            final result = a.startUnit.compareTo(b.startUnit);

            if (result != 0) {
              return result;
            }

            return b.endUnit.compareTo(a.endUnit);
          });

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isToday
                  ? Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: .all(.circular(6)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          right: 4,
                          top: 1,
                          bottom: 1,
                        ),
                        child: Text(
                          weekDays[weekday - 1],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isToday
                                    ? colorScheme.tertiary
                                    : colorScheme.primary,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                    )
                  : Text(
                      weekDays[weekday - 1],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isToday
                            ? colorScheme.tertiary
                            : colorScheme.primary,
                      ),
                    ),
              Text(
                '${date.month}/${date.day}',
                style: TextStyle(
                  color: isToday ? colorScheme.tertiary : colorScheme.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        Expanded(
          child: _buildCourseColumn(
            context,
            courses: dayCourses,
            isToday: isToday,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseColumn(
    BuildContext context, {
    required List<Course> courses,
    required bool isToday,
  }) {
    final children = <Widget>[];

    int currentUnit = 1;

    for (final course in courses) {
      final start = course.startUnit;
      final end = course.endUnit;

      if (start > totalUnits) {
        continue;
      }

      if (start < currentUnit) {
        continue;
      }

      if (start > currentUnit) {
        children.add(
          Expanded(flex: start - currentUnit, child: const SizedBox()),
        );
      }

      children.add(
        Expanded(
          flex: end - start + 1,
          child: _buildCourseCard(context, course, isToday: isToday),
        ),
      );

      currentUnit = end + 1;
    }

    if (currentUnit <= totalUnits) {
      children.add(
        Expanded(flex: totalUnits - currentUnit + 1, child: const SizedBox()),
      );
    }

    return Column(children: children);
  }

  Widget _buildCourseCard(
    BuildContext context,
    Course course, {
    required bool isToday,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = isToday
        ? colorScheme.tertiaryContainer
        : colorScheme.primaryContainer;

    final roomColor = isToday ? colorScheme.tertiary : colorScheme.primary;

    final titleColor = isToday
        ? colorScheme.onTertiaryContainer
        : colorScheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: M3ESegmentedItem(
        index: 0,
        position: .single,
        outerRadius: 10,
        innerRadius: 10,
        gap: 0,
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        color: backgroundColor,
        onTap: (_) {
          showM3EModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (context) => M3EBottomSheet(
              title: Text(course.name),
              actions: [
                M3EButton(
                  style: M3EButtonStyle.text,
                  shape: M3EButtonShape.round,
                  size: M3EButtonSize.sm,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Mdi.close),
                ),
              ],
              child: BottomsheetWidget(
                items: [
                  {'icon': Mdi.codeBraces, 'name': course.id, 'value': '课程代码'},
                  {
                    'icon': Mdi.tournament,
                    'name': course.name,
                    'value': '课程名称',
                  },
                  {
                    'icon': Mdi.formatListBulletedType,
                    'name': course.classType,
                    'value': '课程类型',
                  },
                  {
                    'icon': Mdi.hoopHouse,
                    'name': course.building,
                    'value': '所在楼宇',
                  },
                  {'icon': Mdi.sofaOutline, 'name': course.room, 'value': '教室'},
                  {
                    'icon': Mdi.humanMaleBoardPoll,
                    'name': course.teachers.join(', '),
                    'value': '授课老师',
                  },
                  {
                    'icon': Mdi.decagramOutline,
                    'name': '${course.credits.toString()}分',
                    'value': '课程学分',
                  },
                  {
                    'icon': Mdi.battery,
                    'name':
                        '第${course.startUnit.toString()}节 · ${course.startTime}',
                    'value': '上课时间',
                  },
                  {
                    'icon': Mdi.battery10,
                    'name':
                        '第${course.endUnit.toString()}节 · ${course.endTime}',
                    'value': '下课时间',
                  },
                ],
              ),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Text(
                course.name,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: titleColor),
              ),
              Text(
                course.room,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: roomColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
