import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/provider/settings_notifier.dart';
import 'package:new_zhic_tool/widget_tree.dart';

void main() {
  runApp(const ProviderScope(child: Zhanghuan()));
}

class Zhanghuan extends ConsumerWidget {
  const Zhanghuan({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp(
          theme: _buildTheme(Brightness.light, lightDynamic, settings),
          darkTheme: _buildTheme(Brightness.dark, darkDynamic, settings),
          home: const WidgetTree(),
        );
      },
    );
  }

  /// Monet 取色开启且系统提供动态配色时用动态配色, 否则用自定义种子色生成。
  ThemeData _buildTheme(
    Brightness brightness,
    ColorScheme? dynamicScheme,
    AppSettings settings,
  ) {
    final colorScheme = settings.useMonet && dynamicScheme != null
        ? dynamicScheme
        : ColorScheme.fromSeed(
            seedColor: settings.seedColor,
            brightness: brightness,
          );

    return ThemeData(colorScheme: colorScheme, brightness: brightness);
  }
}
