import 'package:flutter/material.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/culture_model.dart';
import '../../data/models/person_model.dart';
import '../../data/models/quiz_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/story_model.dart';
import '../../theme/app_theme.dart';
import 'culture_edit_screen.dart';
import 'person_edit_screen.dart';
import 'person_detail_edit_screen.dart';
import 'quiz_edit_screen.dart';
import 'event_edit_screen.dart';
import 'story_edit_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  Admin Collection Configuration
//  Maps each Firestore collection to its UI/behaviour config
//  so a single AdminListScreen can render any collection.
// ══════════════════════════════════════════════════════════════════

class AdminCollectionConfig {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final String searchHint;
  final String emptyMessage;

  /// Pull typed list from provider.
  final List<dynamic> Function(AdminProvider) getItems;

  /// Whether the stream has fired at least once.
  final bool Function(AdminProvider) isLoaded;

  /// Item → display title.
  final String Function(dynamic) getItemTitle;

  /// Item → display subtitle.
  final String Function(dynamic) getItemSubtitle;

  /// Item → Firestore doc id.
  final String? Function(dynamic) getItemId;

  /// Delete by id via provider.
  final Future<bool> Function(AdminProvider, String) deleteItem;

  /// Navigate to edit screen with existing item.
  final Widget Function(dynamic item) editScreenBuilder;

  /// Navigate to create screen (no item).
  final Widget Function() createScreenBuilder;

  /// Custom search filter.
  final bool Function(dynamic item, String query) searchMatcher;

  /// Optional badge widgets per item (difficulty, publish status, etc.)
  final List<Widget> Function(dynamic item)? badgeBuilder;

  /// Optional extra action buttons per tile (e.g. Person Detail).
  final List<Widget> Function(BuildContext context, dynamic item)?
      extraActionsBuilder;

  const AdminCollectionConfig({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.searchHint,
    required this.emptyMessage,
    required this.getItems,
    required this.isLoaded,
    required this.getItemTitle,
    required this.getItemSubtitle,
    required this.getItemId,
    required this.deleteItem,
    required this.editScreenBuilder,
    required this.createScreenBuilder,
    required this.searchMatcher,
    this.badgeBuilder,
    this.extraActionsBuilder,
  });
}

// ══════════════════════════════════════════════════════════════════
//  Collection configs — one per Firestore collection
// ══════════════════════════════════════════════════════════════════

final Map<String, AdminCollectionConfig> adminCollections = {
  // ── Culture ──────────────────────────────────────────────────
  'cultures': AdminCollectionConfig(
    key: 'cultures',
    title: 'Culture',
    icon: Icons.theater_comedy_rounded,
    color: AppTheme.accentGold,
    searchHint: 'Хайх... (гарчиг)',
    emptyMessage: 'Соёлын контент олдсонгүй.\nШинээр нэмнэ үү.',
    getItems: (p) => p.cultures,
    isLoaded: (p) => p.culturesLoaded,
    getItemTitle: (item) => (item as CultureModel).title,
    getItemSubtitle: (item) => (item as CultureModel).description,
    getItemId: (item) => (item as CultureModel).id,
    deleteItem: (p, id) => p.deleteCulture(id),
    editScreenBuilder: (item) =>
        CultureEditScreen(culture: item as CultureModel),
    createScreenBuilder: () => const CultureEditScreen(),
    searchMatcher: (item, q) =>
        (item as CultureModel).title.toLowerCase().contains(q),
  ),

  // ── Persons ──────────────────────────────────────────────────
  'persons': AdminCollectionConfig(
    key: 'persons',
    title: 'Persons',
    icon: Icons.person_search_rounded,
    color: const Color(0xFF60A5FA),
    searchHint: 'Хайх... (нэр)',
    emptyMessage: 'Түүхэн хүн олдсонгүй.\nШинээр нэмнэ үү.',
    getItems: (p) => p.persons,
    isLoaded: (p) => p.personsLoaded,
    getItemTitle: (item) => (item as PersonModel).name,
    getItemSubtitle: (item) {
      final person = item as PersonModel;
      final parts = <String>[
        if (person.birthYear != null) '${person.birthYear}',
        if (person.deathYear != null) '${person.deathYear}',
      ];
      return parts.join(' – ');
    },
    getItemId: (item) => (item as PersonModel).id,
    deleteItem: (p, id) => p.deletePerson(id),
    editScreenBuilder: (item) => PersonEditScreen(person: item as PersonModel),
    createScreenBuilder: () => const PersonEditScreen(),
    searchMatcher: (item, q) =>
        (item as PersonModel).name.toLowerCase().contains(q),
    extraActionsBuilder: (ctx, item) {
      final person = item as PersonModel;
      return [
        IconButton(
          icon: const Icon(Icons.article_outlined, size: 20),
          color: AppTheme.accentGold,
          tooltip: 'Person Detail',
          onPressed: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => PersonDetailEditScreen(personId: person.id!),
            ),
          ),
        ),
      ];
    },
  ),

  // ── Quizzes ──────────────────────────────────────────────────
  'quizzes': AdminCollectionConfig(
    key: 'quizzes',
    title: 'Quizzes',
    icon: Icons.quiz_rounded,
    color: const Color(0xFFA78BFA),
    searchHint: 'Хайх... (гарчиг)',
    emptyMessage: 'Quiz олдсонгүй.\nШинээр нэмнэ үү.',
    getItems: (p) => p.quizzes,
    isLoaded: (p) => p.quizzesLoaded,
    getItemTitle: (item) => (item as QuizModel).title,
    getItemSubtitle: (item) {
      final quiz = item as QuizModel;
      return '${quiz.questions.length} асуулт • ${quiz.difficulty}';
    },
    getItemId: (item) => (item as QuizModel).id,
    deleteItem: (p, id) => p.deleteQuiz(id),
    editScreenBuilder: (item) => QuizEditScreen(quiz: item as QuizModel),
    createScreenBuilder: () => const QuizEditScreen(),
    searchMatcher: (item, q) =>
        (item as QuizModel).title.toLowerCase().contains(q),
    badgeBuilder: (item) {
      final quiz = item as QuizModel;
      final diffColor = {
            'easy': const Color(0xFF4ADE80),
            'medium': AppTheme.streakOrange,
            'hard': AppTheme.crimson,
          }[quiz.difficulty] ??
          AppTheme.textSecondary;
      return [
        _buildBadge(quiz.difficulty, diffColor),
        _buildBadge(
          quiz.isPublished ? 'Published' : 'Draft',
          quiz.isPublished ? const Color(0xFF4ADE80) : AppTheme.textSecondary,
        ),
      ];
    },
  ),

  // ── Events ───────────────────────────────────────────────────
  'events': AdminCollectionConfig(
    key: 'events',
    title: 'Events',
    icon: Icons.history_edu_rounded,
    color: const Color(0xFF38BDF8),
    searchHint: 'Хайх... (гарчиг, он)',
    emptyMessage: 'Түүхэн үйл явдал олдсонгүй.\nШинээр нэмнэ үү.',
    getItems: (p) => p.events,
    isLoaded: (p) => p.eventsLoaded,
    getItemTitle: (item) => (item as EventModel).title,
    getItemSubtitle: (item) {
      final e = item as EventModel;
      return e.date.isEmpty ? 'Он тодорхойгүй' : e.date;
    },
    getItemId: (item) => (item as EventModel).id,
    deleteItem: (p, id) => p.deleteEvent(id),
    editScreenBuilder: (item) => EventEditScreen(event: item as EventModel),
    createScreenBuilder: () => const EventEditScreen(),
    searchMatcher: (item, q) {
      final e = item as EventModel;
      return e.title.toLowerCase().contains(q) ||
          e.date.toLowerCase().contains(q);
    },
  ),

  // ── Stories ──────────────────────────────────────────────────
  'stories': AdminCollectionConfig(
    key: 'stories',
    title: 'Stories',
    icon: Icons.menu_book_rounded,
    color: const Color(0xFFF472B6),
    searchHint: 'Хайх... (гарчиг)',
    emptyMessage: 'Түүх олдсонгүй.\nШинээр нэмнэ үү.',
    getItems: (p) => p.stories,
    isLoaded: (p) => p.storiesLoaded,
    getItemTitle: (item) {
      final s = item as StoryModel;
      return '${s.order}. ${s.title}';
    },
    getItemSubtitle: (item) {
      final s = item as StoryModel;
      final status = s.isPublished ? 'Нийтлэгдсэн' : 'Ноорог';
      return '${s.xpReward} XP • $status';
    },
    getItemId: (item) => (item as StoryModel).id,
    deleteItem: (p, id) => p.deleteStory(id),
    editScreenBuilder: (item) => StoryEditScreen(story: item as StoryModel),
    createScreenBuilder: () => const StoryEditScreen(),
    searchMatcher: (item, q) {
      final s = item as StoryModel;
      return s.title.toLowerCase().contains(q) ||
          s.subtitle.toLowerCase().contains(q);
    },
    badgeBuilder: (item) {
      final s = item as StoryModel;
      return [
        _buildBadge(
          '${s.xpReward} XP',
          AppTheme.accentGold,
        ),
        _buildBadge(
          s.isPublished ? 'Published' : 'Draft',
          s.isPublished ? const Color(0xFF4ADE80) : AppTheme.textSecondary,
        ),
      ];
    },
  ),
};

// ── Helper badge builder ──────────────────────────────────────
Widget _buildBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(
      text,
      style: AppTheme.chip.copyWith(color: color, fontSize: 9),
    ),
  );
}
