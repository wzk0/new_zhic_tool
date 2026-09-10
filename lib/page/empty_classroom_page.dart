import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/empty_room.dart';
import 'package:new_zhic_tool/page/room_detail_page.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/empty_room_provider.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:new_zhic_tool/widget/empty_page.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';

class EmptyClassroomPage extends ConsumerStatefulWidget {
  const EmptyClassroomPage({super.key});

  @override
  ConsumerState<EmptyClassroomPage> createState() => _EmptyClassroomPageState();
}

class _EmptyClassroomPageState extends ConsumerState<EmptyClassroomPage> {
  final M3EDropdownController<String> _dropdownController =
      M3EDropdownController<String>();
  final Set<String> _selectedRoomIds = {};
  List<M3EDropdownItem<String>> _dropdownItems = const [];
  String _roomItemsSignature = '';
  bool _selectionUpdateScheduled = false;

  @override
  void dispose() {
    _dropdownController.dispose();
    super.dispose();
  }

  String _roomValue(EmptyRoom room) {
    return room.id?.toString() ?? room.roomName;
  }

  void _updateDropdownItems(List<EmptyRoom> rooms) {
    final signature = rooms
        .map((room) => '${_roomValue(room)}:${room.roomName}')
        .join('|');

    if (signature == _roomItemsSignature) return;

    _roomItemsSignature = signature;
    _dropdownItems = rooms.map((room) {
      final value = _roomValue(room);
      return M3EDropdownItem<String>(
        label: room.roomName,
        value: value,
        selected: _selectedRoomIds.contains(value),
      );
    }).toList();
  }

  void _handleSelectionChanged(List<M3EDropdownItem<String>> selectedItems) {
    final selectedValues = selectedItems.map((item) => item.value).toSet();

    if (_selectedRoomIds.length == selectedValues.length &&
        _selectedRoomIds.containsAll(selectedValues)) {
      return;
    }

    if (_selectionUpdateScheduled) return;
    _selectionUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionUpdateScheduled = false;
      if (!mounted) return;

      if (_selectedRoomIds.length == selectedValues.length &&
          _selectedRoomIds.containsAll(selectedValues)) {
        return;
      }

      setState(() {
        _selectedRoomIds
          ..clear()
          ..addAll(selectedValues);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('空教室')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ErrorPage(text: '当前未登入，请先登入账号', icon: Mdi.accountAlertOutline),
              ],
            ),
          ),
        ),
      );
    }

    final schedule = ref.watch(scheduleProvider);
    final semesterId = schedule.currentSemester?.id;
    final week = schedule.currentWeek;

    if (semesterId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('空教室')),
        body: EmptyPage(text: '暂无学期信息', icon: Mdi.calendarRangeOutline),
      );
    }

    final query = EmptyRoomQuery(week: week, semesterId: semesterId);
    final roomsAsync = ref.watch(emptyRoomProvider(query));

    return Scaffold(
      appBar: AppBar(title: const Text('空教室')),
      body: roomsAsync.when(
        loading: () =>
            const LoadPage(text: '尝试获取数据中,\n如果加载时间长, 请尝试重新登录', ifok: true),
        error: (error, stackTrace) =>
            ErrorPage(text: error.toString(), icon: Mdi.cloudOffOutline),
        data: (rooms) => _buildContent(context, query, rooms),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EmptyRoomQuery query,
    List<EmptyRoom> rooms,
  ) {
    _updateDropdownItems(rooms);

    final selectedRooms = rooms.where((room) {
      final val = _roomValue(room);
      return _selectedRoomIds.contains(val) ||
          (room.id != null && _selectedRoomIds.contains(room.id.toString())) ||
          _selectedRoomIds.contains(room.roomName);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: M3EDropdownMenu<String>(
            fieldStyle: M3EDropdownFieldStyle(hintText: '选择或搜索教室'),
            dropdownStyle: M3EDropdownStyle(noItemsFoundText: '未找到教室'),
            searchStyle: M3ESearchStyle(hintText: '搜索教室名称'),
            controller: _dropdownController,
            items: _dropdownItems,
            searchEnabled: true,
            singleSelect: false,
            showChipAnimation: true,
            onSelectionChanged: _handleSelectionChanged,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: selectedRooms.isEmpty
                ? KeyedSubtree(
                    key: const ValueKey('empty'),
                    child: _buildEmptySelection(context),
                  )
                : KeyedSubtree(
                    key: const ValueKey('list'),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: selectedRooms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final room = selectedRooms[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                            milliseconds: 250 + (index * 40).clamp(0, 200),
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(opacity: value, child: child),
                            );
                          },
                          child: RoomOccupationCard(
                            room: room,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RoomDetailPage(room: room),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Mdi.sofaOutline, size: 42, color: colorScheme.outline),
                const SizedBox(height: 6),
                Text(
                  '请选择要查看的教室',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                Text(
                  '可选择多个教室',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RoomOccupationCard extends StatelessWidget {
  const RoomOccupationCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  final EmptyRoom room;
  final VoidCallback onTap;

  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return M3ESegmentedItem(
      elevation: 0,
      index: 1,
      position: .first,
      outerRadius: 20,
      innerRadius: 20,
      onTap: (_) => onTap(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            _buildHeader(context, colorScheme),
            const SizedBox(height: 16),
            _buildOccupationTable(context, colorScheme),
            const SizedBox(height: 12),
            _buildLegend(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          child: Text(
            formatRoomName(room.roomName),
            style: textTheme.labelSmall,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.roomName, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                '${room.buildingName} · 可容纳${room.seats}人',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Icon(Mdi.chevronRight, color: colorScheme.outline),
      ],
    );
  }

  String formatRoomName(String originalName) {
    String name = originalName
        .replaceAll('室', '')
        .replaceAll('号乒乓球台', '乒乓')
        .replaceAll('学生活动中心', '活动')
        .replaceAll('号羽毛球场', '羽毛')
        .replaceAll('学生体质健康测试时间预约（操场单杠处）', '体测')
        .replaceAll('公共机房', '')
        .replaceAll('提交作品', '提交')
        .replaceAll('线上教学', '线上');
    final match = RegExp(r'^(?:\d{4}|\d{2}[a-zA-Z]\d)').firstMatch(name);
    if (match != null) {
      return match.group(0)!;
    }
    return name;
  }

  Widget _buildOccupationTable(BuildContext context, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Table(
      columnWidths: const {0: FixedColumnWidth(22)},
      children: [
        TableRow(
          children: [
            const SizedBox(),
            ..._weekdays.map((day) {
              return Center(
                child: Text(
                  '周$day',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              );
            }),
          ],
        ),
        ...List.generate(12, (unitIndex) {
          final unit = unitIndex + 1;
          return TableRow(
            children: [
              SizedBox(
                height: 27,
                child: Center(
                  child: Text(
                    unit.toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ),
              ),
              ...List.generate(7, (weekdayIndex) {
                final weekday = weekdayIndex + 1;
                final occupation = room.occupations.any((occupation) {
                  return occupation.weekday == weekday &&
                      occupation.unit == unit &&
                      occupation.isBusy;
                });

                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    height: 23,
                    decoration: BoxDecoration(
                      color: occupation
                          ? colorScheme.errorContainer
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(child: Text(occupation ? '' : '✅')),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, ColorScheme colorScheme) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LegendItem(colorSchemeKey: true, label: '空闲'), // 内部处理类型分发
        SizedBox(width: 24),
        LegendItem(colorSchemeKey: false, label: '占用'),
      ],
    );
  }
}

class LegendItem extends StatelessWidget {
  const LegendItem({
    super.key,
    required this.colorSchemeKey,
    required this.label,
  });

  final bool colorSchemeKey;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorSchemeKey
        ? colorScheme.tertiaryContainer
        : colorScheme.errorContainer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
