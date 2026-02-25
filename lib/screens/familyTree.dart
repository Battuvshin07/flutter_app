import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/person.dart';
import '../components/person_node.dart';
import '../components/person_detail_card.dart';

// ─────────────────────────────────────────────────────────────────────
// Family tree data model: wraps a Person with tree-specific fields.
// ─────────────────────────────────────────────────────────────────────
class _TreeNode {
  final int id;
  final int? parentId;
  final Person person;
  final Color color;
  final List<_TreeNode> children = [];

  _TreeNode({
    required this.id,
    this.parentId,
    required this.person,
    required this.color,
  });
}

// ─────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key});

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);
  static const _brown = Color(0xFF3B2F2F);
  static const _gold = Color(0xFFB8860B);
  int? _selectedPersonId;

  // Hardcoded tree relationships matching the reference image.
  // IDs match person_id in persons.json.
  static const _relationships = <int, int?>{
    1: null, // Чингис хаан  (root)
    2: null, // Бөртэ үжин   (spouse, rendered beside Chinggis)
    3: 1, // Зүчи          → Чингис
    4: 1, // Цагадай        → Чингис
    5: 1, // Өгөдэй        → Чингис
    6: 1, // Тулуй          → Чингис
    7: 3, // Бат хаан       → Зүчи
    8: 6, // Мөнх хаан      → Тулуй
    9: 6, // Хубилай        → Тулуй
    10: 6, // Хүлэгү         → Тулуй
  };

  static const _nodeColors = <int, Color>{
    1: Color(0xFF8B4513),
    2: Color(0xFFA0522D),
    3: Color(0xFFD2691E),
    4: Color(0xFF4682B4),
    5: Color(0xFF6B8E23),
    6: Color(0xFF8B0000),
    7: Color(0xFF2E4057),
    8: Color(0xFF556B2F),
    9: Color(0xFF708090),
    10: Color(0xFFB8860B),
  };

  List<_TreeNode> _buildTree(List<Person> persons) {
    final Map<int, _TreeNode> nodeMap = {};

    for (final p in persons) {
      if (p.personId == null) continue;
      nodeMap[p.personId!] = _TreeNode(
        id: p.personId!,
        parentId: _relationships[p.personId!],
        person: p,
        color: _nodeColors[p.personId!] ?? const Color(0xFF8B4513),
      );
    }

    final roots = <_TreeNode>[];
    for (final n in nodeMap.values) {
      if (n.parentId != null && nodeMap.containsKey(n.parentId)) {
        nodeMap[n.parentId]!.children.add(n);
      } else {
        roots.add(n);
      }
    }
    return roots;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final roots = _buildTree(provider.persons);
        final chinggis =
            roots.firstWhere((n) => n.id == 1, orElse: () => roots.first);
        final borte = roots.where((n) => n.id == 2).firstOrNull;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_parchment, _parchmentDark],
            ),
          ),
          child: Stack(
            children: [
              // --- Decorative gold accent bar ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gold.withOpacity(0.4),
                        _gold.withOpacity(0.12),
                        _gold.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Title ---
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _parchment.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: _gold.withOpacity(0.3), width: 1),
                    ),
                    child: const Text(
                      '13-Р ЗУУНЫ МОНГОЛЫН ТҮҮХ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _brown,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // --- Zoomable / pannable tree ---
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
                            horizontal: 12, vertical: 10),
                        child: _buildTreeLayout(chinggis, borte, provider),
                      ),
                    ),
                  ),
                ),
              ),

              // --- Person detail card overlay ---
              if (_selectedPersonId != null) _buildDetailOverlay(provider),
            ],
          ),
        );
      },
    );
  }

  // ───────────── TREE LAYOUT ─────────────

  Widget _buildTreeLayout(
      _TreeNode chinggis, _TreeNode? borte, AppProvider provider) {
    return CustomPaint(
      foregroundPainter: _TreeLinePainter(
        chinggis: chinggis,
        borte: borte,
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // === Gen 1: Founding couple ===
          _buildGen1Row(chinggis, borte),
          const SizedBox(height: 55),
          // === Gen 2: Four sons ===
          _buildGen2Row(chinggis.children),
          const SizedBox(height: 55),
          // === Gen 3: Grandchildren ===
          _buildGen3Row(chinggis.children),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGen1Row(_TreeNode chinggis, _TreeNode? borte) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNode(chinggis, 80),
        if (borte != null) ...[
          const SizedBox(width: 40),
          _buildNode(borte, 80),
        ],
      ],
    );
  }

  Widget _buildGen2Row(List<_TreeNode> children) {
    if (children.isEmpty) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children
          .map((c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _buildNode(c, 65),
              ))
          .toList(),
    );
  }

  Widget _buildGen3Row(List<_TreeNode> gen2) {
    final allGrandchildren = <_TreeNode>[];
    for (final parent in gen2) {
      allGrandchildren.addAll(parent.children);
    }
    if (allGrandchildren.isEmpty) return const SizedBox();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left side: Batu Khan (Jochi's son)
        ...gen2
            .where((p) => p.id == 3)
            .expand((p) => p.children)
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      _buildNode(c, 58),
                      const SizedBox(height: 6),
                      _buildGroupLabel('Алтан Ордны\nхаад'),
                    ],
                  ),
                )),
        const SizedBox(width: 24),
        // Right side: Tolui's sons
        ...gen2
            .where((p) => p.id == 6)
            .expand((p) => p.children)
            .map((c) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildNode(c, 58),
                )),
      ],
    );
  }

  Widget _buildGroupLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _gold.withOpacity(0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: _brown.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNode(_TreeNode node, double size) {
    return PersonNode(
      person: node.person,
      size: size,
      accentColor: node.color,
      isSelected: _selectedPersonId == node.id,
      onTap: () {
        setState(() {
          _selectedPersonId = _selectedPersonId == node.id ? null : node.id;
        });
      },
    );
  }

  // ───────────── DETAIL OVERLAY ─────────────

  Widget _buildDetailOverlay(AppProvider provider) {
    final person = provider.getPersonById(_selectedPersonId!);
    if (person == null) return const SizedBox();

    final events = provider.getEventsForPerson(_selectedPersonId!);
    final eventNames = events.map((e) => e.title).toList();

    return PersonDetailCard(
      person: person,
      keyEvents: eventNames,
      onClose: () => setState(() => _selectedPersonId = null),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Custom painter for connecting lines between tree generations.
// ─────────────────────────────────────────────────────────────────────
class _TreeLinePainter extends CustomPainter {
  final _TreeNode chinggis;
  final _TreeNode? borte;

  _TreeLinePainter({required this.chinggis, this.borte});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5C4033)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;

    // ── Gen1 couple connector (horizontal) ──
    if (borte != null) {
      final chX = midX - 35;
      final boX = midX + 35;
      const coupleY = 80.0;
      canvas.drawLine(Offset(chX, coupleY), Offset(boX, coupleY), paint);
    }

    // ── Couple → Gen2 vertical & horizontal fan ──
    final gen2 = chinggis.children;
    if (gen2.isEmpty) return;

    const gen1BottomY = 108.0;
    const gen2TopY = 163.0;
    const gen2MidY = (gen1BottomY + gen2TopY) / 2;

    canvas.drawLine(Offset(midX, gen1BottomY), Offset(midX, gen2MidY), paint);

    const nodeW = 95.0;
    const gap = 20.0;
    final totalW = gen2.length * nodeW + (gen2.length - 1) * gap;
    final startX = midX - totalW / 2;

    final gen2Xs = List.generate(gen2.length, (i) {
      return startX + i * (nodeW + gap) + nodeW / 2;
    });

    if (gen2Xs.length > 1) {
      canvas.drawLine(
          Offset(gen2Xs.first, gen2MidY), Offset(gen2Xs.last, gen2MidY), paint);
    }

    for (final x in gen2Xs) {
      canvas.drawLine(Offset(x, gen2MidY), Offset(x, gen2TopY), paint);
    }

    // ── Gen2 → Gen3 lines ──
    const gen2BottomY = 253.0;
    const gen3TopY = 308.0;
    const gen3MidY = (gen2BottomY + gen3TopY) / 2;

    double grandStartX = midX - 160;
    const grandSpacing = 76.0;

    for (int i = 0; i < gen2.length; i++) {
      final parent = gen2[i];
      if (parent.children.isEmpty) continue;

      final parentX = gen2Xs[i];
      List<double> childXs = [];

      if (parent.id == 3) {
        childXs = [grandStartX + 50];
      } else if (parent.id == 6) {
        final rightStart = midX + 10;
        childXs = List.generate(
            parent.children.length, (j) => rightStart + j * grandSpacing);
      }

      if (childXs.isEmpty) continue;

      canvas.drawLine(
          Offset(parentX, gen2BottomY), Offset(parentX, gen3MidY), paint);

      if (childXs.length == 1) {
        canvas.drawLine(
            Offset(parentX, gen3MidY), Offset(childXs[0], gen3MidY), paint);
      } else {
        final allX = [parentX, ...childXs];
        allX.sort();
        canvas.drawLine(
            Offset(allX.first, gen3MidY), Offset(allX.last, gen3MidY), paint);
      }

      for (final cx in childXs) {
        canvas.drawLine(Offset(cx, gen3MidY), Offset(cx, gen3TopY), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
