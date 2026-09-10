import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/model/empty_room.dart';
import 'package:share_plus/share_plus.dart';

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({super.key, required this.room});

  final EmptyRoom room;

  static const List<String> weeks = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  /// 用于截取分享图片。
  final _shareKey = GlobalKey();

  Future<void> _shareAsImage() async {
    // 等待当前帧完成，确保 RepaintBoundary 已经完成绘制。
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
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name: '${widget.room.roomName}.png',
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          // 教室信息
          M3EButton(
            onPressed: () {
              showM3EModalBottomSheet(
                context: context,
                builder: (context) {
                  return M3EBottomSheet(
                    title: Text(widget.room.roomName),
                    actions: [
                      M3EButton(
                        style: M3EButtonStyle.text,
                        shape: M3EButtonShape.round,
                        size: M3EButtonSize.sm,
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(Mdi.close),
                      ),
                    ],
                    child: SingleChildScrollView(
                      padding: .zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPart(
                            [
                              _getItem(
                                Mdi.hoopHouse,
                                widget.room.buildingName,
                                '所在楼宇',
                              ),
                              _getItem(
                                Mdi.tournament,
                                widget.room.roomName,
                                '名称',
                              ),
                              _getItem(
                                Mdi.human,
                                '${widget.room.seats}人',
                                '可容纳人数',
                              ),
                            ],
                            [
                              widget.room.buildingName,
                              widget.room.roomName,
                              '${widget.room.seats}人',
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            style: .text,
            child: const Icon(Mdi.informationOutline),
          ),

          // 分享
          M3EButton(
            onPressed: _shareAsImage,
            style: .text,
            child: const Icon(Mdi.shareVariant),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: RepaintBoundary(
                key: _shareKey,
                child: Container(
                  color: colorScheme.surface,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildShareHeader(context),
                      const SizedBox(height: 16),
                      _buildLegend(context),
                      const SizedBox(height: 20),
                      _buildOccupationTable(
                        context,
                        colorScheme,
                        widget.room.occupations,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.room.roomName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.room.buildingName,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildPart(List<Widget> children, List copyList) {
    return M3ESegmentedList(
      itemCount: children.length,
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            children[index],
            CircleAvatar(
              backgroundColor: Colors.transparent,
              child: IconButton(
                icon: const Icon(Mdi.contentCopy),
                onPressed: () {
                  HapticFeedback.lightImpact();

                  Clipboard.setData(
                    ClipboardData(text: copyList[index].toString()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getItem(IconData icon, String title, String subtitle) {
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

  Widget _buildOccupationTable(
    BuildContext context,
    ColorScheme colorScheme,
    List<RoomOccupation> occupations,
  ) {
    return Table(
      columnWidths: const {0: FixedColumnWidth(35)},
      children: [
        TableRow(
          children: [
            const SizedBox(height: 25),
            ...RoomDetailPage.weeks.map(
              (week) => Center(
                child: Text(
                  '周$week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.outline,
                  ),
                ),
              ),
            ),
          ],
        ),
        ...List.generate(12, (unitIndex) {
          final unit = unitIndex + 1;

          return TableRow(
            children: [
              SizedBox(
                height: 38,
                child: Center(
                  child: Text(
                    '$unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ...List.generate(7, (weekdayIndex) {
                final weekday = weekdayIndex + 1;

                final isBusy = occupations.any(
                  (occupation) =>
                      occupation.weekday == weekday &&
                      occupation.unit == unit &&
                      occupation.isBusy,
                );

                return Container(
                  height: 34,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isBusy
                        ? colorScheme.errorContainer
                        : colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Text(isBusy ? '' : '✅')),
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendDot(colorScheme.tertiaryContainer, '空闲'),
          const SizedBox(width: 32),
          _legendDot(colorScheme.errorContainer, '占用'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
