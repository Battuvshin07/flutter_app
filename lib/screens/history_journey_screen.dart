import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/history_topic.dart';
import '../models/story.dart';
import '../providers/journey_provider.dart';
import '../components/history_wagon.dart';
import '../components/journey_progress_bar.dart';
import 'story_detail_screen.dart';

/// History Journey – horizontal train progression powered by Firestore.
class HistoryJourneyScreen extends StatefulWidget {
  const HistoryJourneyScreen({super.key});

  @override
  State<HistoryJourneyScreen> createState() => _HistoryJourneyScreenState();
}

class _HistoryJourneyScreenState extends State<HistoryJourneyScreen>
    with TickerProviderStateMixin {
  static const _teal = Color(0xFF5ED8B5);

  late final ScrollController _scrollCtrl;

  // XP reward overlay
  bool _showXpReward = false;
  int _rewardXp = 0;
  late AnimationController _xpAnimCtrl;
  late Animation<double> _xpScale;
  late Animation<double> _xpOpacity;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();

    _xpAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _xpScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _xpAnimCtrl,
        curve: const Interval(0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _xpOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _xpAnimCtrl,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );
    _xpAnimCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showXpReward = false);
        _xpAnimCtrl.reset();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JourneyProvider>(context, listen: false).init();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _xpAnimCtrl.dispose();
    super.dispose();
  }

  // ── Convert Story → HistoryTopic for wagon widget ────────────
  HistoryTopic _toTopic(Story story, JourneyProvider journey) {
    return HistoryTopic(
      id: story.order,
      title: story.title,
      year: '+${story.xpReward} XP',
      xp: story.xpReward,
      isCompleted: journey.isStoryCompleted(story.id),
      isLocked: !journey.isStoryUnlocked(story.id),
    );
  }

  // ── Tap handler ──────────────────────────────────────────────
  void _onWagonTap(Story story, JourneyProvider journey) {
    if (!journey.isStoryUnlocked(story.id)) {
      _showLockedDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryDetailScreen(story: story),
      ),
    ).then((_) {
      // Reload progress when returning
      journey.loadUserProgress().then((__) {
        // Check if XP was earned (show animation)
        final p = journey.getProgress(story.id);
        if (p != null && p.quizPassed && p.xpEarned > 0 && !_showXpReward) {
          // Only animate if they just now completed it
        }
      });
    });
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_rounded,
                color: AppTheme.accentGold.withValues(alpha: 0.7), size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Түгжээтэй',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          'Энэ түүхийг нээхийн тулд өмнөх түүхийг бүрэн судалж, шалгалтад тэнцэх шаардлагатай.',
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ойлголоо',
                style:
                    AppTheme.captionBold.copyWith(color: AppTheme.accentGold)),
          ),
        ],
      ),
    );
  }

  /// Shows the XP earned animated overlay.
  void showXpAnimation(int xp) {
    if (xp <= 0) return;
    setState(() {
      _rewardXp = xp;
      _showXpReward = true;
    });
    _xpAnimCtrl.forward(from: 0);
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D1628),
              AppTheme.background,
              Color(0xFF0A0F1C),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Consumer<JourneyProvider>(
            builder: (context, journey, _) {
              if (journey.isLoading && journey.stories.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGold),
                );
              }

              if (journey.stories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.train_rounded,
                          color: AppTheme.textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text('Түүх олдсонгүй',
                          style: AppTheme.body
                              .copyWith(color: AppTheme.textSecondary)),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => journey.init(),
                        child: Text('Дахин ачаалах',
                            style: AppTheme.captionBold
                                .copyWith(color: AppTheme.accentGold)),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => journey.seedSampleData(),
                        child: Text('Жишиг өгөгдөл ачаалах',
                            style: AppTheme.captionBold
                                .copyWith(color: const Color(0xFF5ED8B5))),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  ..._buildStars(),
                  Column(
                    children: [
                      _buildHeader(journey),
                      const SizedBox(height: 8),
                      _buildCurrentTopicBanner(journey),
                      const SizedBox(height: 20),
                      Expanded(child: _buildTrainTrack(journey)),
                      _buildBottomButton(journey),
                      const SizedBox(height: 16),
                    ],
                  ),
                  if (_showXpReward) _buildXpRewardOverlay(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader(JourneyProvider journey) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Түүхийн аялал',
                    style: AppTheme.h2.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  'Галт тэрэгний аяллаар',
                  style: AppTheme.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          JourneyProgressBar(
            completed: journey.completedCount,
            total: journey.stories.length,
          ),
        ],
      ),
    );
  }

  // ── Current topic banner ─────────────────────────────────────────
  Widget _buildCurrentTopicBanner(JourneyProvider journey) {
    if (journey.stories.isEmpty) return const SizedBox.shrink();
    final current = journey.stories[journey.currentIndex];
    final allDone = journey.completedCount == journey.stories.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color:
              (allDone ? AppTheme.accentGold : _teal).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(
            color:
                (allDone ? AppTheme.accentGold : _teal).withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          allDone ? 'Бүх түүхийг дуусгасан!' : current.title,
          textAlign: TextAlign.center,
          style: AppTheme.sectionTitle.copyWith(
            color: allDone ? AppTheme.accentGold : _teal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Train track ──────────────────────────────────────────────────
  Widget _buildTrainTrack(JourneyProvider journey) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrent(journey);
        });

        return SingleChildScrollView(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildWagonsWithRail(journey),
          ),
        );
      },
    );
  }

  List<Widget> _buildWagonsWithRail(JourneyProvider journey) {
    final widgets = <Widget>[];
    for (int i = 0; i < journey.stories.length; i++) {
      final story = journey.stories[i];
      final topic = _toTopic(story, journey);
      final isCurrent = i == journey.currentIndex;

      widgets.add(
        HistoryWagon(
          topic: topic,
          isCurrent: isCurrent,
          onTap: () => _onWagonTap(story, journey),
        ),
      );

      if (i < journey.stories.length - 1) {
        widgets.add(_buildRailSegment(topic.isCompleted));
      }
    }
    return widgets;
  }

  Widget _buildRailSegment(bool filled) {
    final color = filled
        ? AppTheme.accentGold.withValues(alpha: 0.5)
        : AppTheme.divider.withValues(alpha: 0.4);

    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 2, color: color),
          const SizedBox(height: 6),
          Container(height: 2, color: color),
        ],
      ),
    );
  }

  void _scrollToCurrent(JourneyProvider journey) {
    if (!_scrollCtrl.hasClients) return;
    final target = (journey.currentIndex * 180.0) - 80;
    _scrollCtrl.animateTo(
      target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Bottom button ────────────────────────────────────────────────
  Widget _buildBottomButton(JourneyProvider journey) {
    final allDone = journey.completedCount == journey.stories.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: allDone
              ? null
              : () {
                  final story = journey.stories[journey.currentIndex];
                  _onWagonTap(story, journey);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGold,
            foregroundColor: AppTheme.background,
            disabledBackgroundColor: AppTheme.surfaceLight,
            disabledForegroundColor: AppTheme.textSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          ),
          child: Text(
            allDone ? 'Бүгд дууссан!' : 'Үргэлжлүүлэх',
            style: AppTheme.button.copyWith(
              fontSize: 16,
              color: allDone ? AppTheme.textSecondary : AppTheme.background,
            ),
          ),
        ),
      ),
    );
  }

  // ── XP reward overlay ────────────────────────────────────────────
  Widget _buildXpRewardOverlay() {
    return AnimatedBuilder(
      animation: _xpAnimCtrl,
      builder: (context, _) {
        return Center(
          child: Opacity(
            opacity: _xpOpacity.value,
            child: Transform.scale(
              scale: _xpScale.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: AppTheme.accentGold.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: AppTheme.accentGold, size: 44),
                    const SizedBox(height: 8),
                    Text(
                      '+$_rewardXp XP',
                      style: AppTheme.h2.copyWith(
                        color: AppTheme.accentGold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Decorative stars ─────────────────────────────────────────────
  List<Widget> _buildStars() {
    const starColor = Color(0xFF2A3A55);
    final positions = <(double, double, double)>[
      (30, 60, 2),
      (100, 120, 1.5),
      (200, 40, 2.5),
      (300, 100, 1.8),
      (50, 200, 2),
      (250, 180, 1.5),
      (180, 280, 2),
      (320, 220, 1.8),
    ];

    return positions.map((p) {
      final (left, top, size) = p;
      return Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: starColor,
          ),
        ),
      );
    }).toList();
  }
}
