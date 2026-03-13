// ═══════════════════════════════════════════════════════════════
//  Seed Achievements - Creates level-based achievements in Firestore
//  Run this once to populate the achievements collection
// ═══════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> seedAchievements() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = FirebaseFirestore.instance;

  final achievements = [
    {
      'id': 'level_2_starter',
      'title': 'Эхлэл',
      'description': 'Level 2-д хүрлээ',
      'icon': 'shield',
      'expReward': 50,
      'conditionType': 'level',
      'conditionValue': 2,
      'sortOrder': 1,
    },
    {
      'id': 'level_4_learner',
      'title': 'Сурагч',
      'description': 'Level 4-д хүрлээ',
      'icon': 'medal',
      'expReward': 100,
      'conditionType': 'level',
      'conditionValue': 4,
      'sortOrder': 2,
    },
    {
      'id': 'level_7_hero',
      'title': 'Баатар',
      'description': 'Level 7-д хүрлээ',
      'icon': 'star',
      'expReward': 200,
      'conditionType': 'level',
      'conditionValue': 7,
      'sortOrder': 3,
    },
    {
      'id': 'level_10_king',
      'title': 'Хаан',
      'description': 'Level 10-д хүрлээ',
      'icon': 'trophy',
      'expReward': 500,
      'conditionType': 'level',
      'conditionValue': 10,
      'sortOrder': 4,
    },
  ];

  final batch = db.batch();

  for (final achievement in achievements) {
    final docRef =
        db.collection('achievements').doc(achievement['id'] as String);
    batch.set(docRef, achievement);
    print('✓ Added: ${achievement['title']}');
  }

  await batch.commit();
  print('\n✅ Successfully seeded ${achievements.length} achievements!');
}

void main() async {
  try {
    await seedAchievements();
  } catch (e) {
    print('❌ Error seeding achievements: $e');
  }
}
