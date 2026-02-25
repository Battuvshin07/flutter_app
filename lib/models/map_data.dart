class MapData {
  final int? mapId;
  final String title;
  final String coordinates;
  final int? eventId;
  final String? description;
  final String? year;
  final String? color;

  MapData({
    this.mapId,
    required this.title,
    required this.coordinates,
    this.eventId,
    this.description,
    this.year,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'map_id': mapId,
      'title': title,
      'coordinates': coordinates,
      'event_id': eventId,
      'description': description,
      'year': year,
      'color': color,
    };
  }

  factory MapData.fromMap(Map<String, dynamic> map) {
    return MapData(
      mapId: map['map_id'] as int?,
      title: map['title'] as String,
      coordinates: map['coordinates'] as String,
      eventId: map['event_id'] as int?,
      description: map['description'] as String?,
      year: map['year'] as String?,
      color: map['color'] as String?,
    );
  }

  MapData copyWith({
    int? mapId,
    String? title,
    String? coordinates,
    int? eventId,
    String? description,
    String? year,
    String? color,
  }) {
    return MapData(
      mapId: mapId ?? this.mapId,
      title: title ?? this.title,
      coordinates: coordinates ?? this.coordinates,
      eventId: eventId ?? this.eventId,
      description: description ?? this.description,
      year: year ?? this.year,
      color: color ?? this.color,
    );
  }
}
