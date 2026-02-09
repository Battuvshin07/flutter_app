import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

/// FR-02: Байлдан дагуулалтын интерактив газрын зураг
/// "Интерактив зураг: Сум хийх (zoom), тулаан дээр дарах зэрэг интерактив үйлдлүүд"
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _brown = Color(0xFF3B2F2F);
  static const _parchment = Color(0xFFF2DFC3);
  static const _parchmentDark = Color(0xFFE8D0A8);

  final TransformationController _transformController =
      TransformationController();
  int? _selectedMapId;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

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
                    final maps = provider.dataService.maps;
                    if (maps.isEmpty) {
                      return const Center(
                          child: Text('Газрын зураг олдсонгүй'));
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: _buildInteractiveMap(context, maps, provider),
                        ),
                        _buildLegend(maps),
                      ],
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
              'Байлдан дагуулалтын газрын зураг',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _brown,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Icon(Icons.map_outlined, color: _brown, size: 24),
        ],
      ),
    );
  }

  Widget _buildInteractiveMap(
      BuildContext context, List mapDataList, AppProvider provider) {
    return InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 4.0,
      boundaryMargin: const EdgeInsets.all(100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return Stack(
            children: [
              // Base map background
              CustomPaint(
                size: Size(w, h),
                painter: _EmpireMapPainter(),
              ),
              // Conquest markers
              ...mapDataList.asMap().entries.map((entry) {
                final data = entry.value;
                final coords = data.coordinates.split(',');
                if (coords.length < 2) return const SizedBox.shrink();
                final lat = double.tryParse(coords[0].trim()) ?? 0;
                final lon = double.tryParse(coords[1].trim()) ?? 0;

                // Simple Mercator-like projection onto widget space
                // Longitude range ~19-117 → 0-w, Latitude range ~33-49 → h-0
                final x = ((lon - 15) / (120 - 15)) * w;
                final y = ((50 - lat) / (50 - 30)) * h;
                final color = Color(int.parse(
                    data.toMap()['color']?.toString() ?? '0xFF8B4513'));

                final isSelected = _selectedMapId == data.mapId;

                return Positioned(
                  left: x - (isSelected ? 18 : 14),
                  top: y - (isSelected ? 18 : 14),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMapId =
                            _selectedMapId == data.mapId ? null : data.mapId;
                      });
                      _showMapDetail(context, data, provider);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 36 : 28,
                      height: isSelected ? 36 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : color.withOpacity(0.5),
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: isSelected ? 12 : 6,
                            spreadRadius: isSelected ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.place,
                          color: Colors.white,
                          size: isSelected ? 18 : 14,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showMapDetail(
      BuildContext context, dynamic mapData, AppProvider provider) {
    final map = mapData.toMap();
    final color = Color(int.parse(map['color']?.toString() ?? '0xFF8B4513'));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.place, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mapData.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _brown,
                        ),
                      ),
                      Text(
                        map['year']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              map['description']?.toString() ?? mapData.title,
              style: TextStyle(
                fontSize: 14,
                color: _brown.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List mapDataList) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mapDataList.length,
        itemBuilder: (context, index) {
          final data = mapDataList[index];
          final map = data.toMap();
          final color =
              Color(int.parse(map['color']?.toString() ?? '0xFF8B4513'));
          final isSelected = _selectedMapId == data.mapId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMapId =
                    _selectedMapId == data.mapId ? null : data.mapId;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : const Color(0xFFFFFBF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: color, size: 10),
                  const SizedBox(height: 4),
                  Text(
                    data.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _brown,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the empire territory background
class _EmpireMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a stylized ancient map background
    final bgPaint = Paint()..color = const Color(0xFFE8D0A8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines to simulate map
    final gridPaint = Paint()
      ..color = const Color(0xFFD4BA94)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += size.width / 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Empire territory (rough shape)
    final empPaint = Paint()
      ..color = const Color(0xFFC4A46C).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.1,
        size.width * 0.5, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.1,
        size.width * 0.85, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.95, size.height * 0.5,
        size.width * 0.85, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.85,
        size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.85,
        size.width * 0.15, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.05, size.height * 0.5,
        size.width * 0.15, size.height * 0.3);
    path.close();
    canvas.drawPath(path, empPaint);

    // Empire border
    final borderPaint = Paint()
      ..color = const Color(0xFF8B4513).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Title
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Монголын Эзэнт Гүрэн',
        style: TextStyle(
          color: Color(0xFF8B4513),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, size.height * 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
