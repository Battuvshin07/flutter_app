import 'package:flutter/material.dart';
import '../models/empire_territory.dart';

/// A flat 2D equirectangular world map with Mongol Empire borders and markers.
///
/// Uses the same earth texture as the 3D globe, projected flat, with
/// [InteractiveViewer] for pan & zoom.
class FlatMapWidget extends StatefulWidget {
  final String? selectedMarkerId;
  final bool showEmpire;
  final ValueChanged<ConquestMarker> onMarkerTapped;

  const FlatMapWidget({
    super.key,
    this.selectedMarkerId,
    required this.showEmpire,
    required this.onMarkerTapped,
  });

  @override
  State<FlatMapWidget> createState() => _FlatMapWidgetState();
}

class _FlatMapWidgetState extends State<FlatMapWidget> {
  final TransformationController _transformCtrl = TransformationController();

  // The inner map canvas uses a 2:1 equirectangular aspect ratio.
  // We pick a generous base width so markers/text stay sharp when zoomed.
  static const double _baseMapWidth = 2400;
  static const double _baseMapHeight = _baseMapWidth / 2; // 1200

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnEmpire());
  }

  void _centerOnEmpire() {
    if (!mounted) return;
    final vw = MediaQuery.of(context).size.width;
    final vh = MediaQuery.of(context).size.height;

    // BoxFit.cover: scale so the map fills the entire viewport with no
    // empty space, keeping the 2:1 equirectangular aspect ratio intact.
    final scaleX = vw / _baseMapWidth;
    final scaleY = vh / _baseMapHeight;
    final scale = scaleX > scaleY ? scaleX : scaleY;

    // Center the scaled canvas in the viewport.
    final tx = (vw - _baseMapWidth * scale) / 2.0;
    final ty = (vh - _baseMapHeight * scale) / 2.0;

    final m = Matrix4.identity();
    m.storage[0] = scale; // scaleX
    m.storage[5] = scale; // scaleY
    m.storage[12] = tx; // translateX
    m.storage[13] = ty; // translateY
    _transformCtrl.value = m;
  }

  double _lonToX(double lon, double width) => (lon + 180) / 360 * width;
  double _latToY(double lat, double height) => (90 - lat) / 180 * height;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // The inner canvas is always the full 2:1 equirectangular map.
      // InteractiveViewer handles panning/zooming within it.
      return InteractiveViewer(
        transformationController: _transformCtrl,
        minScale: 0.05,
        maxScale: 8.0,
        constrained: false,
        child: SizedBox(
          width: _baseMapWidth,
          height: _baseMapHeight,
          child: Stack(
            children: [
              // Earth texture — BoxFit.fill so it maps exactly to 2:1 canvas
              Positioned.fill(
                child: Image.asset(
                  'assets/maps/earth_texture.png',
                  fit: BoxFit.fill,
                  color: Colors.black.withValues(alpha: 0.15),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              // Empire border & route lines painted on top
              Positioned.fill(
                child: CustomPaint(
                  painter: _EmpireOverlayPainter(
                    showEmpire: widget.showEmpire,
                    selectedMarkerId: widget.selectedMarkerId,
                  ),
                ),
              ),
              // Interactive marker hit targets
              ..._buildMarkerWidgets(_baseMapWidth, _baseMapHeight),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildMarkerWidgets(double mapW, double mapH) {
    return EmpireTerritory.markers.map((m) {
      final x = _lonToX(m.lon, mapW);
      final y = _latToY(m.lat, mapH);
      final isSelected = widget.selectedMarkerId == m.id;
      final isCapital = m.id == 'karakorum';
      final dotSize = isCapital ? 16.0 : 12.0;

      return Positioned(
        left: x - 55,
        top: y - 56,
        child: GestureDetector(
          onTap: () => widget.onMarkerTapped(m),
          child: SizedBox(
            width: 110,
            height: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D17).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? m.color : m.color.withValues(alpha: 0.5),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: m.color.withValues(alpha: 0.5),
                                blurRadius: 10)
                          ]
                        : [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4)
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.nameEn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        m.year,
                        style: TextStyle(
                          color: m.color,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                // Dot
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: m.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: m.color.withValues(alpha: 0.6),
                        blurRadius: isSelected ? 12 : 6,
                        spreadRadius: isSelected ? 3 : 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Custom painter that draws the empire border polygon and dashed route lines.
class _EmpireOverlayPainter extends CustomPainter {
  final bool showEmpire;
  final String? selectedMarkerId;

  _EmpireOverlayPainter({
    required this.showEmpire,
    this.selectedMarkerId,
  });

  double _lonToX(double lon, double w) => (lon + 180) / 360 * w;
  double _latToY(double lat, double h) => (90 - lat) / 180 * h;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    if (showEmpire) {
      _drawEmpireFill(canvas, w, h);
      _drawEmpireBorder(canvas, w, h);
    }
    _drawRouteLines(canvas, w, h);
  }

  void _drawEmpireFill(Canvas canvas, double w, double h) {
    const coords = EmpireTerritory.boundaryCoords;
    final path = Path();
    path.moveTo(_lonToX(coords[0][1], w), _latToY(coords[0][0], h));
    for (int i = 1; i < coords.length; i++) {
      path.lineTo(_lonToX(coords[i][1], w), _latToY(coords[i][0], h));
    }
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);
  }

  void _drawEmpireBorder(Canvas canvas, double w, double h) {
    const coords = EmpireTerritory.boundaryCoords;
    final borderPaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(_lonToX(coords[0][1], w), _latToY(coords[0][0], h));
    for (int i = 1; i < coords.length; i++) {
      path.lineTo(_lonToX(coords[i][1], w), _latToY(coords[i][0], h));
    }
    path.close();
    canvas.drawPath(path, borderPaint);
  }

  void _drawRouteLines(Canvas canvas, double w, double h) {
    final capital =
        EmpireTerritory.markers.firstWhere((m) => m.id == 'karakorum');
    final cx = _lonToX(capital.lon, w);
    final cy = _latToY(capital.lat, h);

    for (final m in EmpireTerritory.markers) {
      if (m.id == 'karakorum') continue;
      final mx = _lonToX(m.lon, w);
      final my = _latToY(m.lat, h);

      final routePaint = Paint()
        ..color = m.color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      // Draw dashed line
      final dx = mx - cx;
      final dy = my - cy;
      final totalLen = (Offset(cx, cy) - Offset(mx, my)).distance;
      const dashLen = 4.0;
      const gapLen = 4.0;

      final path = Path();
      double drawn = 0;
      bool drawing = true;
      while (drawn < totalLen) {
        final segLen = drawing ? dashLen : gapLen;
        final end = (drawn + segLen).clamp(0.0, totalLen);
        final t1 = drawn / totalLen;
        final t2 = end / totalLen;
        if (drawing) {
          path.moveTo(cx + dx * t1, cy + dy * t1);
          path.lineTo(cx + dx * t2, cy + dy * t2);
        }
        drawn += segLen;
        drawing = !drawing;
      }
      canvas.drawPath(path, routePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmpireOverlayPainter old) =>
      old.showEmpire != showEmpire || old.selectedMarkerId != selectedMarkerId;
}
