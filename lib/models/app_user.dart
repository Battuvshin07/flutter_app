// ════════════════════════════════════════════════════════
//  AppUser – Firestore-backed user model
//  Collection: users/{uid}
// ════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/xp_helpers.dart' as xp;

// ── Achievement (users/{uid}/achievements/{id}) ───────────────────
class AppAchievement {
  final String id;
  final String title;
  final String icon; // 'trophy' | 'shield' | 'medal' | 'star' …
  final bool unlocked; // true when this achievement has been earned
  final DateTime? unlockedAt;

  const AppAchievement({
    required this.id,
    required this.title,
    this.icon = 'trophy',
    this.unlocked = false,
    this.unlockedAt,
  });

  factory AppAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final unlockedAt = (data['unlockedAt'] as Timestamp?)?.toDate();
    // Consider an achievement unlocked if unlockedAt is present or
    // an explicit 'unlocked' boolean field is true
    final unlocked = (data['unlocked'] as bool? ?? false) || unlockedAt != null;
    return AppAchievement(
      id: doc.id,
      title: data['title'] as String? ?? 'Амжилт',
      icon: data['icon'] as String? ?? 'trophy',
      unlocked: unlocked,
      unlockedAt: unlockedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'icon': icon,
        'unlocked': unlocked,
        if (unlockedAt != null) 'unlockedAt': Timestamp.fromDate(unlockedAt!),
      };
}

// ── AppUser ───────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String name;
  final String? displayName;
  final String email;
  final String role; // 'user' | 'admin' | 'superAdmin'
  final String? photoUrl;
  final String? bio;
  final String preferredLanguage; // 'mn' | 'en' | 'ru'
  final int totalXP;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? lastActiveDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int storiesCompleted;
  final int quizzesCompleted;
  final bool darkMode;
  final List<AppAchievement> achievements;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.displayName,
    this.role = 'user',
    this.photoUrl,
    this.bio,
    this.preferredLanguage = 'mn',
    this.totalXP = 0,
    this.isActive = true,
    this.lastLogin,
    this.lastActiveDate,
    this.createdAt,
    this.updatedAt,
    this.storiesCompleted = 0,
    this.quizzesCompleted = 0,
    this.darkMode = false,
    this.achievements = const [],
  });

  /// Create AppUser from a Firestore document snapshot.
  /// Gracefully handles missing / null fields.
  factory AppUser.fromFirestore(
    DocumentSnapshot doc, {
    List<AppAchievement> achievements = const [],
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Support both 'photoUrl' (new) and 'avatarUrl' (legacy)
    final photoUrl =
        data['photoUrl'] as String? ?? data['avatarUrl'] as String?;

    return AppUser(
      id: doc.id,
      name: data['name'] as String? ??
          data['displayName'] as String? ??
          'Хэрэглэгч',
      displayName: data['displayName'] as String?,
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      photoUrl: (photoUrl?.isEmpty ?? true) ? null : photoUrl,
      bio: data['bio'] as String?,
      preferredLanguage: data['preferredLanguage'] as String? ?? 'mn',
      totalXP: (data['totalXP'] as num? ?? 0).toInt(),
      isActive: data['isActive'] as bool? ?? true,
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      storiesCompleted: (data['storiesCompleted'] as num? ?? 0).toInt(),
      quizzesCompleted: (data['quizzesCompleted'] as num? ?? 0).toInt(),
      darkMode: data['darkMode'] as bool? ?? false,
      achievements: achievements,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'displayName': displayName,
        'email': email,
        'role': role,
        'photoUrl': photoUrl,
        'bio': bio,
        'preferredLanguage': preferredLanguage,
        'totalXP': totalXP,
        'isActive': isActive,
        'storiesCompleted': storiesCompleted,
        'quizzesCompleted': quizzesCompleted,
        'darkMode': darkMode,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  AppUser copyWith({
    String? name,
    String? displayName,
    String? email,
    String? role,
    String? photoUrl,
    String? bio,
    String? preferredLanguage,
    int? totalXP,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? lastActiveDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? storiesCompleted,
    int? quizzesCompleted,
    bool? darkMode,
    List<AppAchievement>? achievements,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        role: role ?? this.role,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        totalXP: totalXP ?? this.totalXP,
        isActive: isActive ?? this.isActive,
        lastLogin: lastLogin ?? this.lastLogin,
        lastActiveDate: lastActiveDate ?? this.lastActiveDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        storiesCompleted: storiesCompleted ?? this.storiesCompleted,
        quizzesCompleted: quizzesCompleted ?? this.quizzesCompleted,
        darkMode: darkMode ?? this.darkMode,
        achievements: achievements ?? this.achievements,
      );

  bool get isAdmin => role == 'admin' || role == 'superAdmin';

  /// Current level derived from [totalXP].
  int get level => xp.levelFromXP(totalXP);

  /// Alias for [totalXP] — use when you want the field named `exp`.
  int get exp => totalXP;

  /// Display name fallback chain: displayName → name → 'Хэрэглэгч'
  String get effectiveName =>
      (displayName?.isNotEmpty == true ? displayName : name) ?? 'Хэрэглэгч';

  /// Initials for avatar placeholder (up to 2 chars)
  String get initials {
    final n = effectiveName.trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n.substring(0, n.length.clamp(1, 2)).toUpperCase();
  }
}
