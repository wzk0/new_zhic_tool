import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/model/training.dart';

class TrainingNotifier extends Notifier<List<TrainingModule>> {
  @override
  List<TrainingModule> build() {
    return const [];
  }

  /// WebView 获取 HTML 后调用
  void setTraining(List<TrainingModule> training) {
    state = training;
  }

  /// 清空数据
  void clear() {
    state = const [];
  }
}

/// 培养方案数据 Provider
///
/// 不使用 autoDispose，
///
/// 页面重新进入时可以保留内存数据，
/// 同时后台重新加载最新数据。
final trainingProvider =
    NotifierProvider<TrainingNotifier, List<TrainingModule>>(
      TrainingNotifier.new,
    );
