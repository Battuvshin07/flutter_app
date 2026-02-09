import 'package:flutter/material.dart';
import '../models/person.dart';

/// Animated floating detail card shown when a person node is tapped.
/// Displays portrait, name, years, role, biography, and key events.
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
  static const _brown = Color(0xFF3B2F2F);
  static const _cardBg = Color(0xFFFFFBF5);
  static const _gold = Color(0xFFB8860B);

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
          color: Colors.black26,
          child: Center(
            child: GestureDetector(
              onTap: () {}, // absorb taps on card
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  constraints: const BoxConstraints(maxWidth: 380),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- Close button ---
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _brown.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 18, color: _brown),
                          ),
                        ),
                      ),
                      // --- Portrait ---
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8B4513),
                          border: Border.all(color: _gold, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withOpacity(0.3),
                              blurRadius: 10,
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
                      // --- Name ---
                      Text(
                        person.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _brown,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (years.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        // --- Years ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: _gold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                years,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _brown.withOpacity(0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      // --- Biography ---
                      Text(
                        person.description,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 13,
                          color: _brown.withOpacity(0.8),
                          height: 1.45,
                        ),
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // --- Key Events ---
                      if (widget.keyEvents.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Гол үйл явдлууд',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _brown.withOpacity(0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...widget.keyEvents.take(3).map(
                              (e) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 4, left: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 5),
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _gold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _brown.withOpacity(0.7),
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
    );
  }

  Widget _buildInitials(String initials) {
    return Container(
      color: const Color(0xFF8B4513),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
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
