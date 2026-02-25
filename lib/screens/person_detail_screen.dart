import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/person.dart';
import '../models/event.dart';

/// FR-01: Түүхэн хүмүүсийн намтар, зураг харуулах
/// "Түүхэн хүмүүсийн мэдээллийг харуулах" - Person detail with biography & related events
class PersonDetailScreen extends StatelessWidget {
  final Person person;

  const PersonDetailScreen({super.key, required this.person});

  static const _brown = Color(0xFF3B2F2F);
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);
  static const _cardBg = Color(0xFFFFFBF5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_parchment, _parchmentDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAvatar(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child:
                const Icon(Icons.arrow_back_ios_new, color: _brown, size: 24),
          ),
          const Expanded(
            child: Text(
              'Намтар',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _brown,
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final hasImage = person.imageUrl != null && person.imageUrl!.isNotEmpty;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF8B4513),
        border: Border.all(
            color: const Color(0xFFB8860B).withOpacity(0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.asset(person.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget())
            : _initialsWidget(),
      ),
    );
  }

  Widget _initialsWidget() {
    final initials = person.name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join();
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 36,
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        Text(
          person.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _brown,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (person.birthDate != null)
              _buildDateChip(Icons.cake_outlined, person.birthDate!,
                  const Color(0xFF6B8E23)),
            if (person.birthDate != null && person.deathDate != null)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—', style: TextStyle(color: _brown, fontSize: 16)),
              ),
            if (person.deathDate != null)
              _buildDateChip(
                  Icons.history, person.deathDate!, const Color(0xFF8B0000)),
          ],
        ),
      ],
    );
  }

  Widget _buildDateChip(IconData icon, String date, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(date,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories, size: 18, color: Color(0xFF8B4513)),
              SizedBox(width: 8),
              Text(
                'Намтар',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            person.description,
            style: TextStyle(
              fontSize: 14,
              color: _brown.withOpacity(0.8),
              height: 1.6,
            ),
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
            const Row(
              children: [
                Icon(Icons.event_note, size: 18, color: Color(0xFF4682B4)),
                SizedBox(width: 8),
                Text(
                  'Холбоотой үйл явдлууд',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...events.map((event) => _buildEventItem(event)),
          ],
        );
      },
    );
  }

  Widget _buildEventItem(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D0A8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4682B4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              event.date,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4682B4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _brown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: _brown.withOpacity(0.7),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
