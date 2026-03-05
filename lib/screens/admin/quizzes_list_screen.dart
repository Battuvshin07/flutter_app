import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/quiz_model.dart';
import 'shared_admin_widgets.dart';
import 'quiz_edit_screen.dart';

/// List screen for Quizzes with search, sort, add.
class QuizzesListScreen extends StatefulWidget {
  const QuizzesListScreen({super.key});

  @override
  State<QuizzesListScreen> createState() => _QuizzesListScreenState();
}

class _QuizzesListScreenState extends State<QuizzesListScreen> {
  String _searchQuery = '';

  List<QuizModel> _filtered(List<QuizModel> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((qz) => qz.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Quizzes'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentGold,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuizEditScreen()),
        ),
        child: const Icon(Icons.add_rounded, color: AppTheme.background),
      ),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Хайх... (гарчиг)',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                if (!admin.quizzesLoaded) return const AdminLoadingState();
                final items = _filtered(admin.quizzes);
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Quiz олдсонгүй.\nШинээр нэмнэ үү.',
                    icon: Icons.quiz_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.pagePadding),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _QuizTile(
                      item: item,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizEditScreen(quiz: item),
                        ),
                      ),
                      onDelete: () async {
                        final confirmed = await showDeleteConfirmDialog(
                          context,
                          itemName: item.title,
                        );
                        if (confirmed && context.mounted) {
                          await admin.deleteQuiz(item.id!);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  final QuizModel item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _QuizTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = {
          'easy': const Color(0xFF4ADE80),
          'medium': AppTheme.streakOrange,
          'hard': AppTheme.crimson,
        }[item.difficulty] ??
        AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFA78BFA).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.quiz_rounded,
                color: Color(0xFFA78BFA),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTheme.captionBold.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(item.difficulty, diffColor),
                      const SizedBox(width: 6),
                      _badge(
                        item.isPublished ? 'Published' : 'Draft',
                        item.isPublished
                            ? const Color(0xFF4ADE80)
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.questions.length} Q',
                        style: AppTheme.caption.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppTheme.crimson,
              onPressed: onDelete,
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
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
}
