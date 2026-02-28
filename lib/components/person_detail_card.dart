import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/person.dart';
import 'glass_card.dart';
import 'gold_badge.dart';

/// Animated floating detail card shown when a person node is tapped.
/// Displays portrait, name, years, biography, and key events.
/// Updated to dark + gold design system.
class PersonDetailCard extends StatefulWidget {
  final Person person;
  final List<String> keyEvents;
  final VoidCallback onClose;

  const PersonDetailCard({
    super.key,
    required this.person,
    this.keyEvents = const [],
    required this.onClose,
  });

  @override
  State<PersonDetailCard> createState() => _PersonDetailCardState();
}

class _PersonDetailCardState extends State<PersonDetailCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final hasImage = person.imageUrl != null && person.imageUrl!.isNotEmpty;
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    final years = _buildYearsText(person);

    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          color: Colors.black45,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  constraints: const BoxConstraints(maxWidth: 380),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    glowColor: AppTheme.accentGold,
                    glowIntensity: 0.12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close button
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: _dismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        // Portrait
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accentGold,
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withOpacity(0.35),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: hasImage
                                ? Image.asset(
                                    person.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildInitials(initials),
                                  )
                                : _buildInitials(initials),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          person.name,
                          textAlign: TextAlign.center,
                          style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                        ),
                        if (years.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          GoldBadge.year(years),
                        ],
                        const SizedBox(height: 14),
                        // Biography
                        Text(
                          person.description,
                          textAlign: TextAlign.start,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Key Events
                        if (widget.keyEvents.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Гол үйл явдлууд',
                              style:
                                  AppTheme.sectionTitle.copyWith(fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...widget.keyEvents.take(3).map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 4, left: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(top: 5),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.accentGold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          e,
                                          style: AppTheme.caption.copyWith(
                                            color: AppTheme.textSecondary
                                                .withOpacity(0.85),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
      ),
    );
  }

  String _buildYearsText(Person person) {
    final parts = <String>[];
    if (person.birthDate != null) parts.add(person.birthDate!);
    if (person.deathDate != null) parts.add(person.deathDate!);
    return parts.join(' – ');
  }
}
