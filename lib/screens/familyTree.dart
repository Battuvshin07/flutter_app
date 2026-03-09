import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/models/person_model.dart';
import '../models/person.dart';
import '../services/family_tree_service.dart';
import 'person_detail_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
// LAYOUT MODEL
//
// _LayoutNode is computed in a *first pass* (bottom-up) before any painting.
// It stores the exact pixel width each subtree occupies so every center-X
// can be resolved precisely.
//
// Coordinate system origin: top-left of the InteractiveViewer content.
// Y grows downward, X grows rightward.
// ═══════════════════════════════════════════════════════════════════════════

// ── constants ──────────────────────────────────────────────────────────────
const double _kNodeSize = 72.0; // avatar diameter (root generation)
const double _kNodeLabel =
    52.0; // px below avatar reserved for name/title/years
const double _kNodeSlot = _kNodeSize + 30; // total width of one person slot
const double _kSpouseGap = 24.0; // connector width between spouses
const double _kColGap = 20.0; // horizontal gap between sibling subtrees
const double _kRowGap = 80.0; // vertical gap between generations
const double _kVStep = 36.0; // length of vertical trunk line
const double _kHStep = 20.0; // length of short vertical drop to child
const double _kShrink = 0.82; // nodeSize multiplier per generation
const double _kMinNode = 46.0; // minimum avatar size

/// Computed layout node – one per [FamilyTreeNode].
class _LayoutNode {
  final FamilyTreeNode source;

  /// Width this entire subtree occupies (including all descendants).
  final double subtreeWidth;

  /// X-coordinate of the *midpoint* from which children hang.
  /// For a couple this is the center of the connector dot (midpoint between
  /// the two avatar centers).  For a single node it equals nodeCenter.
  final double hangX;

  /// X-coordinate of this node's avatar center (the primary person).
  final double nodeCenterX;

  /// X-coordinate of the spouse avatar center (null when no spouse).
  final double? spouseCenterX;

  final double nodeSize;
  final List<_LayoutNode> children;

  const _LayoutNode({
    required this.source,
    required this.subtreeWidth,
    required this.hangX,
    required this.nodeCenterX,
    required this.spouseCenterX,
    required this.nodeSize,
    required this.children,
  });
}

/// Recursively compute [_LayoutNode] starting at [offset] (left edge of the
/// area allocated to this subtree).
_LayoutNode _computeLayout(
  FamilyTreeNode node,
  double offsetX,
  double nodeSize,
) {
  final slot = nodeSize + 30; // total width per person slot

  // ── first pass: lay out children with their own offsets ───────────────
  final childSize = (nodeSize * _kShrink).clamp(_kMinNode, _kNodeSize);
  final childLayouts = <_LayoutNode>[];
  double childX = offsetX;

  if (node.children.isNotEmpty) {
    // Total width consumed by all children (each child owns its subtreeWidth
    // plus _kColGap on either side).
    for (final child in node.children) {
      final childLayout = _computeLayout(child, childX, childSize);
      childLayouts.add(childLayout);
      childX += childLayout.subtreeWidth + _kColGap;
    }
    childX -= _kColGap; // remove trailing gap
  }

  // Width this subtree occupies: max(parent couple width, children span).
  final coupleWidth = node.spouse != null
      ? slot + _kSpouseGap + slot // spouse + connector + primary
      : slot;

  final childrenSpan = node.children.isNotEmpty ? childX - offsetX : 0.0;

  final subtreeWidth = childrenSpan > coupleWidth ? childrenSpan : coupleWidth;

  // Center of the subtree (used to place the couple row).
  final subtreeCenterX = offsetX + subtreeWidth / 2;

  // ── couple placement ──────────────────────────────────────────────────
  double nodeCenterX;
  double? spouseCenterX;
  double hangX;

  if (node.spouse != null) {
    // Place couple centered within subtree.
    // Layout: [spouse slot][_kSpouseGap][primary slot]
    // We want the gap-center (==hangX) == subtreeCenterX.
    // hangX = spouseRight + _kSpouseGap/2
    //       = (spouseLeft + slot) + _kSpouseGap/2
    // Solve: spouseLeft = subtreeCenterX - slot - _kSpouseGap/2
    final spouseLeft = subtreeCenterX - slot - _kSpouseGap / 2;
    spouseCenterX = spouseLeft + slot / 2;
    hangX = spouseLeft + slot + _kSpouseGap / 2; // center of connector
    nodeCenterX = hangX + _kSpouseGap / 2 + slot / 2;
  } else {
    nodeCenterX = subtreeCenterX;
    hangX = subtreeCenterX;
  }

  // Re-center children under hangX if children span differs.
  // Recalculate child offsetX so children are centered under hangX.
  if (node.children.isNotEmpty) {
    final totalChildSpan = childLayouts.fold<double>(
          0,
          (sum, c) => sum + c.subtreeWidth,
        ) +
        _kColGap * (childLayouts.length - 1);

    final childStartX = hangX - totalChildSpan / 2;
    final recentered = <_LayoutNode>[];
    double cx = childStartX;
    for (final cl in childLayouts) {
      recentered.add(_reoffset(
          cl,
          cx -
              (cl.hangX -
                  cl.subtreeWidth / 2 -
                  (cl.nodeCenterX -
                      cl.subtreeWidth / 2 +
                      cl.subtreeWidth / 2 -
                      cl.hangX))));
      cx += cl.subtreeWidth + _kColGap;
    }
    return _LayoutNode(
      source: node,
      subtreeWidth: subtreeWidth,
      hangX: hangX,
      nodeCenterX: nodeCenterX,
      spouseCenterX: spouseCenterX,
      nodeSize: nodeSize,
      children: recentered,
    );
  }

  return _LayoutNode(
    source: node,
    subtreeWidth: subtreeWidth,
    hangX: hangX,
    nodeCenterX: nodeCenterX,
    spouseCenterX: spouseCenterX,
    nodeSize: nodeSize,
    children: childLayouts,
  );
}

/// Re-offset a layout node and all its children by [dx].
_LayoutNode _reoffset(_LayoutNode n, double dx) {
  return _LayoutNode(
    source: n.source,
    subtreeWidth: n.subtreeWidth,
    hangX: n.hangX + dx,
    nodeCenterX: n.nodeCenterX + dx,
    spouseCenterX: n.spouseCenterX != null ? n.spouseCenterX! + dx : null,
    nodeSize: n.nodeSize,
    children: n.children.map((c) => _reoffset(c, dx)).toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CustomPainter – draws all relationship lines in a single pass
// ═══════════════════════════════════════════════════════════════════════════

class _TreeLinePainter extends CustomPainter {
  final List<_LayoutNode> roots;

  _TreeLinePainter(this.roots);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.accentGold.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    for (final root in roots) {
      _paintNode(canvas, root, _kNodeLabel + 8, linePaint, dotPaint);
    }
  }

  /// [topY] is the Y of the avatar top-edge for this generation.
  void _paintNode(
    Canvas canvas,
    _LayoutNode node,
    double topY,
    Paint linePaint,
    Paint dotPaint,
  ) {
    final avatarCenterY = topY + node.nodeSize / 2;

    // ── spouse connector ─────────────────────────────────────────────────
    if (node.spouseCenterX != null) {
      // Horizontal line from spouse avatar edge → primary avatar edge.
      final spouseRight = node.spouseCenterX! + node.nodeSize / 2;
      final primaryLeft = node.nodeCenterX - node.nodeSize / 2;
      canvas.drawLine(
        Offset(spouseRight, avatarCenterY),
        Offset(primaryLeft, avatarCenterY),
        linePaint,
      );
      // Small circle at midpoint (the connector dot).
      canvas.drawCircle(Offset(node.hangX, avatarCenterY), 4, dotPaint);
    }

    if (node.children.isEmpty) return;

    // ── vertical trunk from hangX downward ──────────────────────────────
    final trunkTop = avatarCenterY + node.nodeSize / 2; // bottom of avatar
    final trunkBottom = topY + node.nodeSize + _kNodeLabel + _kVStep;
    canvas.drawLine(
      Offset(node.hangX, trunkTop),
      Offset(node.hangX, trunkBottom),
      linePaint,
    );

    // ── horizontal bar spanning all children ────────────────────────────
    final childSize = (node.nodeSize * _kShrink).clamp(_kMinNode, _kNodeSize);
    final childTopY = trunkBottom + _kHStep + childSize + _kNodeLabel + 8;
    // The child topY for the next level:
    final nextTopY = trunkBottom + _kHStep;
    final childAvatarCY = nextTopY + childSize / 2;

    if (node.children.length > 1) {
      final leftHang = node.children.first.hangX;
      final rightHang = node.children.last.hangX;
      canvas.drawLine(
        Offset(leftHang, trunkBottom),
        Offset(rightHang, trunkBottom),
        linePaint,
      );
    }

    // ── short verticals from horizontal bar to each child ────────────────
    for (final child in node.children) {
      canvas.drawLine(
        Offset(child.hangX, trunkBottom),
        Offset(child.hangX, nextTopY),
        linePaint,
      );
      // recurse
      _paintNode(canvas, child, nextTopY, linePaint, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_TreeLinePainter oldDelegate) => true;
}

// ═══════════════════════════════════════════════════════════════════════════
// Helpers: total canvas size needed for a set of root nodes
// ═══════════════════════════════════════════════════════════════════════════

Size _measureCanvas(List<_LayoutNode> roots) {
  double totalWidth = roots.fold<double>(0, (s, r) => s + r.subtreeWidth) +
      _kColGap * (roots.length - 1).clamp(0, 9999);
  double totalHeight = 0;
  for (final root in roots) {
    final h = _subtreeHeight(root, _kNodeLabel + 8);
    if (h > totalHeight) totalHeight = h;
  }
  return Size(totalWidth + 40, totalHeight + 40); // 20 px padding each side
}

double _subtreeHeight(_LayoutNode node, double topY) {
  final bottom = topY + node.nodeSize + _kNodeLabel;
  if (node.children.isEmpty) return bottom;
  final trunkBottom = topY + node.nodeSize + _kNodeLabel + _kVStep;
  final nextTopY = trunkBottom + _kHStep;
  double maxChild = 0;
  for (final c in node.children) {
    final h = _subtreeHeight(c, nextTopY);
    if (h > maxChild) maxChild = h;
  }
  return maxChild;
}

// ═══════════════════════════════════════════════════════════════════════════
// Person node widget
// ═══════════════════════════════════════════════════════════════════════════

class _PersonNode extends StatelessWidget {
  final PersonModel person;
  final double size;
  final VoidCallback onTap;

  const _PersonNode({
    required this.person,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = person.avatarUrl != null && person.avatarUrl!.isNotEmpty;
    final initials = person.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join();

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── avatar circle ──────────────────────────────────────────
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceLight,
                border: Border.all(
                  color: AppTheme.accentGold.withOpacity(0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    blurRadius: 10,
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
                            _Initials(text: initials, size: size),
                      )
                    : _Initials(text: initials, size: size),
              ),
            ),
            const SizedBox(height: 6),
            // ── name ──────────────────────────────────────────────────
            Text(
              person.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.chip.copyWith(
                fontSize: (size * 0.17).clamp(9, 14),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            // ── title ─────────────────────────────────────────────────
            if (person.title != null && person.title!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                person.title!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.chip.copyWith(
                  fontSize: (size * 0.13).clamp(8, 12),
                  color: AppTheme.accentGold.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            // ── years ─────────────────────────────────────────────────
            if (person.birthYear != null) ...[
              const SizedBox(height: 2),
              Text(
                _years(person),
                textAlign: TextAlign.center,
                style: AppTheme.chip.copyWith(
                  fontSize: (size * 0.13).clamp(8, 11),
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _years(PersonModel p) {
    final parts = <String>[];
    if (p.birthYear != null) parts.add('${p.birthYear}');
    if (p.deathYear != null) parts.add('${p.deathYear}');
    return parts.join(' — ');
  }
}

class _Initials extends StatelessWidget {
  final String text;
  final double size;
  const _Initials({required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceLight,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.accentGold,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tree canvas widget – positions nodes via Positioned inside a Stack
// ═══════════════════════════════════════════════════════════════════════════

class _TreeCanvas extends StatelessWidget {
  final List<_LayoutNode> roots;
  final void Function(PersonModel) onPersonTap;

  const _TreeCanvas({required this.roots, required this.onPersonTap});

  @override
  Widget build(BuildContext context) {
    final canvasSize = _measureCanvas(roots);
    final nodes = <Widget>[];

    for (final root in roots) {
      _collectNodeWidgets(root, _kNodeLabel + 8, nodes, onPersonTap);
    }

    return SizedBox(
      width: canvasSize.width,
      height: canvasSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── lines layer (bottom) ──────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _TreeLinePainter(roots)),
          ),
          // ── node widgets (top) ────────────────────────────────────────
          ...nodes,
        ],
      ),
    );
  }

  /// Recursively build Positioned widgets for every person node.
  void _collectNodeWidgets(
    _LayoutNode node,
    double topY,
    List<Widget> out,
    void Function(PersonModel) onTap,
  ) {
    final slot = node.nodeSize + 30;
    final avatarLeft = node.nodeCenterX - slot / 2;

    // Primary person
    out.add(Positioned(
      left: avatarLeft,
      top: topY,
      child: _PersonNode(
        person: node.source.person,
        size: node.nodeSize,
        onTap: () => onTap(node.source.person),
      ),
    ));

    // Spouse (if present)
    if (node.spouseCenterX != null && node.source.spouse != null) {
      final spouseLeft = node.spouseCenterX! - slot / 2;
      out.add(Positioned(
        left: spouseLeft,
        top: topY,
        child: _PersonNode(
          person: node.source.spouse!,
          size: node.nodeSize,
          onTap: () => onTap(node.source.spouse!),
        ),
      ));
    }

    if (node.children.isEmpty) return;

    // Recurse to children.
    final trunkBottom = topY + node.nodeSize + _kNodeLabel + _kVStep;
    final nextTopY = trunkBottom + _kHStep;
    for (final child in node.children) {
      _collectNodeWidgets(child, nextTopY, out, onTap);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FamilyTreeScreen
// ═══════════════════════════════════════════════════════════════════════════

class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final FamilyTreeService _service = FamilyTreeService();

  void _openPersonDetail(PersonModel person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PersonDetailScreen(
          person: Person(
            name: person.name,
            birthDate: person.birthYear?.toString(),
            deathDate: person.deathYear?.toString(),
            description: person.shortBio,
            imageUrl: person.avatarUrl,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PersonModel>>(
      stream: _service.watchAllPersons(),
      builder: (context, snapshot) {
        // ── loading ──────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentGold,
              strokeWidth: 2.5,
            ),
          );
        }

        // ── empty ────────────────────────────────────────────────────────
        final persons = snapshot.data ?? [];
        if (persons.isEmpty) {
          return Center(
            child: Text(
              'Удмын модны мэдээлэл олдсонгүй',
              style: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
            ),
          );
        }

        // ── build layout model ───────────────────────────────────────────
        final roots = FamilyTreeService.buildTree(persons);

        // Lay out multiple roots side by side with a gap between them.
        double offsetX = 20;
        final layoutRoots = <_LayoutNode>[];
        for (final root in roots) {
          final l = _computeLayout(root, offsetX, _kNodeSize);
          layoutRoots.add(l);
          offsetX += l.subtreeWidth + _kColGap * 2;
        }

        // ── main scaffold ────────────────────────────────────────────────
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
              // Decorative top gold bar
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

              // Tree canvas
              Padding(
                padding: const EdgeInsets.only(top: 42),
                child: InteractiveViewer(
                  constrained: false,
                  minScale: 0.25,
                  maxScale: 3.0,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _TreeCanvas(
                      roots: layoutRoots,
                      onPersonTap: _openPersonDetail,
                    ),
                  ),
                ),
              ),

              // Zoom hint
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pinch_outlined,
                            size: 14,
                            color: AppTheme.textSecondary.withOpacity(0.7)),
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
            ],
          ),
        );
      },
    );
  }
}
