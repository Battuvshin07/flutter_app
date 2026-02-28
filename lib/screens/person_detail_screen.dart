import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../models/person.dart';
import '../models/event.dart';
import '../components/glass_card.dart';
import '../components/gold_badge.dart';
import '../components/event_card.dart';

/// FR-01: Түүхэн хүмүүсийн намтар, зураг харуулах
/// Dark + gold gamified person detail screen.
class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

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
            person.description,
            style: AppTheme.body.copyWith(height: 1.6),
          ),
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
