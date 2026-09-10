import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/semester_config.dart';
import 'package:new_zhic_tool/page/about_page.dart';
import 'package:new_zhic_tool/page/calendar_page.dart';
import 'package:new_zhic_tool/page/course_selection_page.dart';
import 'package:new_zhic_tool/page/empty_classroom_page.dart';
import 'package:new_zhic_tool/page/evaluation_page.dart';
import 'package:new_zhic_tool/page/exam_page.dart';
import 'package:new_zhic_tool/page/help_page.dart';
import 'package:new_zhic_tool/page/leave_page.dart';
import 'package:new_zhic_tool/page/library_page.dart';
import 'package:new_zhic_tool/page/neea_page.dart';
import 'package:new_zhic_tool/page/question_bank_page.dart';
import 'package:new_zhic_tool/page/score_page.dart';
import 'package:new_zhic_tool/page/training_plan_page.dart';
import 'package:new_zhic_tool/page/xuexinwang_page.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawerItemConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? targetPage;

  const DrawerItemConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.targetPage,
  });
}

class DrawerWidget extends ConsumerStatefulWidget {
  const DrawerWidget({super.key});

  @override
  ConsumerState<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends ConsumerState<DrawerWidget>
    with SingleTickerProviderStateMixin {
  late final M3EDropdownController<String> _semesterController;
  late AnimationController _animationController;
  bool _syncingDropdown = false;

  List<SemesterConfig> _dropdownSemesters = const [];
  int _clickCount = 0;
  bool _isLoggedInCache = false;

  static const String _kPrefsClickCount = 'drawer_avatar_click_count';
  static const String _kPrefsAnimationValue = 'drawer_avatar_animation_value';

  final List<List<DrawerItemConfig>> _menuGroups = const [
    [
      DrawerItemConfig(
        icon: Mdi.homeOutline,
        title: '首页',
        subtitle: '查询所选学期课表',
        targetPage: null,
      ),
      DrawerItemConfig(
        icon: Mdi.sproutOutline,
        title: '培养方案',
        subtitle: '查询个人培养方案',
        targetPage: TrainingPlanPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.flaskEmptyOutline,
        title: '空教室',
        subtitle: '查询空闲教室',
        targetPage: EmptyClassroomPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.starFourPointsOutline,
        title: '成绩',
        subtitle: '查询成绩信息',
        targetPage: ScorePage(),
      ),
      DrawerItemConfig(
        icon: Mdi.receiptTextEditOutline,
        title: '考试',
        subtitle: '查询考试安排',
        targetPage: ExamPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.brain,
        title: '题库',
        subtitle: '查询共享的期末题库',
        targetPage: QuestionBankPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.calendarRangeOutline,
        title: '校历',
        subtitle: '查询中环校历',
        targetPage: CalendarPage(),
      ),
    ],
    [
      DrawerItemConfig(
        icon: Mdi.libraryOutline,
        title: '图书馆',
        subtitle: '在线查询校图书馆信息',
        targetPage: LibraryPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.chairSchool,
        title: '选课',
        subtitle: '在线选课',
        targetPage: CourseSelectionPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.commentEditOutline,
        title: '评教',
        subtitle: '在线评教',
        targetPage: EvaluationPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.bedOutline,
        title: '请假',
        subtitle: '在线智慧宿舍请假',
        targetPage: LeavePage(),
      ),
      DrawerItemConfig(
        icon: Mdi.schoolOutline,
        title: '学信网',
        subtitle: '在线查看学信网',
        targetPage: XuexinwangPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.textSearch,
        title: '教育考试查询',
        subtitle: '在线查看四六级等考试成绩',
        targetPage: NeeaPage(),
      ),
    ],
    [
      DrawerItemConfig(
        icon: Mdi.helpCircleOutline,
        title: '帮助',
        subtitle: '使用帮助',
        targetPage: HelpPage(),
      ),
      DrawerItemConfig(
        icon: Mdi.informationOutline,
        title: '关于',
        subtitle: '关于掌环',
        targetPage: AboutPage(),
      ),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this);
    _semesterController = M3EDropdownController<String>();

    _loadSavedState();
    _checkLoginStatus();

    ref.listenManual<ScheduleState>(scheduleProvider, (previous, next) {
      _checkLoginStatus();
      final previousSemesters = previous?.semesters ?? const [];
      final currentSemesters = next.semesters;
      final previousId = previous?.currentSemester?.id;
      final currentId = next.currentSemester?.id;
      final semestersChanged =
          _semesterIds(previousSemesters) != _semesterIds(currentSemesters);
      final selectedSemesterChanged = previousId != currentId;
      if (!semestersChanged && !selectedSemesterChanged) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncDropdown(semesters: currentSemesters, selectedId: currentId);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final schedule = ref.read(scheduleProvider);
      _syncDropdown(
        semesters: schedule.semesters,
        selectedId: schedule.currentSemester?.id,
      );
    });
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt(_kPrefsClickCount) ?? 0;
      final savedValue = prefs.getDouble(_kPrefsAnimationValue) ?? 0.0;
      if (savedCount > 0 && mounted) {
        setState(() {
          _clickCount = savedCount;
        });
        final durationMs = (15000 / _clickCount).clamp(30, 15000).toInt();
        _animationController.duration = Duration(milliseconds: durationMs);
        _animationController.value = savedValue.clamp(0.0, 1.0);
        _animationController.repeat();
      }
    } catch (_) {}
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPrefsClickCount, _clickCount);
      await prefs.setDouble(_kPrefsAnimationValue, _animationController.value);
    } catch (_) {}
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool('is_logged_in') ?? false;
      if (mounted && _isLoggedInCache != loggedIn) {
        setState(() {
          _isLoggedInCache = loggedIn;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveState();
    _semesterController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _semesterIds(List<SemesterConfig> semesters) {
    return semesters.map((e) => e.id).join('|');
  }

  void _syncDropdown({
    required List<SemesterConfig> semesters,
    required String? selectedId,
  }) {
    if (!mounted) return;
    if (semesters.isEmpty) return;

    final newIds = _semesterIds(semesters);
    final oldIds = _semesterIds(_dropdownSemesters);
    final itemsChanged = newIds != oldIds;

    _syncingDropdown = true;
    try {
      if (itemsChanged) {
        final items = semesters
            .map(
              (semester) => M3EDropdownItem<String>(
                label: semester.name,
                value: semester.id,
              ),
            )
            .toList();
        _semesterController.setItems(items);
        _dropdownSemesters = List<SemesterConfig>.from(semesters);
      }

      if (selectedId == null || selectedId.isEmpty) return;

      final selectedValues = _semesterController.selectedValues;
      if (selectedValues.length == 1 && selectedValues.first == selectedId) {
        return;
      }

      _semesterController.clearAll();
      _semesterController.selectWhere((item) => item.value == selectedId);
    } finally {
      _syncingDropdown = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    _checkLoginStatus();

    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top),
            _buildSemesterDropdown(context, ref, schedule),
            const SizedBox(height: 16),
            _buildAvatar(context, schedule),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildPart(context, _menuGroups[0]),
                  const SizedBox(height: 15),
                  _buildPart(context, _menuGroups[1]),
                  const SizedBox(height: 15),
                  _buildPart(context, _menuGroups[2]),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterDropdown(
    BuildContext context,
    WidgetRef ref,
    ScheduleState schedule,
  ) {
    if (schedule.isLoading && schedule.semesters.isEmpty) {
      return const SizedBox(
        height: 48,
        child: Center(child: M3ELoadingIndicator()),
      );
    }

    if (schedule.semesters.isEmpty) {
      return M3ESegmentedItem(
        index: 0,
        position: .first,
        outerRadius: 12,
        innerRadius: 12,
        gap: .minPositive,
        child: Row(
          spacing: 13,
          children: [
            const M3ELoadingIndicator(),
            Text(
              '暂无学期配置, 请尝试登入',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      );
    }

    return M3EDropdownMenu<String>(
      controller: _semesterController,
      items: _semesterController.items,
      singleSelect: true,
      fieldStyle: M3EDropdownFieldStyle(
        hintText: '选择学期',
        borderRadius: BorderRadius.circular(18),
        selectedBorderRadius: 28,
        hoverRadius: 16,
        pressedRadius: 8,
      ),
      itemStyle: M3EDropdownItemStyle(
        textStyle: Theme.of(context).textTheme.titleSmall,
        selectedTextStyle: Theme.of(context).textTheme.titleSmall,
      ),
      onSelectionChanged: (items) {
        if (_syncingDropdown || items.isEmpty) return;

        final selectedId = items.first.value;
        final selectedSemester = schedule.semesters
            .where((semester) => semester.id == selectedId)
            .firstOrNull;

        if (selectedSemester == null) return;

        debugShow(
          'Drawer 选择学期: '
          '${selectedSemester.name} '
          '(id=${selectedSemester.id})',
        );

        Future.microtask(() {
          if (!mounted) return;
          final currentSchedule = ref.read(scheduleProvider);
          final currentSemester = currentSchedule.semesters
              .where((semester) => semester.id == selectedId)
              .firstOrNull;

          if (currentSemester == null) return;
          if (currentSchedule.currentSemester?.id == currentSemester.id) return;

          ref.read(scheduleProvider.notifier).selectSemester(currentSemester);
        });
      },
    );
  }

  Widget _buildAvatar(BuildContext context, ScheduleState schedule) {
    final student = schedule.studentInfo;
    final bool hasValidStudent =
        _isLoggedInCache &&
        student.name.trim().isNotEmpty &&
        student.name != '未登入';

    final name = hasValidStudent
        ? student.name
        : schedule.isSyncing
        ? '同步中...'
        : '未登入';

    final avatarWidget = CircleAvatar(
      radius: 25,
      child: Text(
        hasValidStudent ? student.avatarText : '?',
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontWeight: .bold),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _clickCount++;
            });
            final durationMs = (15000 / _clickCount).clamp(30, 15000).toInt();
            _animationController.duration = Duration(milliseconds: durationMs);
            _animationController.repeat();
            _clickCount < 500
                ? Fluttertoast.showToast(
                    msg: '当前旋转等级: $_clickCount (${durationMs}ms/圈)',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  )
                : Fluttertoast.showToast(
                    msg: '当前旋转等级: $_clickCount (已达极限)',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
            _saveState();
          },
          onLongPress: () async {
            HapticFeedback.heavyImpact();
            setState(() {
              _clickCount = 0;
            });
            _animationController.stop();
            await _saveState();
            if (!context.mounted) return;

            Fluttertoast.showToast(
              msg: '已停止旋转!',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
            Confetti.launch(
              context,
              options: const ConfettiOptions(
                particleCount: 150,
                spread: 70,
                y: 0.7,
              ),
            );
          },
          child: _clickCount > 0
              ? RotationTransition(
                  turns: _animationController,
                  child: avatarWidget,
                )
              : avatarWidget,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 3,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                if (hasValidStudent && student.department.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 5,
                        right: 5,
                        top: 1,
                        bottom: 1,
                      ),
                      child: Text(
                        student.department,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasValidStudent) ...[
              const SizedBox(height: 4),
              Row(
                spacing: 3,
                children: [
                  if (student.adminClass.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 5,
                          right: 5,
                          top: 1,
                          bottom: 1,
                        ),
                        child: Text(
                          student.adminClass,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  if (student.code.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 5,
                          right: 5,
                          top: 1,
                          bottom: 1,
                        ),
                        child: Text(
                          student.code,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPart(BuildContext context, List<DrawerItemConfig> items) {
    return M3ESegmentedList(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildItemWidget(context, item.icon, item.title, item.subtitle),
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(
                Mdi.chevronRight,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        );
      },
      onTap: (index) {
        final targetPage = items[index].targetPage;
        if (targetPage == null) {
          Navigator.of(context).pop();
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

        Navigator.of(context).pop();
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => targetPage));
      },
    );
  }

  Widget _buildItemWidget(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(icon),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
