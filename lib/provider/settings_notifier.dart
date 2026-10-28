import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用外观与显示设置。
class AppSettings {
  const AppSettings({
    this.useMonet = true,
    this.seedColorValue,
    this.highlightTodayOnly = false,
  });

  /// 默认种子色, 与旧版本一致。
  static const Color defaultSeedColor = Colors.deepPurple;

  /// 是否跟随系统壁纸取色(Android 12+)。
  final bool useMonet;

  /// 自定义种子色的 ARGB 值; null 表示未自定义。
  final int? seedColorValue;

  /// 课表是否仅高亮"当天"; 关闭时每周的同一星期都会高亮。
  final bool highlightTodayOnly;

  Color get seedColor =>
      seedColorValue == null ? defaultSeedColor : Color(seedColorValue!);

  AppSettings copyWith({
    bool? useMonet,
    int? seedColorValue,
    bool? highlightTodayOnly,
    bool clearSeedColor = false,
  }) {
    return AppSettings(
      useMonet: useMonet ?? this.useMonet,
      seedColorValue: clearSeedColor
          ? null
          : seedColorValue ?? this.seedColorValue,
      highlightTodayOnly: highlightTodayOnly ?? this.highlightTodayOnly,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _useMonetKey = 'theme_use_monet';
  static const String _seedColorKey = 'theme_seed_color';
  static const String _highlightTodayOnlyKey = 'schedule_highlight_today_only';

  @override
  AppSettings build() {
    Future.microtask(_restore);
    return const AppSettings();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      state = AppSettings(
        useMonet: prefs.getBool(_useMonetKey) ?? true,
        seedColorValue: prefs.getInt(_seedColorKey),
        highlightTodayOnly: prefs.getBool(_highlightTodayOnlyKey) ?? false,
      );
    } catch (e) {
      debugShow('读取设置失败: $e');
    }
  }

  Future<void> setUseMonet(bool value) async {
    if (state.useMonet == value) {
      return;
    }

    state = state.copyWith(useMonet: value);

    await _persist();
  }

  Future<void> setHighlightTodayOnly(bool value) async {
    if (state.highlightTodayOnly == value) {
      return;
    }

    state = state.copyWith(highlightTodayOnly: value);

    await _persist();
  }

  Future<void> setSeedColor(Color color) async {
    final value = color.toARGB32();

    if (state.seedColorValue == value) {
      return;
    }

    state = state.copyWith(seedColorValue: value);

    await _persist();
  }

  Future<void> resetSeedColor() async {
    if (state.seedColorValue == null) {
      return;
    }

    state = state.copyWith(clearSeedColor: true);

    await _persist();
  }

  Future<void> _persist() async {
    final useMonet = state.useMonet;
    final seedColorValue = state.seedColorValue;
    final highlightTodayOnly = state.highlightTodayOnly;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_useMonetKey, useMonet);
      await prefs.setBool(_highlightTodayOnlyKey, highlightTodayOnly);
      if (seedColorValue == null) {
        await prefs.remove(_seedColorKey);
      } else {
        await prefs.setInt(_seedColorKey, seedColorValue);
      }
    } catch (e) {
      debugShow('保存设置失败: $e');
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
