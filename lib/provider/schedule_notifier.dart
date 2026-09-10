import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:new_zhic_tool/service/schedule_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:new_zhic_tool/model/student_info.dart';
import 'package:new_zhic_tool/model/course.dart';
import 'package:new_zhic_tool/model/semester_config.dart';
import 'package:new_zhic_tool/service/config_service.dart';

class ScheduleState {
  const ScheduleState({
    this.semesters = const [],
    this.currentSemester,
    this.currentWeek = 1,
    this.courses = const [],
    this.coursesByWeek = const {},
    this.studentInfo = const StudentInfo(),
    this.isLoading = false,
    this.isSyncing = false,
    this.error,
    this.fromCache = false,
  });

  final List<SemesterConfig> semesters;

  final SemesterConfig? currentSemester;

  final int currentWeek;

  final List<Course> courses;

  final Map<int, List<Course>> coursesByWeek;

  final StudentInfo studentInfo;

  final bool isLoading;

  final bool isSyncing;

  final Object? error;

  final bool fromCache;

  ScheduleState copyWith({
    List<SemesterConfig>? semesters,
    SemesterConfig? currentSemester,
    int? currentWeek,
    List<Course>? courses,
    Map<int, List<Course>>? coursesByWeek,
    StudentInfo? studentInfo,
    bool? isLoading,
    bool? isSyncing,
    Object? error,
    bool? fromCache,
    bool clearError = false,
  }) {
    return ScheduleState(
      semesters: semesters ?? this.semesters,
      currentSemester: currentSemester ?? this.currentSemester,
      currentWeek: currentWeek ?? this.currentWeek,
      courses: courses ?? this.courses,
      coursesByWeek: coursesByWeek ?? this.coursesByWeek,
      studentInfo: studentInfo ?? this.studentInfo,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : error ?? this.error,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}

class ScheduleNotifier extends Notifier<ScheduleState> {
  static const String _semesterKey = 'selected_semester_id';
  static const String _loginFlagKey = 'is_logged_in';

  late final ScheduleService _scheduleService;

  late final ConfigService _configService;

  int _loadGeneration = 0;

  @override
  ScheduleState build() {
    _scheduleService = ScheduleService();

    _configService = ConfigService();

    Future.microtask(() => initialize());

    return const ScheduleState();
  }

  Future<void> initialize() async {
    if (state.isLoading || state.isSyncing) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final semesters = await _configService.fetchConfigs();

      if (semesters.isEmpty) {
        throw Exception('没有可用的学期配置');
      }

      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_semesterKey);
      final bool isLoggedIn = prefs.getBool(_loginFlagKey) ?? false;

      debugShow('保存的学期 ID: $savedId, 登入状态: $isLoggedIn');

      SemesterConfig selectedSemester;

      if (savedId != null && savedId.isNotEmpty) {
        selectedSemester = semesters.firstWhere(
          (semester) => semester.id == savedId,
          orElse: () => semesters.first,
        );
      } else {
        selectedSemester = semesters.first;
      }

      final currentWeek = _getCurrentWeek(selectedSemester.startDate);

      state = state.copyWith(
        semesters: semesters,
        currentSemester: selectedSemester,
        currentWeek: currentWeek,
        courses: const [],
        coursesByWeek: const {},
        studentInfo: const StudentInfo(),
        fromCache: false,
        isLoading: false,
        clearError: true,
      );

      if (isLoggedIn) {
        await loadCourses();
      } else {
        debugShow('用户未登入, 跳过加载个人课表与学生信息');
      }
    } catch (e, stackTrace) {
      debugShow('初始化课表失败: $e');
      debugShow(stackTrace.toString());

      state = state.copyWith(isLoading: false, isSyncing: false, error: e);
    }
  }

  Future<void> loadCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(_loginFlagKey) ?? false;
    if (!isLoggedIn) {
      debugShow('【安全拦截】检测到当前未登入, 拒绝加载课表与个人信息');
      state = state.copyWith(
        studentInfo: const StudentInfo(),
        courses: const [],
        coursesByWeek: const {},
        isSyncing: false,
        isLoading: false,
      );
      return;
    }

    final semester = state.currentSemester;

    if (semester == null) {
      return;
    }

    final semesterId = semester.id;

    final generation = ++_loadGeneration;

    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      debugShow(
        '开始加载整个学期课表: '
        'semester=$semesterId',
      );

      final scheduleData = await _scheduleService.fetchSchedule(
        semesterId: semesterId,
      );

      if (generation != _loadGeneration) {
        debugShow(
          '丢弃过期课表请求: '
          'semester=$semesterId',
        );

        return;
      }

      if (state.currentSemester?.id != semesterId) {
        debugShow(
          '当前学期已经改变, '
          '忽略旧课表: '
          'semester=$semesterId',
        );

        return;
      }

      final coursesByWeek = scheduleData.coursesByWeek;

      final serviceStudent = scheduleData.studentInfo;

      final studentInfo = StudentInfo(
        name: serviceStudent.name,
        code: serviceStudent.code,
        department: serviceStudent.department,
        adminClass: serviceStudent.adminClass,
      );

      final currentCourses =
          coursesByWeek[state.currentWeek] ?? const <Course>[];

      state = state.copyWith(
        coursesByWeek: coursesByWeek,
        courses: currentCourses,
        studentInfo: studentInfo,
        isSyncing: false,
        fromCache: scheduleData.fromCache,
        clearError: true,
      );

      if (scheduleData.fromCache) {
        debugShow(
          '课表加载完成：使用本地缓存 '
          'semester=$semesterId',
        );
      } else {
        debugShow(
          '课表加载完成：使用网络数据 '
          'semester=$semesterId',
        );
      }

      debugShow(
        '当前周: ${state.currentWeek}, '
        '课程数量: ${currentCourses.length}',
      );
    } catch (e, stackTrace) {
      if (generation != _loadGeneration) {
        return;
      }

      if (state.currentSemester?.id != semesterId) {
        return;
      }

      debugShow('加载课表失败: $e');

      debugShow(stackTrace.toString());

      state = state.copyWith(isSyncing: false, error: e);
    }
  }

  Future<void> selectSemester(SemesterConfig semester) async {
    debugShow(
      '选择学期: '
      '${semester.name} '
      '(id=${semester.id})',
    );

    _loadGeneration++;

    final week = _getCurrentWeek(semester.startDate);

    state = state.copyWith(
      currentSemester: semester,
      currentWeek: week,
      courses: const [],
      coursesByWeek: const {},
      fromCache: false,
      clearError: true,
    );

    debugShow(
      'ScheduleState 已更新: '
      '${state.currentSemester?.name} '
      '(id=${state.currentSemester?.id}), '
      'week=${state.currentWeek}',
    );

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_semesterKey, semester.id);

      debugShow(
        '学期选择已保存: '
        '${semester.id}',
      );
    } catch (e, stackTrace) {
      debugShow('保存学期选择失败: $e');

      debugShow(stackTrace.toString());
    }

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool(_loginFlagKey) ?? false;
    if (isLoggedIn) {
      await loadCourses();
    }
  }

  Future<void> selectWeek(int week) async {
    if (week < 1 || week > 20) {
      return;
    }

    if (state.currentWeek == week) {
      return;
    }

    final courses = state.coursesByWeek[week] ?? const <Course>[];

    debugShow(
      '切换周次: '
      '${state.currentWeek} → $week, '
      '课程=${courses.length}',
    );

    state = state.copyWith(
      currentWeek: week,
      courses: courses,
      clearError: true,
    );
  }

  Future<void> logout() async {
    debugShow('用户执行登出, 正在清空所有本地缓存与状态...');
    _loadGeneration++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_semesterKey);
      await prefs.setBool(_loginFlagKey, false);
    } catch (e) {
      debugShow('清理本地偏好设置失败: $e');
    }

    final currentSemesters = state.semesters;
    state = ScheduleState(
      semesters: currentSemesters,
      currentSemester: currentSemesters.isNotEmpty
          ? currentSemesters.first
          : null,
      studentInfo: const StudentInfo(),
      courses: const [],
      coursesByWeek: const {},
    );

    debugShow('已切换为登出状态, 个人信息与课表已全部清空');
  }

  int _getCurrentWeek(String startDate) {
    try {
      final start = DateTime.parse(startDate);
      final today = DateTime.now();
      final startDay = DateTime(start.year, start.month, start.day);
      final todayDay = DateTime(today.year, today.month, today.day);
      final difference = todayDay.difference(startDay).inDays;
      if (difference < 0) {
        return 1;
      }
      final week = difference ~/ 7 + 1;
      return week.clamp(1, 20);
    } catch (e) {
      debugShow('计算当前周失败: $e');
      return 1;
    }
  }
}

final scheduleProvider = NotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);
