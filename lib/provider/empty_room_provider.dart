import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_zhic_tool/model/empty_room.dart';
import 'package:new_zhic_tool/service/empty_room_service.dart';

final emptyRoomProvider = FutureProvider.autoDispose
    .family<List<EmptyRoom>, EmptyRoomQuery>((ref, query) {
      return EmptyRoomService.instance.fetchRooms(
        week: query.week,
        semesterId: query.semesterId,
      );
    });

class EmptyRoomQuery {
  const EmptyRoomQuery({required this.week, required this.semesterId});

  final int week;

  /// ScheduleState 中的 semester.id 是 String。
  final String semesterId;

  @override
  bool operator ==(Object other) {
    return other is EmptyRoomQuery &&
        other.week == week &&
        other.semesterId == semesterId;
  }

  @override
  int get hashCode {
    return Object.hash(week, semesterId);
  }
}
