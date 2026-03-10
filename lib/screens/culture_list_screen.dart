import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../components/culture_card.dart';
import '../data/models/culture_model.dart';
import 'culture_detail_screen.dart';

/// FR-07: Redesigned Dribbble-level Culture List Screen.
/// Features filter chips, progress-aware cards, and lock states.
/// Cultures are streamed live from Firestore via AppProvider.
class CultureListScreen extends StatefulWidget {
  const CultureListScreen({super.key});

  @override
  State<CultureListScreen> createState() => _CultureListScreenState();
}

class _CultureListScreenState extends State<CultureListScreen> {
  int _selectedFilter = 0;

  static const _filters = ['Бүх сэдэв', 'Шинэ', 'Дууссан'];

  static const _iconMap = {
    'landscape': Icons.landscape_rounded,
    'shield': Icons.shield_rounded,
    'route': Icons.route_rounded,
    'temple_buddhist': Icons.temple_buddhist_rounded,
    'edit_note': Icons.edit_note_rounded,
    'restaurant': Icons.restaurant_rounded,
  };

  static const _accentPalette = [
    AppTheme.accentGold,
    Color(0xFF64B5F6),
    AppTheme.streakOrange,
    AppTheme.xpGreen,
    AppTheme.crimson,
    Color(0xFFCE93D8),
  ];

  // Progress keyed by Firestore document ID (String)
  final Map<String, double> _progressMap = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              Color(0xFF0D1B30),
              AppTheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildFilterChips(),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding, 12, AppTheme.pagePadding, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppTheme.accentGold, size: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Соёл ба Нийгэм',
              style: AppTheme.h2.copyWith(fontSize: 20),
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.surfaceLight,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Icon(Icons.search_rounded,
                color: AppTheme.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ───────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding, vertical: 6),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final selected = i == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.accentGold : AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  border: Border.all(
                    color: selected ? AppTheme.accentGold : AppTheme.cardBorder,
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: AppTheme.chip.copyWith(
                    color:
                        selected ? AppTheme.background : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Culture list ───────────────────────────────────────────────
  Widget _buildList() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final rawList = provider.cultures;
        if (rawList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_edu_rounded,
                    color: AppTheme.textSecondary.withValues(alpha: 0.28), size: 56),
                const SizedBox(height: 14),
                Text('Соёлын мэдээлэл олдсонгүй', style: AppTheme.body),
              ],
            ),
          );
        }

        final filtered = _applyFilter(rawList);
        if (filtered.isEmpty) {
          return Center(
            child: Text('Хайлт хоосон байна', style: AppTheme.body),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding, 12, AppTheme.pagePadding, 28),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final item = filtered[index];
            final id = item.id ?? '';
            final accent = _accentPalette[index % _accentPalette.length];
            final icon = _iconMap[item.icon] ?? Icons.info_outline_rounded;
            final progress = _progressMap[id] ?? 0.0;
            final isCompleted = progress >= 1.0;

            return CultureCard(
              title: item.title,
              subtitle: item.description,
              icon: icon,
              accentColor: accent,
              progress: progress,
              isCompleted: isCompleted,
              coverImageUrl: item.coverImageUrl,
              onTap: () => _openDetail(context, item, accent, icon, id),
            );
          },
        );
      },
    );
  }

  // ── Filter logic ───────────────────────────────────────────────
  List<CultureModel> _applyFilter(List<CultureModel> list) {
    switch (_selectedFilter) {
      case 1: // Шинэ — not started
        return list
            .where((e) => (_progressMap[e.id ?? ''] ?? 0.0) == 0.0)
            .toList();
      case 2: // Дууссан — 100 %
        return list
            .where((e) => (_progressMap[e.id ?? ''] ?? 0.0) >= 1.0)
            .toList();
      default:
        return list;
    }
  }

  void _openDetail(
    BuildContext context,
    CultureModel item,
    Color accent,
    IconData icon,
    String id,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CultureDetailScreen(
          item: item,
          accentColor: accent,
          icon: icon,
          progress: _progressMap[id] ?? 0.0,
          onCompleted: () {
            setState(() => _progressMap[id] = 1.0);
          },
        ),
      ),
    );
  }
}
