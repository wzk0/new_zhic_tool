class EmptyRoom {
  const EmptyRoom({
    this.id,
    this.roomName = '未知',
    this.buildingName = '未知',
    this.seats = 0,
    this.occupations = const [],
    this.rawData = const {},
  });

  final dynamic id;

  final String roomName;

  final String buildingName;

  final int seats;

  final List<RoomOccupation> occupations;

  final Map<String, dynamic> rawData;

  factory EmptyRoom.fromJson(Map<String, dynamic> json) {
    final rawOccupations = json['roomWeekUnitOccupationVms'];

    return EmptyRoom(
      id: json['id'],
      roomName: json['roomNameZh']?.toString() ?? '未知',
      buildingName: json['buildingNameZh']?.toString() ?? '未知',
      seats: int.tryParse(json['seatsForLesson']?.toString() ?? '') ?? 0,
      occupations: rawOccupations is List
          ? rawOccupations
                .whereType<Map<String, dynamic>>()
                .map(RoomOccupation.fromJson)
                .toList()
          : const [],
      rawData: json,
    );
  }
}

class RoomOccupation {
  const RoomOccupation({this.weekday, this.unit, this.activityType});

  final int? weekday;

  final int? unit;

  final dynamic activityType;

  bool get isBusy => activityType != null;

  factory RoomOccupation.fromJson(Map<String, dynamic> json) {
    return RoomOccupation(
      weekday: int.tryParse(json['weekday']?.toString() ?? ''),
      unit: int.tryParse(json['unit']?.toString() ?? ''),
      activityType: json['activityType'],
    );
  }
}
