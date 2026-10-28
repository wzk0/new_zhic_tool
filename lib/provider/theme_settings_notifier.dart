import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题设置: 是否使用 Monet(动态取色) 与自定义种子色。
class ThemeSettings {
  const ThemeSettings({this.useMonet = true, this.seedColorValue});

  /// 默认种子色, 与旧版本一致。
  static const Color defaultSeedColor = Colors.deepPurple;

  /// 是否跟随系统壁纸取色(Android 12+)。
  final bool useMonet;

  /// 自定义种子色的 ARGB 值; null 表示未自定义。
  final int? seedColorValue;

  Color get seedColor =>
      seedColorValue == null ? defaultSeedColor : Color(seedColorValue!);

  ThemeSettings copyWith({bool? useMonet, int? seedColorValue}) {
    return ThemeSettings(
      useMonet: useMonet ?? this.useMonet,
      seedColorValue: seedColorValue ?? this.seedColorValue,
    );
  }
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  static const String _useMonetKey = 'theme_use_monet';
  static const String _seedColorKey = 'theme_seed_color';

  @override
  ThemeSettings build() {
    Future.microtask(_restore);
    return const ThemeSettings();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      state = ThemeSettings(
        useMonet: prefs.getBool(_useMonetKey) ?? true,
        seedColorValue: prefs.getInt(_seedColorKey),
      );
    } catch (e) {
      debugShow('读取主题设置失败: $e');
    }
  }

  Future<void> setUseMonet(bool value) async {
    if (state.useMonet == value) {
      return;
    }

    state = state.copyWith(useMonet: value);

    await _persist();
  }

  Future<void> setSeedColor(Color color) async {
    final value = color.toARGB32();

    if (state.seedColorValue == value) {
      return;
    }

    state = ThemeSettings(useMonet: state.useMonet, seedColorValue: value);

    await _persist();
  }

  Future<void> resetSeedColor() async {
    if (state.seedColorValue == null) {
      return;
    }

    state = ThemeSettings(useMonet: state.useMonet);

    await _persist();
  }

  Future<void> _persist() async {
    final useMonet = state.useMonet;
    final seedColorValue = state.seedColorValue;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useMonetKey, useMonet);
      if (seedColorValue == null) {
        await prefs.remove(_seedColorKey);
      } else {
        await prefs.setInt(_seedColorKey, seedColorValue);
      }
    } catch (e) {
      debugShow('保存主题设置失败: $e');
    }
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );
