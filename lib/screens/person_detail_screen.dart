import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../data/models/person_detail_model.dart';
import '../components/glass_card.dart';
import '../components/gold_badge.dart';
import '../components/event_card.dart';

/// FR-01: Түүхэн хүмүүсийн намтар, зураг харуулах
/// Dark + gold gamified person detail screen.
class PersonDetailScreen extends StatefulWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  PersonDetailModel? _detail;
  bool _detailLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      // Find the person in Firestore by name to get their document ID.
      final personSnap = await FirebaseFirestore.instance
          .collection('persons')
          .where('name', isEqualTo: widget.person.name)
          .limit(1)
          .get();

      if (personSnap.docs.isNotEmpty) {
        final firestoreId = personSnap.docs.first.id;
        final detailDoc = await FirebaseFirestore.instance
            .collection('person_details')
            .doc(firestoreId)
            .get();

        if (detailDoc.exists && mounted) {
          setState(() {
            _detail = PersonDetailModel.fromFirestore(detailDoc);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching person detail: $e');
    }
    if (mounted) setState(() => _detailLoading = false);
  }

  Person get person => widget.person;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, Color(0xFF0D1628)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildPortrait(),
                      const SizedBox(height: 16),
                      _buildNameSection(),
                      const SizedBox(height: 20),
                      _buildBioCard(),
                      if (_detail != null) ...[
                        if (_detail!.achievements.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildAchievementsCard(),
                        ],
                        if (_detail!.timeline.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildTimelineCard(),
                        ],
                        if (_detail!.sources.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSourcesCard(),
                        ],
                      ],
                      const SizedBox(height: 20),
                      _buildRelatedEvents(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Намтар',
              textAlign: TextAlign.center,
              style: AppTheme.h2.copyWith(fontSize: 19),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: AppTheme.accentGold,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortrait() {
    final hasImage = person.imageUrl != null && person.imageUrl!.isNotEmpty;
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.accentGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.asset(
                person.imageUrl!,
                fit: BoxFit.cover,
                width: 130,
                height: 130,
                errorBuilder: (_, __, ___) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          initials,
          style: AppTheme.h2.copyWith(
            color: AppTheme.accentGold,
            fontSize: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        Text(
          person.name,
          style: AppTheme.h2.copyWith(fontSize: 24),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (person.birthDate != null) GoldBadge.birth(person.birthDate!),
            if (person.birthDate != null && person.deathDate != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color: AppTheme.accentGold.withOpacity(0.6),
                ),
              ),
            ],
            if (person.deathDate != null) GoldBadge.death(person.deathDate!),
          ],
        ),
        const SizedBox(height: 10),
        GoldBadge.xp(12450),
      ],
    );
  }

  Widget _buildBioCard() {
    final bioText = (_detail != null && _detail!.longBio.isNotEmpty)
        ? _detail!.longBio
        : person.description;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: AppTheme.accentGold,
      glowIntensity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                size: 18,
                color: AppTheme.accentGold.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'Намтар',
                style: AppTheme.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            color: AppTheme.accentGold.withOpacity(0.15),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          Text(
            bioText,
            style: AppTheme.body.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: AppTheme.accentGold,
      glowIntensity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 18,
                color: AppTheme.accentGold.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text('Амжилтууд', style: AppTheme.sectionTitle),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            color: AppTheme.accentGold.withOpacity(0.15),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          ...(_detail!.achievements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 14, color: AppTheme.accentGold.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child:
                          Text(a, style: AppTheme.body.copyWith(height: 1.5)),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildTimelineCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: AppTheme.accentGold,
      glowIntensity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 18,
                color: AppTheme.accentGold.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text('Цаг хугацааны шугам', style: AppTheme.sectionTitle),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            color: AppTheme.accentGold.withOpacity(0.15),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          ...(_detail!.timeline.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${t.year}',
                        style: AppTheme.chip.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t.text,
                          style: AppTheme.body.copyWith(height: 1.5)),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildSourcesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      glowColor: AppTheme.accentGold,
      glowIntensity: 0.06,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: AppTheme.accentGold.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text('Эх сурвалж', style: AppTheme.sectionTitle),
            ],
          ),
          const SizedBox(height: 4),
          Divider(
            color: AppTheme.accentGold.withOpacity(0.15),
            thickness: 1,
          ),
          const SizedBox(height: 8),
          ...(_detail!.sources.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.link_rounded,
                        size: 14, color: AppTheme.accentGold.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.url.isNotEmpty ? '${s.title} — ${s.url}' : s.title,
                        style: AppTheme.body.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildRelatedEvents(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final events = person.personId != null
            ? provider.getEventsForPerson(person.personId!)
            : <Event>[];
        if (events.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_note,
                  size: 18,
                  color: AppTheme.accentGold.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text('Холбогдсон үйл явдлууд', style: AppTheme.sectionTitle),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppTheme.accentGold.withOpacity(0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...events.map((event) => EventCard(event: event)),
          ],
        );
      },
    );
  }
}
