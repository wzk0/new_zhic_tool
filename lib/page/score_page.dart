import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/score.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/score_provider.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:new_zhic_tool/widget/bottomsheet_widget.dart';
import 'package:new_zhic_tool/widget/empty_page.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';
import 'package:share_plus/share_plus.dart';

class ScorePage extends ConsumerStatefulWidget {
  const ScorePage({super.key});

  @override
  ConsumerState<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends ConsumerState<ScorePage> {
  final _shareKey = GlobalKey();

  Future<void> _shareAsImage() async {
    await WidgetsBinding.instance.endOfFrame;

    if (!mounted) return;

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

      if (!mounted) return;

      final renderBox = context.findRenderObject();

      Rect? sharePositionOrigin;

      if (renderBox is RenderBox) {
        sharePositionOrigin =
            renderBox.localToGlobal(Offset.zero) & renderBox.size;
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(pngBytes, mimeType: 'image/png', name: '成绩单.png'),
          ],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } finally {
      image.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider);

    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('成绩')),
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

    if (semesterId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('成绩')),
        body: const Center(child: Text('暂无学期信息')),
      );
    }

    final scoresAsync = ref.watch(scoreProvider(semesterId.toString()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩'),
        actions: [
          scoresAsync.maybeWhen(
            data: (scores) => scores.isEmpty
                ? const SizedBox.shrink()
                : M3EButton(
                    onPressed: _shareAsImage,
                    style: M3EButtonStyle.text,
                    child: const Icon(Mdi.shareVariant),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: scoresAsync.when(
        loading: () {
          return LoadPage(text: '尝试获取业务ID中,\n如果加载时间长, 请尝试重新登入', ifok: true);
        },
        error: (error, stackTrace) {
          return ErrorPage(
            text: error.toString(),
            icon: Mdi.fileDocumentAlertOutline,
          );
        },
        data: (scores) {
          return RepaintBoundary(
            key: _shareKey,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: _ScoreContent(
                semesterId: semesterId.toString(),
                scores: scores,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScoreContent extends ConsumerWidget {
  const _ScoreContent({required this.semesterId, required this.scores});

  final String semesterId;
  final List<Score> scores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = _calculateSummary(scores);

    return scores.isEmpty
        ? EmptyPage(text: '该学期尚未出成绩', icon: Mdi.alertCircleOutline)
        : CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _SummaryCard(summary: summary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 11, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: M3ESegmentedList(
                    itemCount: scores.length,
                    onTap: (index) {
                      HapticFeedback.lightImpact();
                      Confetti.launch(
                        context,
                        options: const ConfettiOptions(
                          particleCount: 150,
                          spread: 70,
                          y: 0.7,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      final score = scores[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _getScoreItem(context, score)),
                          CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: IconButton(
                              icon: Icon(Mdi.informationOutline),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                showM3EModalBottomSheet(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (context) => M3EBottomSheet(
                                    title: Text(score.courseName),
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
                                        {
                                          'icon': Mdi.codeBraces,
                                          'name': score.courseCode,
                                          'value': '课程代码',
                                        },
                                        {
                                          'icon': Mdi.tournament,
                                          'name': score.courseName,
                                          'value': '课程名称',
                                        },
                                        {
                                          'icon': Mdi.formatListBulletedType,
                                          'name': score.courseProperty,
                                          'value': '课程属性',
                                        },
                                        {
                                          'icon': Mdi.starFourPointsOutline,
                                          'name': '${score.grade}分',
                                          'value': '成绩',
                                        },
                                        {
                                          'icon': Mdi.mathCompass,
                                          'name': score.gp.toString(),
                                          'value': '绩点',
                                        },
                                        {
                                          'icon': Mdi.decagramOutline,
                                          'name': '${score.credits}分',
                                          'value': '学分',
                                        },
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
  }

  Widget _getScoreItem(BuildContext context, Score score) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: score.passed
              ? colorScheme.primaryContainer
              : colorScheme.tertiaryContainer,
          child: Text(
            score.grade,
            style: textTheme.labelMedium?.copyWith(
              color: score.passed ? colorScheme.primary : colorScheme.tertiary,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                score.courseName,
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                score.courseProperty,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, double> _calculateSummary(List<Score> scores) {
    double totalGpWeight = 0;
    double totalScoreWeight = 0;
    double totalCredits = 0;
    for (final score in scores) {
      if (!score.passed) {
        continue;
      }
      if (score.credits <= 0) {
        continue;
      }
      final grade = double.tryParse(score.grade) ?? 0;
      totalGpWeight += score.gp * score.credits;
      totalScoreWeight += grade * score.credits;
      totalCredits += score.credits;
    }

    return {
      'gpa': totalCredits > 0 ? totalGpWeight / totalCredits : 0,
      'credits': totalCredits,
      'averageScore': totalCredits > 0 ? totalScoreWeight / totalCredits : 0,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final Map<String, double> summary;

  @override
  Widget build(BuildContext context) {
    return M3ESegmentedItem(
      onTap: (index) {
        HapticFeedback.lightImpact();
        Confetti.launch(
          context,
          options: const ConfettiOptions(
            particleCount: 150,
            spread: 70,
            y: 0.7,
          ),
        );
      },
      index: 0,
      position: .first,
      outerRadius: 18,
      innerRadius: 18,
      padding: .all(23),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: '平均分',
            value: summary['averageScore']!.toStringAsFixed(1),
          ),
          _SummaryItem(
            label: '总学分',
            value: summary['credits']!.toStringAsFixed(1),
          ),
          _SummaryItem(label: 'GPA', value: summary['gpa']!.toStringAsFixed(2)),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
