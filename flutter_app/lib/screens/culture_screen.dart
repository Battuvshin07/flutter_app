import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// FR-07: Соёл, нийгмийн амьдралын мэдээлэл таниулах
/// Doc menu: "Хүмүүс, Үйл явдал, Газрын зураг, Quiz, Соёл"
class CultureScreen extends StatelessWidget {
  const CultureScreen({super.key});

  static const _brown = Color(0xFF3B2F2F);
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);
  static const _cardBg = Color(0xFFFFFBF5);

  static const _iconMap = {
    'landscape': Icons.landscape,
    'shield': Icons.shield,
    'route': Icons.route,
    'temple_buddhist': Icons.temple_buddhist,
    'edit_note': Icons.edit_note,
    'restaurant': Icons.restaurant,
  };

  static const _colorPalette = [
    Color(0xFF8B4513),
    Color(0xFF4682B4),
    Color(0xFFD2691E),
    Color(0xFF6B8E23),
    Color(0xFF8B0000),
    Color(0xFFB8860B),
  ];

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
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    final cultureList = provider.culture;
                    if (cultureList.isEmpty) {
                      return const Center(
                          child: Text('Соёлын мэдээлэл олдсонгүй'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: cultureList.length,
                      itemBuilder: (context, index) => _buildCultureCard(
                        context,
                        cultureList[index],
                        _colorPalette[index % _colorPalette.length],
                      ),
                    );
                  },
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
              'Соёл ба нийгэм',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _brown,
              ),
            ),
          ),
          const Icon(Icons.museum_outlined, color: _brown, size: 24),
        ],
      ),
    );
  }

  Widget _buildCultureCard(
      BuildContext context, Map<String, dynamic> item, Color color) {
    final icon = _iconMap[item['icon']] ?? Icons.info_outline;
    return GestureDetector(
      onTap: () => _showDetail(context, item, color),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: _brown.withOpacity(0.7),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _brown.withOpacity(0.4), size: 20),
          ],
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, Map<String, dynamic> item, Color color) {
    final icon = _iconMap[item['icon']] ?? Icons.info_outline;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _CultureDetailScreen(item: item, color: color, icon: icon),
      ),
    );
  }
}

class _CultureDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color color;
  final IconData icon;

  const _CultureDetailScreen({
    required this.item,
    required this.color,
    required this.icon,
  });

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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: _brown, size: 24),
                    ),
                    const Expanded(
                      child: Text(
                        'Дэлгэрэнгүй',
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Icon header
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 40),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _brown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['description'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
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
                        child: Text(
                          item['details'] ?? item['description'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: _brown.withOpacity(0.8),
                            height: 1.7,
                          ),
                        ),
                      ),
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
}
