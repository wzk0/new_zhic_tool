import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/model/training.dart';

class TrainingNotifier extends Notifier<List<TrainingModule>> {
  @override
  List<TrainingModule> build() {
    return const [];
  }

  void setTraining(List<TrainingModule> training) {
    state = training;
  }

  void clear() {
    state = const [];
  }
}

final trainingProvider =
    NotifierProvider<TrainingNotifier, List<TrainingModule>>(
      TrainingNotifier.new,
    );
