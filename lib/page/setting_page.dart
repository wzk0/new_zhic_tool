import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/icon.dart';
import 'package:new_zhic_tool/provider/theme_settings_notifier.dart';
import 'package:new_zhic_tool/widget/seed_color_picker.dart';

class SettingPage extends ConsumerWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 8, bottom: 12),
            child: Text(
              '外观',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          M3ESegmentedList(
            itemCount: 2,
            onTap: (index) {
              HapticFeedback.lightImpact();
              switch (index) {
                case 0:
                  ref
                      .read(themeSettingsProvider.notifier)
                      .setUseMonet(!settings.useMonet);
                  break;
                case 1:
                  _pickSeedColor(context, ref, settings);
                  break;
              }
            },
            itemBuilder: (context, index) {
              return switch (index) {
                0 => _buildMonetItem(context, ref, settings),
                1 => _buildSeedColorItem(context, settings),
                _ => const SizedBox.shrink(),
              };
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
            child: Text(
              settings.useMonet
                  ? '开启后主题色跟随系统壁纸(Android 12+), 关闭则使用自定义主题色。'
                  : '当前使用自定义主题色生成的配色。',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSeedColor(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings settings,
  ) async {
    final color = await showSeedColorPicker(
      context,
      initial: settings.seedColor,
    );

    if (color == null) {
      return;
    }

    await ref.read(themeSettingsProvider.notifier).setSeedColor(color);
  }

  Widget _buildMonetItem(
    BuildContext context,
    WidgetRef ref,
    ThemeSettings settings,
  ) {
    return Row(
      children: [
        _buildIcon(context, Mdi.paletteOutline),
        const SizedBox(width: 13),
        Expanded(
          child: _buildTexts(
            context,
            title: 'Monet 取色',
            subtitle: settings.useMonet ? '跟随系统壁纸' : '已关闭',
          ),
        ),
        Switch(
          value: settings.useMonet,
          onChanged: (value) {
            HapticFeedback.lightImpact();
            ref.read(themeSettingsProvider.notifier).setUseMonet(value);
          },
        ),
      ],
    );
  }

  Widget _buildSeedColorItem(BuildContext context, ThemeSettings settings) {
    final seedColor = settings.seedColor;

    return Row(
      children: [
        _buildIcon(context, Mdi.brushOutline),
        const SizedBox(width: 13),
        Expanded(
          child: _buildTexts(
            context,
            title: '主题色',
            subtitle:
                '#${seedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
                '${settings.useMonet ? ' (Monet 开启时不生效)' : ''}',
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: seedColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Icon(Mdi.chevronRight, color: Theme.of(context).colorScheme.outline),
      ],
    );
  }

  Widget _buildIcon(BuildContext context, IconData icon) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(icon),
    );
  }

  Widget _buildTexts(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleSmall),
        Text(
          subtitle,
          style: textTheme.bodySmall,
          overflow: .ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
