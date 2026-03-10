import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../components/admin/glass_card.dart';
import '../../providers/admin_provider.dart';
import 'shared_admin_widgets.dart';

/// Read-only admin screen for viewing user progress records.
/// Supports admin reset (delete) of individual progress records.
class ProgressListScreen extends StatefulWidget {
  const ProgressListScreen({super.key});

  @override
  State<ProgressListScreen> createState() => _ProgressListScreenState();
}

class _ProgressListScreenState extends State<ProgressListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadProgress();
    });
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((p) {
      final userId =
          (p['userId'] ?? p['user_id'] ?? '').toString().toLowerCase();
      final storyId =
          (p['storyId'] ?? p['quiz_id'] ?? '').toString().toLowerCase();
      return userId.contains(q) || storyId.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(context, title: 'Progress'),
      body: Column(
        children: [
          AdminSearchField(
            hint: 'Хайх... (userId, storyId)',
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          Expanded(
            child: Consumer<AdminProvider>(
              builder: (context, admin, _) {
                if (admin.isLoading && admin.progress.isEmpty) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.accentGold),
                  );
                }
                final items = _filtered(admin.progress);
                if (items.isEmpty) {
                  return const AdminEmptyState(
                    message: 'Хэрэглэгчийн ахицын мэдэгдэл олдсонгүй.',
                    icon: Icons.bar_chart_rounded,
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.accentGold,
                  onRefresh: () => admin.loadProgress(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.pagePadding),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ProgressTile(
                        data: item,
                        onReset: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppTheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusLg),
                                side: const BorderSide(
                                    color: AppTheme.cardBorder),
                              ),
                              title: Text('Ахицыг устгах уу?',
                                  style: AppTheme.sectionTitle),
                              content: Text(
                                'Энэ хэрэглэгчийн ахицын мэдэгдлийг устгахдаа итгэлтэй байна уу?',
                                style: AppTheme.body,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Цуцлах',
                                      style: AppTheme.caption.copyWith(
                                          color: AppTheme.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Устгах',
                                      style: AppTheme.caption
                                          .copyWith(color: AppTheme.crimson)),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && context.mounted) {
                            await Provider.of<AdminProvider>(context,
                                    listen: false)
                                .deleteProgress(
                              item['id'] ?? '',
                              userId: item['userId'],
                            );
                            if (context.mounted) {
                              Provider.of<AdminProvider>(context, listen: false)
                                  .loadProgress();
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onReset;

  const _ProgressTile({required this.data, required this.onReset});

  @override
  Widget build(BuildContext context) {
    final userId = data['userId'] ?? data['user_id'] ?? '—';
    final storyId = data['storyId'] ?? data['quiz_id'] ?? data['id'] ?? '—';
    final studied = data['studied'] ?? data['completed'] ?? false;
    final quizPassed = data['quizPassed'] ?? false;
    final xpEarned = data['xpEarned'] ?? data['score'] ?? 0;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: AppTheme.accentGold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User: ${_truncate(userId.toString(), 20)}',
                      style: AppTheme.captionBold.copyWith(fontSize: 11),
                    ),
                    Text(
                      'Story/Quiz: ${_truncate(storyId.toString(), 20)}',
                      style: AppTheme.chip.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt_rounded,
                    size: 20, color: AppTheme.crimson),
                tooltip: 'Ахицыг устгах',
                onPressed: onReset,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatChip(
                label: 'Судалсан',
                value: studied == true ? '✓' : '✗',
                color: studied == true
                    ? const Color(0xFF4ADE80)
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Quiz',
                value: quizPassed == true ? '✓' : '✗',
                color: quizPassed == true
                    ? const Color(0xFF4ADE80)
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'XP',
                value: '$xpEarned',
                color: AppTheme.accentGold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTheme.chip.copyWith(fontSize: 10, color: color)),
          const SizedBox(width: 4),
          Text(value,
              style: AppTheme.captionBold.copyWith(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
