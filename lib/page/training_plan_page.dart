import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/training.dart';
import 'package:new_zhic_tool/page/training_search_page.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/training_provider.dart';
import 'package:new_zhic_tool/service/training_service.dart';
import 'package:new_zhic_tool/widget/bottomsheet_widget.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrainingPlanPage extends ConsumerStatefulWidget {
  const TrainingPlanPage({super.key});

  @override
  ConsumerState<TrainingPlanPage> createState() => _TrainingPlanPageState();
}

class _TrainingPlanPageState extends ConsumerState<TrainingPlanPage> {
  final _shareKey = GlobalKey();

  bool _isLoading = true;

  bool _isParsing = false;

  Map<String, String> _headers = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trainingProvider.notifier).clear();
    });

    _loadCookies();
  }

  // Cookie

  Future<void> _loadCookies() async {
    final prefs = await SharedPreferences.getInstance();

    final cookie = prefs.getString('cookies');

    if (!mounted) {
      return;
    }

    setState(() {
      _headers = {
        'Accept': 'application/json, text/plain, */*',
        'User-Agent': 'Mozilla/5.0',
        if (cookie != null && cookie.isNotEmpty) 'Cookie': cookie,
      };

      _isLoading = false;
    });
  }

  // HTML 解析

  Future<void> _extractAndParseHtml(InAppWebViewController controller) async {
    if (_isParsing) {
      return;
    }

    if (mounted) {
      setState(() {
        _isParsing = true;
      });
    }

    try {
      final htmlContent = await controller.evaluateJavascript(
        source: 'document.documentElement.outerHTML;',
      );

      if (htmlContent == null || htmlContent.isEmpty) {
        return;
      }

      final training = TrainingService.instance.parseHtml(htmlContent);

      if (!mounted) {
        return;
      }

      ref.read(trainingProvider.notifier).setTraining(training);
    } catch (e, stackTrace) {
      debugPrint('解析 HTML 出错: $e');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isParsing = false;
        });
      }
    }
  }

  // 搜索

  void _openSearch() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const TrainingSearchPage()));
  }

  // 刷新

  // 分享图片

  Future<void> _shareAsImage() async {
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) {
      return;
    }

    final renderObject = _shareKey.currentContext?.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      return;
    }

    final image = await renderObject.toImage(pixelRatio: 3.0);

    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();

      if (!mounted) {
        return;
      }

      final renderBox = context.findRenderObject();

      Rect? sharePositionOrigin;

      if (renderBox is RenderBox) {
        sharePositionOrigin =
            renderBox.localToGlobal(Offset.zero) & renderBox.size;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(pngBytes, mimeType: 'image/png', name: '培养方案.png'),
          ],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } finally {
      image.dispose();
    }
  }

  // Build

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);

    // 未登录

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('培养方案')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ErrorPage(
              text: '当前未登入，请先登入账号',
              icon: Mdi.accountAlertOutline,
            ),
          ),
        ),
      );
    }

    // 加载

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('培养方案')),
        body: const LoadPage(text: '正在加载培养方案...', ifok: true),
      );
    }

    final trainings = ref.watch(trainingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('培养方案'),
        actions: [
          if (trainings.isNotEmpty)
            M3EButton(
              onPressed: _shareAsImage,
              style: M3EButtonStyle.text,
              child: const Icon(Mdi.shareVariant),
            ),
          IconButton(
            tooltip: '搜索',
            onPressed: trainings.isEmpty ? null : _openSearch,
            icon: const Icon(Mdi.magnify),
          ),
        ],
      ),
      body: Stack(
        children: [
          trainings.isEmpty
              ? LoadPage(
                  text: _isParsing ? '正在解析培养方案...' : '正在加载培养方案...',
                  ifok: true,
                )
              : RepaintBoundary(
                  key: _shareKey,
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: _buildContent(context, trainings),
                  ),
                ),

          // 隐藏 WebView
          Offstage(
            offstage: true,
            child: SizedBox(
              height: 1,
              width: 1,
              child: InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(
                    'https://eams.tjzhic.edu.cn/student/for-std/program-completion-preview',
                  ),
                  headers: _headers,
                ),
                initialSettings: InAppWebViewSettings(javaScriptEnabled: true),
                onWebViewCreated: (controller) {},
                onLoadStop: (controller, url) async {
                  await Future.delayed(const Duration(milliseconds: 1500));

                  if (!mounted) {
                    return;
                  }

                  await _extractAndParseHtml(controller);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 页面内容

  Widget _buildContent(BuildContext context, List<TrainingModule> trainings) {
    final summary = TrainingService.instance.calculateSummary(trainings);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
          child: _SummaryCard(summary: summary),
        ),
        Expanded(child: _buildExpandableList(context, trainings)),
      ],
    );
  }

  // 一级模块

  Widget _buildExpandableList(
    BuildContext context,
    List<TrainingModule> trainings,
  ) {
    final service = TrainingService.instance;

    final data = trainings.map((module) {
      final summary = service.calculateModuleSummary(module);

      return M3EExpandableData(
        leading: const CircleAvatar(child: Icon(Mdi.bookEducationOutline)),
        title:
            '${module.name} '
            '(共${summary.totalCount}门'
            '${_formatCredits(summary.totalCredits)}分)',
        subtitle: _buildModuleSubtitle(summary),
        subtitleStyle: [?Theme.of(context).textTheme.labelMedium],
        body: _TrainingSubModuleList(subModules: module.subModules, level: 2),
      );
    }).toList();

    return M3EExpandableCardList(
      data: data,
      allowMultipleExpanded: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      style: M3EExpandableStyle(
        headerPadding: const EdgeInsets.only(
          left: 18,
          right: 12,
          top: 12,
          bottom: 12,
        ),
        bodyPadding: .fromLTRB(6, 3, 6, 3),
        expandIcon: const Icon(Mdi.chevronDown),
        collapseIcon: const Icon(Mdi.chevronUp),
        expandTooltip: '展开模块',
        collapseTooltip: '收起模块',
      ),
    );
  }

  // 一级模块完成情况

  String _buildModuleSubtitle(TrainingModuleSummary summary) {
    return '已完成${summary.completedCount}门'
        '${_formatCredits(summary.completedCredits)}分 '
        '未完成${summary.incompleteCount}门'
        '${_formatCredits(summary.incompleteCredits)}分';
  }
}

// ============================================================
// 顶部汇总卡片
// ============================================================

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final TrainingSummary summary;

  @override
  Widget build(BuildContext context) {
    return M3ESegmentedItem(
      index: 0,
      position: .first,
      outerRadius: 18,
      innerRadius: 18,
      padding: .all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _SummaryItem(
              label: '已完成',
              count: summary.completedCount,
              credits: summary.completedCredits,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: '未完成',
              count: summary.incompleteCount,
              credits: summary.incompleteCredits,
            ),
          ),
          Expanded(
            child: _SummaryItem(
              label: '总课程',
              count: summary.totalCount,
              credits: summary.totalCredits,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 汇总项目
// ============================================================

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.count,
    required this.credits,
  });

  final String label;

  final int count;

  final double credits;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 5),
        Text(
          '$count门',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatCredits(credits)}分',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 二级 / 三级模块列表
// ============================================================

class _TrainingSubModuleList extends StatelessWidget {
  const _TrainingSubModuleList({required this.subModules, required this.level});

  final List<TrainingSubModule> subModules;

  final int level;

  @override
  Widget build(BuildContext context) {
    if (subModules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var i = 0; i < subModules.length; i++)
          _TrainingSubModuleCard(
            key: ValueKey('${level}_${subModules[i].name}_$i'),
            subModule: subModules[i],
            level: level,
            index: i,
            totalCount: subModules.length,
          ),
      ],
    );
  }
}

// ============================================================
// 二级 / 三级模块
// ============================================================

class _TrainingSubModuleCard extends StatefulWidget {
  const _TrainingSubModuleCard({
    super.key,
    required this.subModule,
    required this.level,
    required this.index,
    required this.totalCount,
  });

  final TrainingSubModule subModule;

  final int level;

  final int index;

  final int totalCount;

  @override
  State<_TrainingSubModuleCard> createState() => _TrainingSubModuleCardState();
}

class _TrainingSubModuleCardState extends State<_TrainingSubModuleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final textTheme = Theme.of(context).textTheme;

    final hasCourses = widget.subModule.courses.isNotEmpty;

    final hasSubModules = widget.subModule.subModules.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: widget.level == 3 ? 8 : 0),
      child: M3EExpandableItem(
        index: widget.index,
        totalCount: widget.totalCount,
        isExpanded: _isExpanded,
        decoration: M3EExpandableStyle(
          expandIcon: const Icon(Mdi.chevronDown),
          collapseIcon: const Icon(Mdi.chevronUp),
          headerPadding: const EdgeInsets.only(
            left: 18,
            right: 12,
            top: 12,
            bottom: 12,
          ),
        ),
        expandMotion: .expressiveSpatialDefault,
        collapseMotion: .expressiveSpatialDefault,
        onToggle: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },

        // Header
        headerBuilder: (context, index, progress) {
          return Row(
            children: [
              CircleAvatar(
                child: Icon(
                  widget.level == 2
                      ? Mdi.bookshelf
                      : Mdi.bookOpenPageVariantOutline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.subModule.name,
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subModule.sign.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subModule.sign,
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },

        // Body
        bodyBuilder: (context, index, progress) {
          if (!hasCourses && !hasSubModules) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('暂无课程', style: textTheme.bodyMedium),
            );
          }

          return Padding(
            padding: EdgeInsets.only(left: widget.level == 2 ? 8 : 0),
            child: Column(
              children: [
                if (hasCourses)
                  ...widget.subModule.courses.map(
                    (course) => _TrainingCourseRow(course: course),
                  ),
                if (hasSubModules)
                  _TrainingSubModuleList(
                    subModules: widget.subModule.subModules,
                    level: widget.level + 1,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// 课程
// ============================================================

class _TrainingCourseRow extends StatelessWidget {
  const _TrainingCourseRow({required this.course});

  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final textTheme = Theme.of(context).textTheme;

    final isCompleted = course.status
        .replaceAll(RegExp(r'\s+'), '')
        .contains('通过');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCompleted
                      ? colorScheme.primaryContainer
                      : colorScheme.tertiaryContainer,
                  child: Text(
                    '${course.credits}分',
                    style: textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 13),
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
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.transparent,
            child: IconButton(
              icon: const Icon(Mdi.informationOutline),
              onPressed: () {
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
                    child: TrainingCourseDetail(course: course),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 课程详情
// ============================================================

class TrainingCourseDetail extends StatelessWidget {
  const TrainingCourseDetail({super.key, required this.course});

  final TrainingCourse course;

  @override
  Widget build(BuildContext context) {
    return BottomsheetWidget(
      items: [
        {'icon': Mdi.codeBraces, 'name': course.code, 'value': '课程代码'},
        {'icon': Mdi.tournament, 'name': course.name, 'value': '课程名称'},
        {
          'icon': Mdi.formatListBulletedType,
          'name': course.nature,
          'value': '课程性质',
        },
        {'icon': Mdi.calendarRange, 'name': course.semester, 'value': '修读学期'},
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
    );
  }
}

String _formatCredits(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}
