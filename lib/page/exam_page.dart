import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/exam.dart';
import 'package:new_zhic_tool/provider/auth_notifier.dart';
import 'package:new_zhic_tool/provider/exam_provider.dart';
import 'package:new_zhic_tool/provider/schedule_notifier.dart';
import 'package:new_zhic_tool/widget/bottomsheet_widget.dart';
import 'package:new_zhic_tool/widget/empty_page.dart';
import 'package:new_zhic_tool/widget/error_page.dart';
import 'package:new_zhic_tool/widget/load_page.dart';
import 'package:share_plus/share_plus.dart';

class ExamPage extends ConsumerStatefulWidget {
  const ExamPage({super.key});

  @override
  ConsumerState<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends ConsumerState<ExamPage> {
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
            XFile.fromData(pngBytes, mimeType: 'image/png', name: '考试安排.png'),
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
        appBar: AppBar(),
        body: ErrorPage(text: '当前未登入, 请先登入账号', icon: Mdi.accountAlertOutline),
      );
    }

    final schedule = ref.watch(scheduleProvider);

    final semesterId = schedule.currentSemester?.id;

    if (semesterId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('暂无学期信息')),
      );
    }

    final examsAsync = ref.watch(examProvider(semesterId.toString()));

    return Scaffold(
      appBar: AppBar(
        actions: [
          examsAsync.maybeWhen(
            data: (exams) => exams.isEmpty
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

      body: examsAsync.when(
        loading: () {
          return const LoadPage(text: '正在获取与解析考试安排...', ifok: true);
        },

        error: (error, stackTrace) {
          return ErrorPage(
            text: error.toString(),
            icon: Mdi.fileDocumentAlertOutline,
          );
        },

        data: (exams) {
          return RepaintBoundary(
            key: _shareKey,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: _ExamContent(
                semesterId: semesterId.toString(),
                exams: exams,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExamContent extends ConsumerWidget {
  const _ExamContent({required this.semesterId, required this.exams});

  final String semesterId;

  final List<Exam> exams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingExams = exams.where((exam) => !exam.isFinished).toList();

    final finishedExams = exams.where((exam) => exam.isFinished).toList();

    return exams.isEmpty
        ? _buildEmptyList(context)
        : ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (upcomingExams.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _SectionHeader(
                    title: '进行中 / 未开始',
                    icon: Mdi.calendarClock,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: _buildPart(context, upcomingExams),
                ),
              ],

              if (upcomingExams.isEmpty && finishedExams.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _NoUpcomingNotice(),
                ),

              if (finishedExams.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: _buildPart(context, finishedExams),
                ),
            ],
          );
  }

  Widget _buildEmptyList(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 500,
        child: EmptyPage(text: '本学期暂无考试安排', icon: Mdi.calendarBlankOutline),
      ),
    );
  }

  Widget _buildPart(BuildContext context, List<Exam> examList) {
    return M3ESegmentedList(
      itemCount: examList.length,

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
        final exam = examList[index];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _getExamItem(context, exam)),
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
                      title: Text(exam.courseName),
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
                            'icon': Mdi.bookOpenOutline,
                            'name': exam.courseName,
                            'value': '考试课程',
                          },
                          {
                            'icon': Mdi.tagOutline,
                            'name': exam.type,
                            'value': '考试类型',
                          },
                          {
                            'icon': Mdi.clockOutline,
                            'name': exam.time.isEmpty ? '未公布' : exam.time,
                            'value': '考试时间',
                          },
                          {
                            'icon': Mdi.mapMarkerOutline,
                            'name': exam.location.isEmpty
                                ? '未公布'
                                : exam.location,
                            'value': '考试地点',
                          },
                          {
                            'icon': Mdi.informationOutline,
                            'name': exam.status,
                            'value': '考试状态',
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
    );
  }

  Widget _getExamItem(BuildContext context, Exam exam) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: exam.isFinished ? 0.65 : 1,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          CircleAvatar(
            backgroundColor: exam.isFinished
                ? colorScheme.surfaceContainerHighest
                : colorScheme.primaryContainer,

            child: Icon(
              exam.isFinished ? Mdi.calendarCheckOutline : Mdi.calendarClock,

              color: exam.isFinished
                  ? colorScheme.outline
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ExamTag(text: exam.type),
                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        exam.courseName,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: textTheme.titleSmall?.copyWith(
                          decoration: exam.isFinished
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                _InfoRow(
                  icon: Mdi.clockOutline,
                  text: exam.time.isEmpty ? '时间未公布' : exam.time,
                ),
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Mdi.mapMarkerOutline,
                  text: exam.location.isEmpty ? '地点未公布' : exam.location,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;

  final IconData icon;

  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),

        const SizedBox(width: 8),

        Text(
          title,

          style: textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _NoUpcomingNotice extends StatelessWidget {
  const _NoUpcomingNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Icon(Mdi.informationOutline, color: colorScheme.primary),

          const SizedBox(width: 12),

          Expanded(child: Text('暂无未结束的考试安排', style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ExamTag extends StatelessWidget {
  const _ExamTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 1, bottom: 1),
        child: Text(
          text,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 12, color: colorScheme.outline),

        const SizedBox(width: 4),

        Expanded(
          child: Text(
            text,

            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),

            maxLines: 2,

            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
