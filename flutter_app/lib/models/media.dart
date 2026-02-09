class Media {
  final int? mediaId;
  final String type; // 'image', 'video', 'audio'
  final String url;
  final int? relatedId;

  Media({
    this.mediaId,
    required this.type,
    required this.url,
    this.relatedId,
  });

  Map<String, dynamic> toMap() {
    return {
      'media_id': mediaId,
      'type': type,
      'url': url,
      'related_id': relatedId,
    };
  }

  factory Media.fromMap(Map<String, dynamic> map) {
    return Media(
      mediaId: map['media_id'] as int?,
      type: map['type'] as String,
      url: map['url'] as String,
      relatedId: map['related_id'] as int?,
    );
  }

  Media copyWith({
    int? mediaId,
    String? type,
    String? url,
    int? relatedId,
  }) {
    return Media(
      mediaId: mediaId ?? this.mediaId,
      type: type ?? this.type,
      url: url ?? this.url,
      relatedId: relatedId ?? this.relatedId,
    );
  }
}
