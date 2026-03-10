import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Firestore model for `videos/{videoId}`.
///
/// Fields mirror the admin VideoEditScreen form and the
/// backend Video.model.js Mongoose schema.
class VideoModel {
  final String? id;
  final String youtubeId;
  final String title;
  final String subtitle;
  final String duration;

  /// Material icon name string (e.g. 'shield', 'landscape').
  /// Resolve to [IconData] via [iconFromName].
  final String iconName;

  /// 6-char hex color without '#' (e.g. 'F4C84A').
  /// Resolve to [Color] via [colorFromHex].
  final String accentHex;

  final int order;
  final bool isPublished;
  final DateTime? updatedAt;
  final String? updatedBy;

  VideoModel({
    this.id,
    required this.youtubeId,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.iconName,
    required this.accentHex,
    this.order = 0,
    this.isPublished = true,
    this.updatedAt,
    this.updatedBy,
  });

  // ── Static helpers ──────────────────────────────────────────

  static IconData iconFromName(String name) {
    switch (name) {
      case 'shield':
        return Icons.shield_rounded;
      case 'route':
        return Icons.route_rounded;
      case 'landscape':
        return Icons.landscape_rounded;
      case 'swap_horiz':
        return Icons.swap_horiz_rounded;
      case 'history_edu':
        return Icons.history_edu_rounded;
      case 'museum':
        return Icons.museum_rounded;
      case 'play_circle':
        return Icons.play_circle_outline_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'anchor':
        return Icons.anchor_rounded;
      case 'temple':
        return Icons.temple_buddhist_rounded;
      default:
        return Icons.video_library_rounded;
    }
  }

  static Color colorFromHex(String hex) {
    final h = hex.replaceAll('#', '').padLeft(6, '0');
    return Color(int.parse('FF$h', radix: 16));
  }

  // ── Firestore ───────────────────────────────────────────────

  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VideoModel(
      id: doc.id,
      youtubeId: d['youtubeId'] ?? '',
      title: d['title'] ?? '',
      subtitle: d['subtitle'] ?? '',
      duration: d['duration'] ?? '',
      iconName: d['iconName'] ?? 'video_library',
      accentHex: d['accentHex'] ?? 'F4C84A',
      order: d['order'] ?? 0,
      isPublished: d['isPublished'] ?? true,
      updatedAt: _parseTimestamp(d['updatedAt']),
      updatedBy: d['updatedBy'],
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'youtubeId': youtubeId,
      'title': title,
      'subtitle': subtitle,
      'duration': duration,
      'iconName': iconName,
      'accentHex': accentHex,
      'order': order,
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  VideoModel copyWith({
    String? id,
    String? youtubeId,
    String? title,
    String? subtitle,
    String? duration,
    String? iconName,
    String? accentHex,
    int? order,
    bool? isPublished,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return VideoModel(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      duration: duration ?? this.duration,
      iconName: iconName ?? this.iconName,
      accentHex: accentHex ?? this.accentHex,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
