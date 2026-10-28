import 'package:flutter/services.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';

/// 常用主题色, 点击即可选中。
const List<Color> _presetColors = [
  Color(0xFF6750A4),
  Color(0xFF2196F3),
  Color(0xFF00BCD4),
  Color(0xFF009688),
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFFFFC107),
  Color(0xFFFF9800),
  Color(0xFFF44336),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF607D8B),
];

/// 打开主题色调色盘, 返回用户选中的颜色; 关闭则不返回。
Future<Color?> showSeedColorPicker(
  BuildContext context, {
  required Color initial,
}) {
  return showM3EModalBottomSheet<Color>(
    context: context,
    showDragHandle: true,
    builder: (context) => M3EBottomSheet(
      title: const Text('主题色'),
      actions: [
        M3EButton(
          style: M3EButtonStyle.text,
          shape: M3EButtonShape.round,
          size: M3EButtonSize.sm,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Mdi.close),
        ),
      ],
      child: _SeedColorPicker(initial: initial),
    ),
  );
}

class _SeedColorPicker extends StatefulWidget {
  const _SeedColorPicker({required this.initial});

  final Color initial;

  @override
  State<_SeedColorPicker> createState() => _SeedColorPickerState();
}

class _SeedColorPickerState extends State<_SeedColorPicker> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  Color get _color => _hsv.toColor();

  void _update(HSVColor value) {
    HapticFeedback.selectionClick();
    setState(() {
      _hsv = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreview(textTheme),
          const SizedBox(height: 20),
          _buildLabel('预设色', textTheme),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in _presetColors)
                _PresetSwatch(
                  color: color,
                  selected: color.toARGB32() == _color.toARGB32(),
                  onTap: () => _update(HSVColor.fromColor(color)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('色相', textTheme),
          const SizedBox(height: 8),
          _GradientBar(
            label: '色相',
            gradientColors: const [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
            value: _hsv.hue / 360,
            onChanged: (value) => _update(_hsv.withHue(value * 360)),
          ),
          const SizedBox(height: 16),
          _buildLabel('饱和度', textTheme),
          const SizedBox(height: 8),
          _GradientBar(
            label: '饱和度',
            gradientColors: [
              Colors.white,
              _hsv.withSaturation(1).withValue(1).toColor(),
            ],
            value: _hsv.saturation,
            onChanged: (value) => _update(_hsv.withSaturation(value)),
          ),
          const SizedBox(height: 16),
          _buildLabel('明度', textTheme),
          const SizedBox(height: 8),
          _GradientBar(
            label: '明度',
            gradientColors: [Colors.black, _hsv.withValue(1).toColor()],
            value: _hsv.value,
            onChanged: (value) => _update(_hsv.withValue(value)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: M3EButton(
                  onPressed: () => Navigator.pop(context),
                  style: .outlined,
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: M3EButton(
                  onPressed: () => Navigator.pop(context, _color),
                  child: const Text('应用'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPreview(TextTheme textTheme) {
    final color = _color;

    return Container(
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        style: textTheme.titleMedium?.copyWith(
          color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PresetSwatch extends StatelessWidget {
  const _PresetSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '预设色 ${color.toARGB32().toRadixString(16).substring(2)}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? colorScheme.onSurface
                  : colorScheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// 带渐变轨道的调色条, 通过拖动或点击选择 0~1 的位置。
class _GradientBar extends StatelessWidget {
  const _GradientBar({
    required this.label,
    required this.gradientColors,
    required this.value,
    required this.onChanged,
  });

  final String label;

  final List<Color> gradientColors;

  final double value;

  final ValueChanged<double> onChanged;

  static const double _height = 32;

  static const double _thumbSize = 24;

  void _handle(BuildContext context, Offset globalPosition) {
    final box = context.findRenderObject();

    if (box is! RenderBox) {
      return;
    }

    final local = box.globalToLocal(globalPosition);

    final usable = (box.size.width - _thumbSize).clamp(1.0, double.infinity);

    onChanged(((local.dx - _thumbSize / 2) / usable).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - _thumbSize;

        return Semantics(
          slider: true,
          label: label,
          value: '${(value * 100).round()}%',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _handle(context, details.globalPosition),
            onHorizontalDragUpdate: (details) =>
                _handle(context, details.globalPosition),
            child: SizedBox(
              height: _height,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Positioned(
                    left: (usable * value).clamp(0.0, usable),
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.onSurface.withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
