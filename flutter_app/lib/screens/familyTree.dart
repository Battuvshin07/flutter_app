import 'package:flutter/material.dart';

class FamilyTreeScreen extends StatelessWidget {
  const FamilyTreeScreen({super.key});

  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);
  static const _cardBg = Color(0xFFFFFBF5);
  static const _brown = Color(0xFF3B2F2F);
  static const _lineColor = Color(0xFF2D2D2D);
  static const _gold = Color(0xFFB8860B);

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: LayoutBuilder(
                    builder: (ctx, box) => _buildTree(box.maxWidth),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomSection(),
    );
  }

  // ======================== APP BAR ========================

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
              "Genghis Khan's Family Tree",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _brown,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const FlutterLogo(size: 30),
        ],
      ),
    );
  }

  // ======================== TREE ========================

  Widget _buildTree(double w) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // === Generation 1: Founders ===
        _buildGen1(),
        SizedBox(
          width: w,
          height: 45,
          child: CustomPaint(painter: _CoupleToSonsPainter()),
        ),
        // === Generation 2: Four Sons ===
        _buildGen2(),
        // Chagatai Ulus label
        Align(
          alignment: const Alignment(0.25, 0),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: _buildDropdownChip('Khans of the\nChagatai Ulus'),
          ),
        ),
        SizedBox(
          width: w,
          height: 55,
          child: CustomPaint(painter: _SonsToGrandsPainter()),
        ),
        // === Generation 3: Grandchildren ===
        _buildGen3(),
        SizedBox(
          width: w,
          height: 50,
          child: CustomPaint(painter: _BatuToGreatGrandsPainter()),
        ),
        // === Generation 4: Great-Grandchildren ===
        _buildGen4(),
        const SizedBox(height: 20),
      ],
    );
  }

  // ======================== GEN 1 ========================

  Widget _buildGen1() {
    return Row(
      children: [
        Expanded(
          child: _buildPersonCard(
            name: 'Genghis Khan',
            color: const Color(0xFF8B4513),
            initials: 'GK',
            avatarSize: 70,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPersonCard(
            name: 'Borte Udjin',
            color: const Color(0xFFA0522D),
            initials: 'BU',
            avatarSize: 70,
          ),
        ),
      ],
    );
  }

  // ======================== GEN 2 ========================

  Widget _buildGen2() {
    return Row(
      children: [
        Expanded(
          child: _buildPersonCard(
            name: 'Jochi',
            color: const Color(0xFFD2691E),
            initials: 'J',
            avatarSize: 55,
          ),
        ),
        Expanded(
          child: _buildPersonCard(
            name: 'Ogedei',
            color: const Color(0xFF6B8E23),
            initials: 'O',
            avatarSize: 55,
          ),
        ),
        Expanded(
          child: _buildPersonCard(
            name: 'Chagatai',
            color: const Color(0xFF4682B4),
            initials: 'Ch',
            avatarSize: 55,
          ),
        ),
        Expanded(
          child: _buildPersonCard(
            name: 'Tolui',
            color: const Color(0xFF8B0000),
            initials: 'T',
            avatarSize: 55,
          ),
        ),
      ],
    );
  }

  // ======================== GEN 3 ========================

  Widget _buildGen3() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Batu Khan + Guyuk Khan
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildPersonCard(
                  name: 'Batu Khan',
                  subtitle: 'Khans of the\nBlue Horde',
                  color: const Color(0xFF2E4057),
                  initials: 'BK',
                  avatarSize: 50,
                ),
              ),
              Expanded(
                child: _buildPersonCard(
                  name: 'Guyuk Khan',
                  color: const Color(0xFF4A6B8A),
                  initials: 'GY',
                  avatarSize: 50,
                ),
              ),
            ],
          ),
        ),
        // Right: Tolui's descendants grouped
        Expanded(
          flex: 6,
          child: _buildToluiDescendantsCard(),
        ),
      ],
    );
  }

  Widget _buildToluiDescendantsCard() {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildMiniPerson('Mongke', const Color(0xFF556B2F))),
              Expanded(
                  child: _buildMiniPerson('Kublai', const Color(0xFF708090))),
              Expanded(
                  child:
                      _buildMiniPerson('Ariq\nBoke', const Color(0xFF8B7355))),
              Expanded(
                  child: _buildMiniPerson('Hulagu', const Color(0xFFB8860B))),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Yuan Emperors',
              style: TextStyle(
                fontSize: 11,
                color: _brown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======================== GEN 4 ========================

  Widget _buildGen4() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildPersonCard(
                      name: 'Orda Ichen',
                      color: const Color(0xFF808080),
                      initials: 'OI',
                      avatarSize: 45,
                      badge: 'Berke',
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitleChip('Khans of the\nWhite Horde'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildPersonCard(
                      name: 'Shayban',
                      color: const Color(0xFF6B4226),
                      initials: 'Sh',
                      avatarSize: 45,
                    ),
                    const SizedBox(height: 4),
                    _buildSubtitleChip('Khans of the\nShayban Ulus'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Expanded(flex: 6, child: SizedBox()),
      ],
    );
  }

  // ======================== REUSABLE COMPONENTS ========================

  Widget _buildPersonCard({
    required String name,
    required Color color,
    required String initials,
    double avatarSize = 55,
    String? subtitle,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildAvatar(initials: initials, color: color, size: avatarSize),
              if (badge != null)
                Positioned(
                  right: -22,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _brown,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _brown,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: _brown.withOpacity(0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String initials,
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: _gold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.28,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPerson(String name, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar(initials: name.characters.first, color: color, size: 40),
        const SizedBox(height: 4),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _brown,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: _brown),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: _brown),
        ],
      ),
    );
  }

  Widget _buildSubtitleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: _brown),
      ),
    );
  }

  // ======================== BOTTOM NAV + FOOTER ========================

  Widget _buildBottomSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBottomNav(),
        _buildFooter(),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.account_tree, 'Tree', true),
          _buildNavItem(Icons.format_list_bulleted, 'Timeline', false),
          _buildNavItem(Icons.search, 'Search', false),
          _buildNavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool selected) {
    final color = selected ? const Color(0xFF8B4513) : Colors.grey;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powered by ',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const FlutterLogo(size: 20),
          Text(
            ' Flutter',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 24),
          Icon(Icons.blur_circular, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            'MyHeritage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== TREE LINE PAINTERS ========================

/// Draws connecting lines from the founding couple down to the four sons.
class _CoupleToSonsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final midY = size.height * 0.5;

    // Vertical from couple center down
    canvas.drawLine(Offset(midX, 0), Offset(midX, midY), paint);

    // Son centers (4 Expanded widgets → centers at 1/8, 3/8, 5/8, 7/8)
    final xs = [
      size.width * 0.125,
      size.width * 0.375,
      size.width * 0.625,
      size.width * 0.875,
    ];

    // Horizontal bar
    canvas.drawLine(Offset(xs.first, midY), Offset(xs.last, midY), paint);

    // Vertical drops to each son
    for (final x in xs) {
      canvas.drawLine(Offset(x, midY), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws connecting lines from sons (Gen2) to grandchildren (Gen3).
class _SonsToGrandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final midY = size.height * 0.4;

    // Jochi (0.125) → Batu Khan (left section: flex 5/11, first Expanded → center ~5/44)
    final jochiX = size.width * 0.125;
    final batuX = size.width * 5 / 44;
    _drawElbow(canvas, paint, jochiX, 0, batuX, size.height, midY);

    // Ogedei (0.375) → Guyuk Khan (left section: second Expanded → center ~15/44)
    final ogedeiX = size.width * 0.375;
    final guyukX = size.width * 15 / 44;
    _drawElbow(canvas, paint, ogedeiX, 0, guyukX, size.height, midY);

    // Tolui (0.875) → center of Tolui group card (right section center ~8/11)
    final toluiX = size.width * 0.875;
    final groupCenterX = size.width * 8 / 11;
    _drawElbow(canvas, paint, toluiX, 0, groupCenterX, size.height, midY);
  }

  void _drawElbow(Canvas canvas, Paint paint, double fromX, double fromY,
      double toX, double toY, double midY) {
    canvas.drawLine(Offset(fromX, fromY), Offset(fromX, midY), paint);
    canvas.drawLine(Offset(fromX, midY), Offset(toX, midY), paint);
    canvas.drawLine(Offset(toX, midY), Offset(toX, toY), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws connecting lines from Batu Khan to Orda Ichen and Shayban.
class _BatuToGreatGrandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2D2D)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Batu center (left section flex 5/11, first Expanded → 5/44)
    final batuX = size.width * 5 / 44;
    // Orda center: same position as Batu (5/44)
    final ordaX = size.width * 5 / 44;
    // Shayban center (left section, second Expanded → 15/44)
    final shaybanX = size.width * 15 / 44;
    final midY = size.height * 0.45;

    // Vertical from Batu
    canvas.drawLine(Offset(batuX, 0), Offset(batuX, midY), paint);
    // Horizontal bar spanning Orda to Shayban
    canvas.drawLine(Offset(ordaX, midY), Offset(shaybanX, midY), paint);
    // Vertical drops
    canvas.drawLine(Offset(ordaX, midY), Offset(ordaX, size.height), paint);
    canvas.drawLine(
        Offset(shaybanX, midY), Offset(shaybanX, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
