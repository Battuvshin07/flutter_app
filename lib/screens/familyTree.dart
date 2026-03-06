import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/models/person_model.dart';
import '../services/family_tree_service.dart';
import '../components/glass_card.dart';
import '../components/gold_badge.dart';

// ─────────────────────────────────────────────────────────────────────
// Main screen – Firestore-backed family tree
// Dynamically builds hierarchy from fatherId relationships
// ─────────────────────────────────────────────────────────────────────
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final FamilyTreeService _service = FamilyTreeService();
  String? _selectedPersonId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PersonModel>>(
      stream: _service.watchAllPersons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentGold,
              strokeWidth: 2.5,
            ),
          );
        }

        final persons = snapshot.data ?? [];
        if (persons.isEmpty) {
          return Center(
            child: Text(
              'Удмын модны мэдээлэл олдсонгүй',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          );
        }

        final roots = FamilyTreeService.buildTree(persons);
        // Find the primary root (first root, or the one with most descendants)
        final primaryRoot = roots.isNotEmpty ? roots.first : null;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.background, Color(0xFF0D1628)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative gold accent bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentGold.withOpacity(0.0),
                        AppTheme.accentGold.withOpacity(0.5),
                        AppTheme.accentGold.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Title chip
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.accentGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'МОНГОЛЫН ТҮҮХЭН УДМЫН МОД',
                      style: AppTheme.chip.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Zoomable / pannable tree
              if (primaryRoot != null)
                Padding(
                  padding: const EdgeInsets.only(top: 42),
                  child: InteractiveViewer(
                    minScale: 0.35,
                    maxScale: 3.0,
                    boundaryMargin: const EdgeInsets.all(300),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: _buildTreeWidget(roots),
                        ),
                      ),
                    ),
                  ),
                ),

              // "Pinch to zoom" hint at bottom
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.cardBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pinch_outlined,
                          size: 14,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Pinch to zoom  •  Pan to explore',
                          style: AppTheme.chip.copyWith(
                            fontSize: 10,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Person detail card overlay
              if (_selectedPersonId != null) _buildDetailOverlay(persons),
            ],
          ),
        );
      },
    );
  }

  // ───────────── RECURSIVE TREE LAYOUT ─────────────

  Widget _buildTreeWidget(List<FamilyTreeNode> roots) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Render each root and its descendants
        for (final root in roots) _buildSubtree(root, 80),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Recursively builds a subtree: parent on top, children in a row below.
  Widget _buildSubtree(FamilyTreeNode node, double nodeSize) {
    if (node.children.isEmpty) {
      return _buildPersonNode(node, nodeSize);
    }

    final childSize = (nodeSize * 0.82).clamp(50.0, 80.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Parent node
        _buildPersonNode(node, nodeSize),
        const SizedBox(height: 8),
        // Vertical connector line
        Container(
            width: 2, height: 30, color: AppTheme.accentGold.withOpacity(0.45)),
        const SizedBox(height: 4),
        // Horizontal connector + children
        IntrinsicWidth(
          child: Column(
            children: [
              // Horizontal line spanning all children
              if (node.children.length > 1)
                Container(
                    height: 2, color: AppTheme.accentGold.withOpacity(0.45)),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: node.children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        // Vertical line from horizontal bar to child
                        Container(
                          width: 2,
                          height: 20,
                          color: AppTheme.accentGold.withOpacity(0.45),
                        ),
                        _buildSubtree(child, childSize),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPersonNode(FamilyTreeNode node, double size) {
    final person = node.person;
    final hasImage = person.avatarUrl != null && person.avatarUrl!.isNotEmpty;
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    final isSelected = _selectedPersonId == person.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPersonId = _selectedPersonId == person.id ? null : person.id;
        });
      },
      child: SizedBox(
        width: size + 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentGold
                      : AppTheme.accentGold.withOpacity(0.45),
                  width: isSelected ? 3.5 : 2.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.5),
                      blurRadius: 18,
                      spreadRadius: 3,
                    )
                  else
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.12),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: ClipOval(
                child: hasImage
                    ? Image.network(
                        person.avatarUrl!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                        errorBuilder: (_, __, ___) =>
                            _buildInitials(initials, size),
                      )
                    : _buildInitials(initials, size),
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              person.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.chip.copyWith(
                fontSize: size * 0.17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            // Title (e.g. "Монголын Их Хаан")
            if (person.title != null && person.title!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                person.title!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.chip.copyWith(
                  fontSize: size * 0.13,
                  color: AppTheme.accentGold.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            // Years
            if (person.birthYear != null) ...[
              const SizedBox(height: 2),
              Text(
                _buildYearsText(person),
                textAlign: TextAlign.center,
                style: AppTheme.chip.copyWith(
                  fontSize: size * 0.14,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(String initials, double sz) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: sz * 0.3,
          ),
        ),
      ),
    );
  }

  // ───────────── DETAIL OVERLAY ─────────────

  Widget _buildDetailOverlay(List<PersonModel> persons) {
    final person = persons.where((p) => p.id == _selectedPersonId).firstOrNull;
    if (person == null) return const SizedBox();

    final hasImage = person.avatarUrl != null && person.avatarUrl!.isNotEmpty;
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();
    final years = _buildYearsText(person);

    return GestureDetector(
      onTap: () => setState(() => _selectedPersonId = null),
      child: Container(
        color: Colors.black45,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps on card
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
                        onTap: () => setState(() => _selectedPersonId = null),
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
                            ? Image.network(
                                person.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildOverlayInitials(initials),
                              )
                            : _buildOverlayInitials(initials),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      person.name,
                      textAlign: TextAlign.center,
                      style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                    ),
                    if (person.title != null && person.title!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        person.title!,
                        textAlign: TextAlign.center,
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.accentGold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (years.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GoldBadge.year(years),
                    ],
                    const SizedBox(height: 14),
                    // Biography
                    Text(
                      person.shortBio,
                      textAlign: TextAlign.start,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayInitials(String initials) {
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

  String _buildYearsText(PersonModel person) {
    final parts = <String>[];
    if (person.birthYear != null) parts.add('${person.birthYear}');
    if (person.deathYear != null) parts.add('${person.deathYear}');
    return parts.join(' — ');
  }
}
