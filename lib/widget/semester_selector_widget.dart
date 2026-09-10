import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'package:new_zhic_tool/provider/schedule_notifier.dart';

class SemesterSelector extends ConsumerStatefulWidget {
  const SemesterSelector({super.key});

  @override
  ConsumerState<SemesterSelector> createState() => _SemesterSelectorState();
}

class _SemesterSelectorState extends ConsumerState<SemesterSelector> {
  final M3EDropdownController<String> dropdownController =
      M3EDropdownController<String>();

  String? _lastSelectedId;

  bool _syncingController = false;

  @override
  void dispose() {
    dropdownController.dispose();
    super.dispose();
  }

  void _syncDropdown(String semesterId) {
    if (_lastSelectedId == semesterId) {
      return;
    }

    _lastSelectedId = semesterId;

    final selectedValues = dropdownController.selectedValues;

    if (selectedValues.length == 1 && selectedValues.first == semesterId) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _syncingController = true;

      dropdownController.clearAll();

      dropdownController.selectWhere((item) => item.value == semesterId);

      _syncingController = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);

    final semesters = schedule.semesters;

    if (schedule.isLoading && semesters.isEmpty) {
      return const ListTile(title: Text('学期'), trailing: M3ELoadingIndicator());
    }

    if (semesters.isEmpty) {
      return const ListTile(title: Text('学期'), subtitle: Text('暂无学期配置'));
    }

    final currentSemester = schedule.currentSemester;

    if (currentSemester != null) {
      _syncDropdown(currentSemester.id);
    }

    final dropList = semesters
        .map(
          (semester) =>
              M3EDropdownItem<String>(label: semester.name, value: semester.id),
        )
        .toList();

    return M3EDropdownMenu<String>(
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
      singleSelect: true,
      items: dropList,
      controller: dropdownController,
      onSelectionChanged: (items) async {
        if (_syncingController || items.isEmpty) {
          return;
        }

        final selectedId = items.first.value;

        final semester = semesters.firstWhere(
          (semester) => semester.id == selectedId,
        );

        await ref.read(scheduleProvider.notifier).selectSemester(semester);
      },
    );
  }
}
