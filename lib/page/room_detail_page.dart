import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/core/share_boundary.dart';
import 'package:new_zhic_tool/model/empty_room.dart';
import 'package:new_zhic_tool/widget/occupation_table.dart';

class RoomDetailPage extends StatefulWidget {
  const RoomDetailPage({super.key, required this.room});

  final EmptyRoom room;

  static const List<String> weeks = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final _shareKey = GlobalKey();

  Future<void> _shareAsImage() async {
    await shareBoundaryImage(
      context,
      _shareKey,
      fileName: '${widget.room.roomName}.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const OccupationLegend(),
                      ),
                      const SizedBox(height: 20),
                      RoomOccupationTable(occupations: widget.room.occupations),
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

  Widget _buildPart(List<Widget> children, List<String> copyList) {
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

                  Clipboard.setData(ClipboardData(text: copyList[index]));
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
}
