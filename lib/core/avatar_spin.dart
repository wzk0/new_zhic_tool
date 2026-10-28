import 'package:material_ui/material_ui.dart';
import 'package:new_zhic_tool/core/debug.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 首页侧栏与关于页"点图标转圈"彩蛋共用的状态。
///
/// 负责点击次数、转速、持久化以及 [AnimationController] 的生命周期,
/// 页面只关心自己的提示文案。
class AvatarSpinController {
  AvatarSpinController({
    required TickerProvider vsync,
    required this.clickCountKey,
    required this.animationValueKey,
  }) : _controller = AnimationController(vsync: vsync);

  /// 保存在 SharedPreferences 中的点击次数与当前动画进度 key。
  final String clickCountKey;

  final String animationValueKey;

  final AnimationController _controller;

  int _clickCount = 0;

  int get clickCount => _clickCount;

  bool get isSpinning => _clickCount > 0;

  /// 传给 [RotationTransition] 的动画。
  Animation<double> get turns => _controller;

  /// 一圈时长: 点击越多次转得越快, 限制在 30ms ~ 15000ms。
  static int durationForClickCount(int clickCount) {
    if (clickCount <= 0) {
      return 15000;
    }

    return (15000 / clickCount).clamp(30, 15000).toInt();
  }

  /// 恢复上次的点击次数与旋转进度。
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedCount = prefs.getInt(clickCountKey) ?? 0;

      final savedValue = prefs.getDouble(animationValueKey) ?? 0.0;

      if (savedCount <= 0) {
        return;
      }

      _clickCount = savedCount;
      _controller.duration = Duration(
        milliseconds: durationForClickCount(savedCount),
      );
      _controller.value = savedValue.clamp(0.0, 1.0);
      _controller.repeat();
    } catch (e) {
      debugShow('读取头像旋转状态失败: $e');
    }
  }

  /// 记录一次点击, 返回本次的旋转周期(毫秒)。
  int registerClick() {
    _clickCount++;
    final durationMs = durationForClickCount(_clickCount);
    _controller.duration = Duration(milliseconds: durationMs);
    _controller.repeat();
    save();
    return durationMs;
  }

  /// 停止旋转并清零。
  void reset() {
    _clickCount = 0;
    _controller.stop();
    save();
  }

  Future<void> save() async {
    // AnimationController 销毁后不可再读取, 需先同步取值。
    final clickCount = _clickCount;
    final animationValue = _controller.value;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(clickCountKey, clickCount);
      await prefs.setDouble(animationValueKey, animationValue);
    } catch (e) {
      debugShow('保存头像旋转状态失败: $e');
    }
  }

  void dispose() {
    save();
    _controller.dispose();
  }
}
