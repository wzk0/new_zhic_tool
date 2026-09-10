import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/training.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/training_provider.dart';
import 'package:new_zhic_tool/widget/bottomsheet_widget.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';

class TrainingSearchPage extends ConsumerStatefulWidget {
  const TrainingSearchPage({super.key});

  @override
  ConsumerState<TrainingSearchPage> createState() => _TrainingSearchPageState();
}

class _TrainingSearchPageState extends ConsumerState<TrainingSearchPage> {
  final M3EDropdownController<String> _dropdownController =
      M3EDropdownController<String>();

  final Set<String> _selectedCourseValues = {};

  List<M3EDropdownItem<String>> _dropdownItems = const [];

  List<_TrainingSearchResult> _searchResults = const [];

  String _trainingItemsSignature = '';

  bool _selectionUpdateScheduled = false;

  @override
  void dispose() {
    _dropdownController.dispose();
    super.dispose();
  }

  void _updateDropdownItems(List<TrainingModule> trainings) {
    final results = <_TrainingSearchResult>[];

    for (final module in trainings) {
      for (final subModule in module.subModules) {
        _collectCourses(module: module, subModule: subModule, results: results);
      }
    }

    final signature = results
        .map(
          (result) =>
              '${result.course.code}:'
              '${result.course.name}:'
              '${result.module.name}:'
              '${result.subModule.name}:'
              '${result.course.semester}',
        )
        .join('|');

    if (signature == _trainingItemsSignature) {
      return;
    }

    _trainingItemsSignature = signature;

    _dropdownItems = results.map((result) {
      final course = result.course;
      final value = _resultValue(result);

      final searchLabel = [
        course.name,
        '代码 ${course.code}',
        '性质 ${course.nature}',
        '学期 ${course.semester}',
        '状态 ${course.status}',
        '模块 ${result.module.name}',
        '分类 ${result.subModule.name}',
      ].where((item) => item.trim().isNotEmpty).join(' · ');

      return M3EDropdownItem<String>(
        label: searchLabel,
        value: value,
        selected: _selectedCourseValues.contains(value),
      );
    }).toList();
  }

  void _collectCourses({
    required TrainingModule module,
    required TrainingSubModule subModule,
    required List<_TrainingSearchResult> results,
  }) {
    for (final course in subModule.courses) {
      results.add(
        _TrainingSearchResult(
          module: module,
          subModule: subModule,
          course: course,
        ),
      );
    }

    for (final child in subModule.subModules) {
      _collectCourses(module: module, subModule: child, results: results);
    }
  }

  String _resultValue(_TrainingSearchResult result) {
    return '${result.course.code}|'
        '${result.course.name}|'
        '${result.module.name}|'
        '${result.subModule.name}|'
        '${result.course.semester}';
  }

  void _handleSelectionChanged(List<M3EDropdownItem<String>> selectedItems) {
    final selectedValues = selectedItems.map((item) => item.value).toSet();

    if (_selectedCourseValues.length == selectedValues.length &&
        _selectedCourseValues.containsAll(selectedValues)) {
      return;
    }

    if (_selectionUpdateScheduled) {
      return;
    }

    _selectionUpdateScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionUpdateScheduled = false;

      if (!mounted) {
        return;
      }

      if (_selectedCourseValues.length == selectedValues.length &&
          _selectedCourseValues.containsAll(selectedValues)) {
        return;
      }

      setState(() {
        _selectedCourseValues
          ..clear()
          ..addAll(selectedValues);

        _searchResults = _findSelectedCourses(selectedValues);
      });
    });
  }

  List<_TrainingSearchResult> _findSelectedCourses(Set<String> selectedValues) {
    if (selectedValues.isEmpty) {
      return const [];
    }

    final trainings = ref.read(trainingProvider);

    final results = <_TrainingSearchResult>[];

    for (final module in trainings) {
      for (final subModule in module.subModules) {
        _findSelectedCoursesRecursive(
          module: module,
          subModule: subModule,
          selectedValues: selectedValues,
          results: results,
        );
      }
    }

    return results;
  }

  void _findSelectedCoursesRecursive({
    required TrainingModule module,
    required TrainingSubModule subModule,
    required Set<String> selectedValues,
    required List<_TrainingSearchResult> results,
  }) {
    for (final course in subModule.courses) {
      final result = _TrainingSearchResult(
        module: module,
        subModule: subModule,
        course: course,
      );

      if (selectedValues.contains(_resultValue(result))) {
        results.add(result);
      }
    }

    for (final child in subModule.subModules) {
      _findSelectedCoursesRecursive(
        module: module,
        subModule: child,
        selectedValues: selectedValues,
        results: results,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ErrorPage(
              text: '当前未登入, 请先登入账号',
              icon: Mdi.accountAlertOutline,
            ),
          ),
        ),
      );
    }

    final trainings = ref.watch(trainingProvider);

    if (trainings.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const LoadPage(text: '正在加载培养方案...', ifok: true),
      );
    }

    _updateDropdownItems(trainings);

    return Scaffold(appBar: AppBar(), body: _buildContent(context));
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: M3EDropdownMenu<String>(
            itemStyle: M3EDropdownItemStyle(
              textStyle: Theme.of(context).textTheme.labelMedium,
              selectedTextStyle: Theme.of(context).textTheme.labelLarge,
            ),

            fieldStyle: M3EDropdownFieldStyle(hintText: '选择或搜索课程'),
            dropdownStyle: M3EDropdownStyle(noItemsFoundText: '未找到课程'),
            searchStyle: M3ESearchStyle(hintText: '搜索课程名称/类型/代码/状态/性质'),
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
            child: _searchResults.isEmpty
                ? KeyedSubtree(
                    key: const ValueKey('empty'),
                    child: _buildEmptySelection(context),
                  )
                : KeyedSubtree(
                    key: const ValueKey('list'),
                    child: _buildSearchResults(context),
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
                Icon(
                  Mdi.bookSearchOutline,
                  size: 42,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 6),
                Text(
                  '请选择要查看的课程',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
                Text(
                  '可选择多个课程',
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

  Widget _buildSearchResults(BuildContext context) {
    return M3ESegmentedList.builder(
      itemCount: _searchResults.length,
      physics: const AlwaysScrollableScrollPhysics(),
      listPadding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      outerRadius: 20,
      innerRadius: 20,
      gap: 3,
      itemBuilder: (context, index) {
        final result = _searchResults[index];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 250 + (index * 40).clamp(0, 200)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: _TrainingSearchResultCard(
            result: result,
            onTap: () {
              _showCourseBottomSheet(context, result.course);
            },
          ),
        );
      },
    );
  }

  void _showCourseBottomSheet(BuildContext context, TrainingCourse course) {
    HapticFeedback.lightImpact();

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
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Icon(Mdi.close),
          ),
        ],
        child: BottomsheetWidget(
          items: [
            {'icon': Mdi.codeBraces, 'name': course.code, 'value': '课程代码'},
            {'icon': Mdi.tournament, 'name': course.name, 'value': '课程名称'},
            {
              'icon': Mdi.formatListBulletedType,
              'name': course.nature,
              'value': '课程性质',
            },
            {
              'icon': Mdi.calendarRange,
              'name': course.semester,
              'value': '修读学期',
            },
            {
              'icon': Mdi.starFourPointsOutline,
              'name': '${course.score}分',
              'value': '成绩',
            },
            {'icon': Mdi.mathCompass, 'name': course.gpa, 'value': '绩点'},
            {
              'icon': Mdi.decagramOutline,
              'name': '${course.credits}分',
              'value': '学分',
            },
            {
              'icon': Mdi.informationBoxOutline,
              'name': course.status,
              'value': '状态',
            },
          ],
        ),
      ),
    );
  }
}

class _TrainingSearchResultCard extends StatelessWidget {
  const _TrainingSearchResultCard({required this.result, required this.onTap});

  final _TrainingSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final course = result.course;

    final isCompleted = course.status
        .replaceAll(RegExp(r'\s+'), '')
        .contains('通过');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isCompleted
                ? colorScheme.primaryContainer
                : colorScheme.tertiaryContainer,
            child: Text('${course.credits}分', style: textTheme.labelMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${result.module.name} · ${result.subModule.name}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '成绩: ${course.score}│'
                  '绩点: ${course.gpa}│'
                  '${course.status}',
                  style: textTheme.bodySmall?.copyWith(
                    color: isCompleted
                        ? colorScheme.primary
                        : colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Mdi.chevronRight, color: colorScheme.outline),
        ],
      ),
    );
  }
}

class _TrainingSearchResult {
  const _TrainingSearchResult({
    required this.module,
    required this.subModule,
    required this.course,
  });

  final TrainingModule module;
  final TrainingSubModule subModule;
  final TrainingCourse course;
}
