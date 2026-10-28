import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/model/empty_room.dart';

/// 教室占用表: 12 节 × 7 天, 供教室卡片与教室详情页共用。
///
/// [dense] 为 true 时使用列表卡片的紧凑尺寸, 否则使用详情页的大尺寸。
class RoomOccupationTable extends StatelessWidget {
  const RoomOccupationTable({
    super.key,
    required this.occupations,
    this.dense = false,
  });

  final List<RoomOccupation> occupations;

  final bool dense;

  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final labelStyle = (dense ? textTheme.labelSmall : textTheme.bodySmall)
        ?.copyWith(color: colorScheme.outline);

    final unitRowHeight = dense ? 27.0 : 38.0;
    final cellHeight = dense ? 23.0 : 34.0;
    final cellInset = dense ? 2.0 : 3.0;
    final cellRadius = dense ? 5.0 : 6.0;

    return Table(
      columnWidths: {0: FixedColumnWidth(dense ? 22 : 35)},
      children: [
        TableRow(
          children: [
            SizedBox(height: dense ? 0 : 25),
            ..._weekdays.map((day) {
              return Center(
                child: Text(
                  '周$day',
                  style: labelStyle?.copyWith(fontWeight: FontWeight.bold),
                ),
              );
            }),
          ],
        ),
        ...List.generate(12, (unitIndex) {
          final unit = unitIndex + 1;

          return TableRow(
            children: [
              SizedBox(
                height: unitRowHeight,
                child: Center(
                  child: Text(
                    '$unit',
                    style: labelStyle?.copyWith(fontWeight: FontWeight.bold),
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

                return Padding(
                  padding: EdgeInsets.all(cellInset),
                  child: Container(
                    height: cellHeight,
                    decoration: BoxDecoration(
                      color: isBusy
                          ? colorScheme.errorContainer
                          : colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(cellRadius),
                    ),
                    child: Center(child: Text(isBusy ? '' : '✅')),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

/// 占用表的图例: 空闲 / 占用。
class OccupationLegend extends StatelessWidget {
  const OccupationLegend({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(label: '空闲', isBusy: false, dense: dense),
        SizedBox(width: dense ? 24 : 32),
        _LegendDot(label: '占用', isBusy: true, dense: dense),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.isBusy,
    required this.dense,
  });

  final String label;

  final bool isBusy;

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dotSize = dense ? 9.0 : 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: isBusy
                ? colorScheme.errorContainer
                : colorScheme.tertiaryContainer,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: dense
              ? textTheme.labelSmall
              : textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
