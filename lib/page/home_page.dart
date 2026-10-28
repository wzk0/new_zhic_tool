import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/core/week_utils.dart';
import 'package:new_zhic_tool/page/login_page.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:new_zhic_tool/provider/settings_notifier.dart';
import 'package:new_zhic_tool/widget/class_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key, required this.classWidgetKey});

  final GlobalKey classWidgetKey;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  final List<String> _tabLabels = List.generate(20, (i) => '第${i + 1}周');

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }

    final week = _tabController.index + 1;

    ref.read(scheduleProvider.notifier).selectWeek(week);

    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isLoggedIn = ref.watch(authProvider);

    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            M3EButton(
              onPressed: () async {
                HapticFeedback.lightImpact();

                await _openLoginPage();
              },
              child: const Text('登入账号'),
            ),
          ],
        ),
      );
    }

    final schedule = ref.watch(scheduleProvider);

    final highlightTodayOnly = ref.watch(
      settingsProvider.select((settings) => settings.highlightTodayOnly),
    );

    // 今天所在的周次, 与当前查看的周次无关。
    final todayWeek = currentWeekOf(schedule.currentSemester?.startDate);

    if (schedule.isLoading && schedule.semesters.isEmpty) {
      return const Center(child: M3ELoadingIndicator());
    }

    final currentWeek = schedule.currentWeek;

    if (_tabController.index != currentWeek - 1 &&
        !_tabController.indexIsChanging) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        if (_tabController.index != currentWeek - 1) {
          _tabController.animateTo(currentWeek - 1);
        }
      });
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 13),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: colorScheme.primaryContainer,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorPadding: const EdgeInsets.symmetric(vertical: 1),
            indicatorAnimation: TabIndicatorAnimation.elastic,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            dividerColor: Colors.transparent,
            labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: colorScheme.onPrimaryContainer),
            tabs: _tabLabels.map((label) {
              return Tab(height: 36, child: Text(label));
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),
        Expanded(
          child: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: List.generate(_tabLabels.length, (index) {
                  final weekNumber = index + 1;
                  final courses =
                      schedule.coursesByWeek[weekNumber] ?? const [];

                  final isCurrent = index == _tabController.index;

                  // 开启"仅突出显示当天"后, 只有今天所在的那一周才高亮。
                  final highlightToday =
                      !highlightTodayOnly || weekNumber == todayWeek;

                  return Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: ClassWidget(
                      courses: courses,
                      captureKey: isCurrent ? widget.classWidgetKey : null,
                      currentWeek: weekNumber,
                      semesterStartDate: schedule.currentSemester?.startDate,
                      highlightToday: highlightToday,
                    ),
                  );
                }),
              ),
              if (schedule.isSyncing)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: colorScheme.surface.withValues(alpha: 0.72),
                      child: const Center(child: M3ELoadingIndicator()),
                    ),
                  ),
                ),
              // 开启了"仅突出显示当天"且翻到了非本周时, 提供回到本周的入口。
              Positioned(
                right: 16,
                bottom: 16,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  reverseDuration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.85,
                          end: 1,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child:
                      highlightTodayOnly &&
                          _tabController.index + 1 != todayWeek
                      ? _buildTodayButton(context, todayWeek)
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 回到本周按钮。
  ///
  /// [M3EFab] 的阴影写死无法关闭, 这里用 [M3EButton] 组一个无阴影的浮动按钮。
  Widget _buildTodayButton(BuildContext context, int todayWeek) {
    final colorScheme = Theme.of(context).colorScheme;

    return M3EButton(
      onPressed: () => _jumpToWeek(todayWeek),
      tooltip: '回到本周',
      size: .lg,
      decoration: M3EButtonDecoration(
        backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimaryContainer),
        elevation: const WidgetStatePropertyAll(0),
        fixedSize: const Size(64, 64),
        minimumSize: const Size(64, 64),
        padding: EdgeInsets.zero,
        borderRadius: 20,
      ),
      child: const Icon(Mdi.calendarTodayOutline, size: 28),
    );
  }

  void _jumpToWeek(int week) {
    HapticFeedback.lightImpact();

    _tabController.animateTo((week - 1).clamp(0, _tabLabels.length - 1));
  }

  Future<void> _openLoginPage() async {
    await LoginPage.open(context);
  }
}
