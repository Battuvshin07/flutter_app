import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/models/person_model.dart';
import '../models/person.dart';
import '../services/family_tree_service.dart';
import 'person_detail_screen.dart';

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
                    constrained: false,
                    minScale: 0.35,
                    maxScale: 3.0,
                    // top: 0   → cannot pan above the root couple.
                    // bottom: 0 → cannot pan below the last generation.
                    // left/right: 200 px of comfortable horizontal slack.
                    boundaryMargin: const EdgeInsets.only(
                      left: 200,
                      right: 200,
                      top: 0,
                      bottom: 0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: _buildTreeWidget(roots),
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
    final hasChildren = node.children.isNotEmpty;

    // Top element: couple row or single node.
    final Widget topWidget = node.spouse != null
        ? _buildCoupleRow(node, nodeSize)
        : _buildPersonNode(node, nodeSize);

    if (!hasChildren) return topWidget;

    final childSize = (nodeSize * 0.82).clamp(50.0, 80.0);

    // For couple rows the center of the couple is at the connector midpoint:
    // leftNodeWidth(nodeSize+30) + connectorWidth(44)/2 = nodeSize + 52.
    // Pinning the top widget inside a SizedBox of exactly coupleRowWidth
    // guarantees the outer Column is never narrower than the couple, so the
    // 2 px vertical bar (centered by CrossAxisAlignment.center) always falls
    // precisely on the couple's midpoint even when children are narrower.
    final coupleRowWidth =
        node.spouse != null ? (nodeSize + 30) * 2 + 44.0 : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Parent / couple — constrained to its natural width so the Column
        // never collapses narrower than the couple row.
        if (coupleRowWidth != null)
          SizedBox(width: coupleRowWidth, child: topWidget)
        else
          topWidget,
        const SizedBox(height: 8),
        // Vertical connector — centered by CrossAxisAlignment.center above.
        Container(
            width: 2, height: 30, color: AppTheme.accentGold.withOpacity(0.45)),
        const SizedBox(height: 4),
        // Horizontal connector + children
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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

  /// Renders a couple side-by-side: [spouse] — connector — [primary].
  Widget _buildCoupleRow(FamilyTreeNode node, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildPersonNode(FamilyTreeNode(person: node.spouse!), size),
        _buildSpouseConnector(),
        _buildPersonNode(node, size),
      ],
    );
  }

  /// Golden horizontal connector between spouses.
  Widget _buildSpouseConnector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 18, height: 2, color: AppTheme.accentGold.withOpacity(0.6)),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.accentGold.withOpacity(0.7),
          ),
        ),
        Container(
            width: 18, height: 2, color: AppTheme.accentGold.withOpacity(0.6)),
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

    return GestureDetector(
      onTap: () {
        final localPerson = Person(
          name: person.name,
          birthDate: person.birthYear?.toString(),
          deathDate: person.deathYear?.toString(),
          description: person.shortBio,
          imageUrl: person.avatarUrl,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonDetailScreen(person: localPerson),
          ),
        );
      },
      child: SizedBox(
        width: size + 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.45),
                  width: 2.5,
                ),
                boxShadow: [
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

  String _buildYearsText(PersonModel person) {
    final parts = <String>[];
    if (person.birthYear != null) parts.add('${person.birthYear}');
    if (person.deathYear != null) parts.add('${person.deathYear}');
    return parts.join(' — ');
  }
}
