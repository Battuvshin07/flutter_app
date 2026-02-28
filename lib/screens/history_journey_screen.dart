import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/history_topic.dart';
import '../components/history_wagon.dart';
import '../components/journey_progress_bar.dart';

/// FR: 2D "History Train Progression" screen.
/// Horizontally scrollable railway with wagon nodes.
class HistoryJourneyScreen extends StatefulWidget {
  const HistoryJourneyScreen({super.key});

  @override
  State<HistoryJourneyScreen> createState() => _HistoryJourneyScreenState();
}

class _HistoryJourneyScreenState extends State<HistoryJourneyScreen>
    with TickerProviderStateMixin {
  static const _teal = Color(0xFF5ED8B5);

  late final ScrollController _scrollCtrl;
  late List<HistoryTopic> _topics;

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
    _topics = _buildSampleTopics();

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
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _xpAnimCtrl.dispose();
    super.dispose();
  }

  // ── Sample data ──────────────────────────────────────────────────
  List<HistoryTopic> _buildSampleTopics() {
    final raw = [
      ('Монгол овгууд нэгдэв', '1189-1206', 100),
      ('Чингис төрөв', '1162', 150),
      ('Цолыг хүлээн авсан', '1206', 150),
      ('Хорезмийн аян', '1219', 200),
      ('Европ аян', '1236', 200),
      ('Өгөдэй хаан', '1229', 150),
      ('Мөнх хаан', '1251', 150),
      ('Хубилай хаан', '1260', 200),
      ('Юань улс', '1271', 250),
      ('Эзэнт гүрэн задарсан', '1368', 200),
    ];

    return List.generate(raw.length, (i) {
      final (title, year, xp) = raw[i];
      return HistoryTopic(
        id: i,
        title: title,
        year: year,
        xp: xp,
        isCompleted: i < 2, // first two done
        isLocked: i > 2, // 0,1 completed, 2 current, rest locked
      );
    });
  }

  // ── Derived getters ──────────────────────────────────────────────
  int get _completedCount => _topics.where((t) => t.isCompleted).length;

  int get _currentIndex {
    for (int i = 0; i < _topics.length; i++) {
      if (!_topics[i].isCompleted && !_topics[i].isLocked) return i;
    }
    return _topics.length - 1;
  }

  // ── Actions ──────────────────────────────────────────────────────
  void _completeTopic(int index) {
    if (index < 0 || index >= _topics.length) return;
    final topic = _topics[index];
    if (topic.isLocked || topic.isCompleted) return;

    setState(() {
      topic.isCompleted = true;
      // Unlock next
      if (index + 1 < _topics.length) {
        _topics[index + 1].isLocked = false;
      }
      // Start XP animation
      _rewardXp = topic.xp;
      _showXpReward = true;
    });
    _xpAnimCtrl.forward(from: 0);
  }

  void _onContinue() {
    final idx = _currentIndex;
    _completeTopic(idx);
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
          child: Stack(
            children: [
              // Stars / subtle dots
              ..._buildStars(),
              // Main column
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildCurrentTopicBanner(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildTrainTrack()),
                  _buildBottomButton(),
                  const SizedBox(height: 16),
                ],
              ),
              // XP reward overlay
              if (_showXpReward) _buildXpRewardOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.pagePadding,
        vertical: 8,
      ),
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
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Судлах түүх', style: AppTheme.h2.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  'Галт тэрэгний аяллаар',
                  style: AppTheme.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          JourneyProgressBar(
            completed: _completedCount,
            total: _topics.length,
          ),
        ],
      ),
    );
  }

  // ── Current topic banner ─────────────────────────────────────────
  Widget _buildCurrentTopicBanner() {
    final topic = _topics[_currentIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: _teal.withValues(alpha: 0.25)),
        ),
        child: Text(
          topic.title,
          textAlign: TextAlign.center,
          style: AppTheme.sectionTitle.copyWith(
            color: _teal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Train track ──────────────────────────────────────────────────
  Widget _buildTrainTrack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Auto-scroll to current wagon after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrent();
        });

        return SingleChildScrollView(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildWagonsWithRail(),
          ),
        );
      },
    );
  }

  List<Widget> _buildWagonsWithRail() {
    final widgets = <Widget>[];
    for (int i = 0; i < _topics.length; i++) {
      final topic = _topics[i];
      final current = i == _currentIndex;

      widgets.add(
        HistoryWagon(
          topic: topic,
          isCurrent: current,
          onTap: () => _completeTopic(i),
        ),
      );

      // Rail connector between wagons
      if (i < _topics.length - 1) {
        final completed = topic.isCompleted;
        widgets.add(_buildRailSegment(completed));
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
          // Top rail
          Container(height: 2, color: color),
          const SizedBox(height: 6),
          // Bottom rail
          Container(height: 2, color: color),
        ],
      ),
    );
  }

  void _scrollToCurrent() {
    if (!_scrollCtrl.hasClients) return;
    // Each wagon is 140 wide + 40 connector = 180 per item
    final target = (_currentIndex * 180.0) - 80;
    _scrollCtrl.animateTo(
      target.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  // ── Bottom button ────────────────────────────────────────────────
  Widget _buildBottomButton() {
    final allDone = _topics.every((t) => t.isCompleted);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: allDone ? null : _onContinue,
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
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppTheme.accentGold,
                      size: 44,
                    ),
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
