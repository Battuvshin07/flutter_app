import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/story.dart';

/// Manages stories list, user progress, XP and unlock state.
class JourneyProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Story> _stories = [];
  Map<String, UserStoryProgress> _progress = {};
  int _totalXP = 0;
  bool _isLoading = false;
  String? _error;

  // ── Getters ──────────────────────────────────────────────────
  List<Story> get stories => _stories;
  Map<String, UserStoryProgress> get progress => _progress;
  int get totalXP => _totalXP;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _uid => _auth.currentUser?.uid;

  int get completedCount => _progress.values.where((p) => p.quizPassed).length;

  /// Returns the index of the current active story (first non-completed
  /// unlocked story), or the last index if all completed.
  int get currentIndex {
    for (int i = 0; i < _stories.length; i++) {
      if (!isStoryCompleted(_stories[i].id)) return i;
    }
    return _stories.length - 1;
  }

  /// Returns the current active story (first non-completed/unlocked story).
  Story? get currentStory {
    if (_stories.isEmpty) return null;
    final idx = currentIndex;
    return idx < _stories.length ? _stories[idx] : null;
  }

  // ── Unlock logic ─────────────────────────────────────────────
  /// A story is unlocked if:
  ///   - It is the first story (order == 1 or index 0), OR
  ///   - The previous story's quiz has been passed.
  bool isStoryUnlocked(String storyId) {
    final idx = _stories.indexWhere((s) => s.id == storyId);
    if (idx <= 0) return true; // first story always unlocked
    final prevId = _stories[idx - 1].id;
    return _progress[prevId]?.quizPassed == true;
  }

  bool isStoryCompleted(String storyId) {
    return _progress[storyId]?.quizPassed == true;
  }

  bool isStoryStudied(String storyId) {
    return _progress[storyId]?.studied == true;
  }

  UserStoryProgress? getProgress(String storyId) => _progress[storyId];

  // ── Load stories from Firestore ──────────────────────────────
  Future<void> loadStories({bool notify = true}) async {
    if (notify) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final snap = await _db.collection('stories').orderBy('order').get();
      _stories = snap.docs.map((d) => Story.fromFirestore(d)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('JourneyProvider.loadStories error: $e');
    }

    if (notify) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Load user progress ───────────────────────────────────────
  Future<void> loadUserProgress() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      // Per-story progress
      final snap =
          await _db.collection('users').doc(uid).collection('progress').get();
      _progress = {
        for (final doc in snap.docs)
          doc.id: UserStoryProgress.fromFirestore(doc),
      };

      // Total XP
      final userDoc = await _db.collection('users').doc(uid).get();
      _totalXP = (userDoc.data()?['totalXP'] ?? 0) as int;
    } catch (e) {
      debugPrint('JourneyProvider.loadUserProgress error: $e');
    }
    notifyListeners();
  }

  /// Convenience: load stories + user progress together.
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await loadStories(notify: false);
    await loadUserProgress();

    _isLoading = false;
    notifyListeners();
  }

  // ── Mark story as studied ────────────────────────────────────
  Future<bool> markStudied(String storyId) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      final existing = _progress[storyId];
      final alreadyStudied = existing?.studied ?? false;

      final data = UserStoryProgress(
        storyId: storyId,
        studied: true,
        quizPassed: existing?.quizPassed ?? false,
        xpEarned: existing?.xpEarned ?? 0,
      );

      final batch = _db.batch();

      // Update progress doc
      batch.set(
        _db.collection('users').doc(uid).collection('progress').doc(storyId),
        data.toFirestore(),
        SetOptions(merge: true),
      );

      // Increment storiesCompleted only if this is the first time
      if (!alreadyStudied) {
        batch.set(
          _db.collection('users').doc(uid),
          {'storiesCompleted': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      _progress[storyId] = data;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('JourneyProvider.markStudied error: $e');
      return false;
    }
  }

  // ── Submit quiz result ───────────────────────────────────────
  /// Returns the XP earned (0 if failed or already earned).
  Future<int> submitQuizResult({
    required String storyId,
    required int score,
    required int total,
  }) async {
    final uid = _uid;
    if (uid == null) return 0;

    final passThreshold = 0.7;
    final passed = total > 0 && (score / total) >= passThreshold;

    if (!passed) return 0;

    try {
      final story = _stories.firstWhere((s) => s.id == storyId);
      final existing = _progress[storyId];
      final alreadyEarned = (existing?.xpEarned ?? 0) > 0;

      final xpToAward = alreadyEarned ? 0 : story.xpReward;

      final data = UserStoryProgress(
        storyId: storyId,
        studied: true,
        quizPassed: true,
        xpEarned: alreadyEarned ? existing!.xpEarned : story.xpReward,
      );

      final batch = _db.batch();

      // Update progress doc
      batch.set(
        _db.collection('users').doc(uid).collection('progress').doc(storyId),
        data.toFirestore(),
        SetOptions(merge: true),
      );

      // Add XP to user total (only if not already earned)
      if (xpToAward > 0) {
        batch.set(
          _db.collection('users').doc(uid),
          {'totalXP': FieldValue.increment(xpToAward)},
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      _progress[storyId] = data;
      if (xpToAward > 0) _totalXP += xpToAward;
      notifyListeners();

      return xpToAward;
    } catch (e) {
      debugPrint('JourneyProvider.submitQuizResult error: $e');
      return 0;
    }
  }

  // ── Seed sample stories + quizzes ────────────────────────────
  /// Writes 5 sample Mongol-history stories and their quizzes to Firestore.
  /// Call once to populate an empty collection; no-ops if stories exist.
  Future<void> seedSampleData() async {
    _isLoading = true;
    notifyListeners();

    final batch = _db.batch();

    // ── Stories ──────────────────────────────────────────────────
    final stories = [
      {
        'id': 'story_1',
        'title': 'Монголын эзэнт гүрний үүсэл',
        'content': 'Монголын эзэнт гүрэн нь 1206 онд Чингис хаан бүх монгол овгуудыг нэгтгэснээр байгуулагдсан. '
            'Тэмүжин залуу насандаа олон бэрхшээлтэй тулгарч, дайсан овгуудаас зугтаж, '
            'итгэлтэй нөхдөө цуглуулж, аажмаар хүч нөлөөгөө тэлсэн. '
            '1206 оны их хурилтайд бүх монгол овгийн удирдагчид Тэмүжиныг "Чингис хаан" — '
            '"далайн хаан" хэмээн өргөмжилсөн юм.\n\n'
            'Чингис хаан засаг захиргааг шинэчилж, Их засаг хууль тогтоож, '
            'мянгатын тогтолцоог бий болгосноор армийн зохион байгуулалтыг бэхжүүлсэн. '
            'Энэ нь дэлхийн түүхэнд хамгийн том газар нутагтай эзэнт гүрний эхлэл байв.',
        'order': 1,
        'xpReward': 100,
      },
      {
        'id': 'story_2',
        'title': 'Чингис хааны дайн дажин',
        'content': 'Чингис хаан эзэнт гүрнийг байгуулсны дараа зүүн болон баруун зүг рүү тэлж эхэлсэн. '
            '1211 онд Жин улсыг довтолж, 1215 онд нийслэл Бээжинг эзэлсэн. '
            'Хорезм улсын элчид хөнөөгдсөний дараа 1219 онд баруун тийш аян дайн эхэлсэн.\n\n'
            'Монголчууд Самарканд, Бухар зэрэг томоохон хотуудыг эзэлж, '
            'Хорезмийн эзэнт гүрнийг бут ниргэсэн. Чингис хааны цэргийн стратеги — '
            'хурд, сахилга бат, тагнуулын сүлжээ — нь дэлхийн цэргийн түүхэнд шинэ хуудас нээсэн юм.',
        'order': 2,
        'xpReward': 120,
      },
      {
        'id': 'story_3',
        'title': 'Их Монгол Улсын задрал',
        'content': 'Чингис хаан 1227 онд нас барсны дараа эзэнт гүрэн хөвгүүд болон ач нараар удирдагдсан. '
            'Өгөдэй хаан (1229–1241) эцгийнхээ бүтээн байгуулалтыг үргэлжлүүлж, '
            'Европ руу дайн хийсэн. Бат хааны удирдсан баруун аян дайнаар '
            'Орос, Польш, Унгарыг довтолсон.\n\n'
            'Хубилай хааны үед (1260–1294) гүрэн дөрвөн том хаант улсад хуваагдсан: '
            'Юань улс (Хятад), Цагаадайн хаант улс, Алтан Ордын хаант улс, '
            'Ил хаант улс. Тус бүр бие даасан бодлого явуулж эхэлсэн нь задралын шалтгаан болсон.',
        'order': 3,
        'xpReward': 130,
      },
      {
        'id': 'story_4',
        'title': 'Юань улс ба Хубилай хааны үе',
        'content': 'Хубилай хаан 1271 онд Юань улсыг байгуулж, Хятадын нутгийг бүхэлд нь захирсан '
            'анхны монгол хаан болсон. Нийслэлээ Хаанбалиг (өнөөгийн Бээжин) хотод байгуулсан.\n\n'
            'Хубилай хаан худалдаа наймааг дэмжиж, Торгоны замын дагуу олон улсын харилцааг '
            'хөгжүүлсэн. Марко Поло зэрэг европын жуулчид энэ үед Монголд зочилж, '
            'дэлхийд Монголын соёл иргэншлийг таниулсан. Гэвч 1368 онд Мин гүрний '
            'бослогоор Юань улс унасан юм.',
        'order': 4,
        'xpReward': 140,
      },
      {
        'id': 'story_5',
        'title': 'Монголын нууц товчоо',
        'content': 'Монголын нууц товчоо нь 1228 он орчимд бичигдсэн Монголчуудын хамгийн эртний '
            'түүхэн бичиг юм. Энэ нь Чингис хааны угсаа гарал, залуу нас, '
            'эзэнт гүрнийг байгуулсан түүхийг өгүүлдэг.\n\n'
            'Нууц товчоо нь зөвхөн түүхийн бичиг төдийгүй, монгол ардын аман зохиол, '
            'ёс заншил, шашин шүтлэг, нийгмийн бүтцийг ойлгох үнэт эх сурвалж юм. '
            'ЮНЕСКО-гийн Дэлхийн баримтат өвд бүртгэгдсэн энэ бүтээл нь '
            'монголчуудын оюуны соёлын дээд туурвил гэж тооцогддог.',
        'order': 5,
        'xpReward': 150,
      },
    ];

    for (final s in stories) {
      final ref = _db.collection('stories').doc(s['id'] as String);
      batch.set(ref, {
        'title': s['title'],
        'content': s['content'],
        'order': s['order'],
        'xpReward': s['xpReward'],
      });
    }

    // ── Quizzes ─────────────────────────────────────────────────
    final quizzes = [
      {
        'id': 'quiz_1',
        'storyId': 'story_1',
        'questions': [
          {
            'question': 'Чингис хаан хэдэн онд бүх монгол овгийг нэгтгэсэн бэ?',
            'options': ['1162', '1206', '1227', '1260'],
            'correctIndex': 1,
          },
          {
            'question': 'Чингис хааны жинхэнэ нэр юу вэ?',
            'options': ['Өгөдэй', 'Хубилай', 'Тэмүжин', 'Бат'],
            'correctIndex': 2,
          },
          {
            'question': 'Чингис хааны гаргасан хуулийг юу гэж нэрлэдэг вэ?',
            'options': ['Монгол хууль', 'Их засаг', 'Халх журам', 'Тогтоол'],
            'correctIndex': 1,
          },
        ],
      },
      {
        'id': 'quiz_2',
        'storyId': 'story_2',
        'questions': [
          {
            'question': 'Монголчууд Бээжинг хэдэн онд эзэлсэн бэ?',
            'options': ['1206', '1211', '1215', '1219'],
            'correctIndex': 2,
          },
          {
            'question': 'Хорезм улс руу довтлох шалтгаан юу байсан бэ?',
            'options': [
              'Газар нутаг тэлэх',
              'Элчид хөнөөгдсөн',
              'Худалдааны маргаан',
              'Шашны зөрчил'
            ],
            'correctIndex': 1,
          },
          {
            'question': 'Чингис хааны цэргийн гол давуу тал юу байсан бэ?',
            'options': [
              'Том цэргийн тоо',
              'Хурд, сахилга, тагнуул',
              'Далайн цэрэг',
              'Зэвсгийн давуу тал'
            ],
            'correctIndex': 1,
          },
        ],
      },
      {
        'id': 'quiz_3',
        'storyId': 'story_3',
        'questions': [
          {
            'question': 'Чингис хаан хэдэн онд нас барсан бэ?',
            'options': ['1206', '1215', '1227', '1241'],
            'correctIndex': 2,
          },
          {
            'question': 'Баруун Европ руу аян дайн хийсэн хэн бэ?',
            'options': ['Өгөдэй', 'Бат хаан', 'Хубилай', 'Цагаадай'],
            'correctIndex': 1,
          },
          {
            'question': 'Их Монгол Улс хэдэн хаант улсад хуваагдсан бэ?',
            'options': ['2', '3', '4', '5'],
            'correctIndex': 2,
          },
        ],
      },
      {
        'id': 'quiz_4',
        'storyId': 'story_4',
        'questions': [
          {
            'question': 'Хубилай хаан Юань улсыг хэдэн онд байгуулсан бэ?',
            'options': ['1260', '1271', '1294', '1368'],
            'correctIndex': 1,
          },
          {
            'question': 'Юань улсын нийслэл хаана байсан бэ?',
            'options': ['Самарканд', 'Хархорум', 'Хаанбалиг (Бээжин)', 'Сарай'],
            'correctIndex': 2,
          },
          {
            'question': 'Юань улсыг ямар гүрэн мөхөөсөн бэ?',
            'options': ['Сүн гүрэн', 'Мин гүрэн', 'Жин гүрэн', 'Тан гүрэн'],
            'correctIndex': 1,
          },
        ],
      },
      {
        'id': 'quiz_5',
        'storyId': 'story_5',
        'questions': [
          {
            'question': 'Монголын нууц товчоо хэдэн онд бичигдсэн бэ?',
            'options': ['1162', '1206', '1228', '1271'],
            'correctIndex': 2,
          },
          {
            'question':
                'Нууц товчоо ямар олон улсын байгууллагын өвд бүртгэгдсэн бэ?',
            'options': ['ЮНЕСКО', 'НҮБ', 'ЮНИСЕФ', 'ОУВС'],
            'correctIndex': 0,
          },
          {
            'question': 'Нууц товчоо голчлон хэний түүхийг өгүүлдэг вэ?',
            'options': [
              'Хубилай хаан',
              'Бат хаан',
              'Чингис хаан',
              'Өгөдэй хаан'
            ],
            'correctIndex': 2,
          },
        ],
      },
    ];

    for (final q in quizzes) {
      final ref = _db.collection('story_quizzes').doc(q['id'] as String);
      batch.set(ref, {
        'storyId': q['storyId'],
        'questions': q['questions'],
      });
    }

    try {
      await batch.commit();
      debugPrint('Seed data written to Firestore');
    } catch (e) {
      debugPrint('Seed error: $e');
      _error = 'Seed алдаа: $e';
    }

    // Reload
    await init();
  }
}
