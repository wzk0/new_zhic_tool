import 'package:new_zhic_tool/model/empty_room.dart';
import 'package:new_zhic_tool/service/network_service.dart';

class EmptyRoomService {
  EmptyRoomService._();

  static final EmptyRoomService instance = EmptyRoomService._();

  Future<List<EmptyRoom>> fetchRooms({
    required int week,
    required String semesterId,
  }) async {
    final url =
        'https://eams.tjzhic.edu.cn/student/for-std/'
        'room-week-occupation/semester/$semesterId/search';

    final data = await NetworkService.instance.post(
      url,
      withCookies: true,
      body: {
        'teachingWeek': week,
        'campus': 2,
        'buildingAssocs': [],
        'roomAssocs': [],
        'seatsForLessonLowerLimit': '',
        'seatsForLessonUpperLimit': '',
        'enabled': 1,
      },
    );

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(EmptyRoom.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map<String, dynamic>>()
          .map(EmptyRoom.fromJson)
          .toList();
    }

    throw const FormatException('空教室接口返回的数据格式异常');
  }
}
