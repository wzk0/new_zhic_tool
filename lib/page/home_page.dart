import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/page/login_page.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
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

                  return Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: ClassWidget(
                      courses: courses,
                      captureKey: isCurrent ? widget.classWidgetKey : null,
                      currentWeek: weekNumber,
                      semesterStartDate: schedule.currentSemester?.startDate,
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
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openLoginPage() async {
    await LoginPage.open(context);
  }
}
