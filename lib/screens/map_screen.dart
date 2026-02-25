import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import '../models/empire_territory.dart';
import '../components/flat_map_widget.dart';

/// FR-02: Mongol Empire - 3D Interactive Globe & 2D Flat Map
/// Rotatable, zoomable 3D Earth with empire territory border and conquest markers.
/// Toggles between 3D globe and 2D flat map with smooth animated crossfade.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  // Theme
  static const _bgDark = Color(0xFF0B0D17);
  static const _cardBg = Color(0xFF1A1D2E);
  static const _empireRed = Color(0xFFE53935);

  // State
  late FlutterEarthGlobeController _globeCtrl;
  bool _showEmpire = true;
  bool _globeReady = false;
  String? _selectedMarkerId;

  /// true = 3D globe, false = 2D flat map
  bool _is3D = true;

  /// Animation controller for crossfade / scale transition
  late AnimationController _viewToggleCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _fadeOut;
  late Animation<double> _scaleIn;
  late Animation<double> _scaleOut;

  @override
  void initState() {
    super.initState();
    _initGlobe();
    _initViewToggleAnimation();
  }

  void _initViewToggleAnimation() {
    _viewToggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Outgoing view fades/scales out in the first half
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _viewToggleCtrl,
          curve: const Interval(0.0, 0.45, curve: Curves.easeIn)),
    );
    _scaleOut = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
          parent: _viewToggleCtrl,
          curve: const Interval(0.0, 0.45, curve: Curves.easeIn)),
    );
    // Incoming view fades/scales in in the second half
    _fadeIn = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _viewToggleCtrl,
          curve: const Interval(0.50, 1.0, curve: Curves.easeOut)),
    );
    _scaleIn = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
          parent: _viewToggleCtrl,
          curve: const Interval(0.50, 1.0, curve: Curves.easeOut)),
    );
  }

  void _toggleViewMode() {
    if (_viewToggleCtrl.isAnimating) return;
    _viewToggleCtrl.forward(from: 0).then((_) {
      setState(() => _is3D = !_is3D);
      _viewToggleCtrl.reset();
    });
  }

  void _initGlobe() {
    _globeCtrl = FlutterEarthGlobeController(
      rotationSpeed: 0.02,
      isZoomEnabled: true,
      zoom: 0.4,
      minZoom: -0.5,
      maxZoom: 3.0,
      isRotating: true,
      isBackgroundFollowingSphereRotation: true,
      surface: Image.asset('assets/maps/earth_texture.png').image,
      background: Image.asset('assets/maps/stars_bg.jpg').image,
      showAtmosphere: true,
      atmosphereColor: const Color(0xFF4FC3F7),
      atmosphereOpacity: 0.35,
      atmosphereThickness: 0.12,
    );

    _globeCtrl.onLoaded = () {
      if (!mounted) return;
      setState(() => _globeReady = true);
      _addEmpireData();
    };
  }

  void _addEmpireData() {
    _addEmpireBorder();
    _addConquestMarkers();
  }

  void _addEmpireBorder() {
    if (!_showEmpire) return;
    const coords = EmpireTerritory.boundaryCoords;
    for (int i = 0; i < coords.length - 1; i++) {
      _globeCtrl.addPointConnection(
        PointConnection(
          id: 'border-$i',
          start: GlobeCoordinates(coords[i][0], coords[i][1]),
          end: GlobeCoordinates(coords[i + 1][0], coords[i + 1][1]),
          style: PointConnectionStyle(
            type: PointConnectionType.solid,
            color: _empireRed.withValues(alpha: 0.7),
            lineWidth: 2.5,
          ),
        ),
        animateDraw: true,
        animateDrawDuration: const Duration(milliseconds: 800),
      );
    }
  }

  void _addConquestMarkers() {
    for (final m in EmpireTerritory.markers) {
      _globeCtrl.addPoint(Point(
        id: m.id,
        coordinates: GlobeCoordinates(m.lat, m.lon),
        label: m.nameEn,
        isLabelVisible: true,
        style: PointStyle(
          color: m.color,
          size: m.id == 'karakorum' ? 8 : 6,
          altitude: 0.05,
          transitionDuration: 600,
        ),
        labelBuilder: (context, point, isHovering, isVisible) {
          if (!isVisible) return null;
          return _buildPointLabel(m, isHovering);
        },
        onTap: () => _onMarkerTapped(m),
      ));
    }

    // Conquest route connections from Karakorum
    final conquests = EmpireTerritory.markers.where((m) => m.id != 'karakorum');
    final capital =
        EmpireTerritory.markers.firstWhere((m) => m.id == 'karakorum');
    for (final c in conquests) {
      _globeCtrl.addPointConnection(
        PointConnection(
          id: 'route-${c.id}',
          start: GlobeCoordinates(capital.lat, capital.lon),
          end: GlobeCoordinates(c.lat, c.lon),
          style: PointConnectionStyle(
            type: PointConnectionType.dashed,
            color: c.color.withValues(alpha: 0.5),
            dashSize: 3,
            spacing: 6,
            lineWidth: 1.5,
            dashAnimateTime: 3000,
          ),
        ),
        animateDraw: true,
        animateDrawDuration: const Duration(seconds: 2),
      );
    }
  }

  Widget? _buildPointLabel(ConquestMarker m, bool isHovering) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isHovering ? _cardBg : _bgDark).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: m.color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(color: m.color.withValues(alpha: 0.3), blurRadius: 6),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.nameEn,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          Text(m.year,
              style: TextStyle(
                  color: m.color, fontSize: 8, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _onMarkerTapped(ConquestMarker marker) {
    setState(() => _selectedMarkerId = marker.id);
    if (_is3D) {
      _globeCtrl.focusOnCoordinates(
        GlobeCoordinates(marker.lat, marker.lon),
        animate: true,
      );
    }
    _showConquestDetail(marker);
  }

  void _toggleEmpireVisibility() {
    setState(() => _showEmpire = !_showEmpire);

    if (_showEmpire) {
      _addEmpireBorder();
    } else {
      const coords = EmpireTerritory.boundaryCoords;

      for (int i = 0; i < coords.length - 1; i++) {
        _globeCtrl.removePointConnection('border-$i');
      }
    }
  }

  void _resetGlobe() {
    _globeCtrl.resetRotation();
    _globeCtrl.setZoom(0.4);
    _globeCtrl.startRotation(rotationSpeed: 0.02);
    setState(() => _selectedMarkerId = null);
  }

  @override
  void dispose() {
    _viewToggleCtrl.dispose();
    // Do NOT call _globeCtrl.dispose() here.
    // The FlutterEarthGlobe widget's State already disposes the
    // controller's rotationController and internal AnimationControllers
    // in its own dispose(). Calling it again causes:
    //   "AnimationController.dispose() called more than once."
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            // Animated map view (3D globe or 2D flat map)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _viewToggleCtrl,
                builder: (context, child) => _buildAnimatedMapView(context),
              ),
            ),
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context),
            ),
            // Controls
            Positioned(
              right: 16,
              bottom: 180,
              child: _buildControlButtons(),
            ),
            // Legend
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildConquestLegend(),
            ),
            // Loading (only for 3D globe)
            if (!_globeReady && _is3D)
              Container(
                color: _bgDark,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _empireRed),
                      SizedBox(height: 16),
                      Text('Loading Globe...',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMapView(BuildContext context) {
    final isAnimating = _viewToggleCtrl.isAnimating;

    // Determine which view is outgoing and which is incoming
    final Widget currentView = _is3D ? _build3DGlobe(context) : _build2DMap();
    final Widget nextView = _is3D ? _build2DMap() : _build3DGlobe(context);

    if (!isAnimating) {
      return currentView;
    }

    // During animation: crossfade with scale
    return Stack(
      children: [
        // Outgoing view
        FadeTransition(
          opacity: _fadeOut,
          child: ScaleTransition(
            scale: _scaleOut,
            child: currentView,
          ),
        ),
        // Incoming view
        FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: nextView,
          ),
        ),
      ],
    );
  }

  Widget _build3DGlobe(BuildContext context) {
    return FlutterEarthGlobe(
      controller: _globeCtrl,
      radius: MediaQuery.of(context).size.width * 0.42,
      onTap: (coords) {
        if (coords != null) {
          setState(() => _selectedMarkerId = null);
        }
      },
    );
  }

  Widget _build2DMap() {
    return FlatMapWidget(
      selectedMarkerId: _selectedMarkerId,
      showEmpire: _showEmpire,
      onMarkerTapped: _onMarkerTapped,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgDark, _bgDark.withValues(alpha: 0.0)],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mongol Empire',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5)),
                Text('13th Century - Interactive 3D Globe',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleViewMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _is3D
                    ? _empireRed.withValues(alpha: 0.2)
                    : const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _is3D
                      ? _empireRed.withValues(alpha: 0.4)
                      : const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      _is3D ? Icons.map_outlined : Icons.public,
                      key: ValueKey(_is3D),
                      color: _is3D ? _empireRed : const Color(0xFF4FC3F7),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: child,
                    ),
                    child: Text(
                      _is3D ? '2D' : '3D',
                      key: ValueKey(_is3D ? '2D' : '3D'),
                      style: TextStyle(
                        color: _is3D ? _empireRed : const Color(0xFF4FC3F7),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _controlBtn(
            icon: Icons.restart_alt,
            tooltip: 'Reset Rotation',
            onTap: _resetGlobe),
        const SizedBox(height: 10),
        _controlBtn(
            icon: _showEmpire ? Icons.visibility : Icons.visibility_off,
            tooltip: 'Toggle Empire',
            onTap: _toggleEmpireVisibility,
            isActive: _showEmpire),
        const SizedBox(height: 10),
        _controlBtn(
            icon: Icons.zoom_in,
            tooltip: 'Zoom In',
            onTap: () {
              final z = _globeCtrl.zoom + 0.3;
              if (z <= _globeCtrl.maxZoom) _globeCtrl.setZoom(z);
            }),
        const SizedBox(height: 10),
        _controlBtn(
            icon: Icons.zoom_out,
            tooltip: 'Zoom Out',
            onTap: () {
              final z = _globeCtrl.zoom - 0.3;
              if (z >= _globeCtrl.minZoom) _globeCtrl.setZoom(z);
            }),
      ],
    );
  }

  Widget _controlBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isActive
                ? _empireRed.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isActive
                    ? _empireRed.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon,
              color: isActive ? _empireRed : Colors.white70, size: 20),
        ),
      ),
    );
  }

  Widget _buildConquestLegend() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_bgDark, _bgDark.withValues(alpha: 0.0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: _empireRed, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('Conquest Locations',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              scrollDirection: Axis.horizontal,
              itemCount: EmpireTerritory.markers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final m = EmpireTerritory.markers[i];
                final sel = _selectedMarkerId == m.id;
                return GestureDetector(
                  onTap: () => _onMarkerTapped(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel
                          ? m.color.withValues(alpha: 0.2)
                          : _cardBg.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel
                              ? m.color
                              : Colors.white.withValues(alpha: 0.08),
                          width: sel ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on, color: m.color, size: 16),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 72,
                          child: Text(m.nameEn,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center),
                        ),
                        Text(m.year,
                            style: TextStyle(
                                fontSize: 9,
                                color: m.color.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showConquestDetail(ConquestMarker marker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: marker.color.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, -8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: marker.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: marker.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.shield, color: marker.color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(marker.nameEn,
                          style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(marker.nameMn,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: marker.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(marker.year,
                      style: TextStyle(
                          color: marker.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Info card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.account_balance, 'Empire',
                      'Great Mongol Empire', marker.color),
                  const SizedBox(height: 10),
                  _infoRow(Icons.calendar_today, 'Period', '1206 - 1368',
                      marker.color),
                  const SizedBox(height: 10),
                  _infoRow(
                      Icons.person, 'Founder', 'Genghis Khan', marker.color),
                  const SizedBox(height: 10),
                  _infoRow(
                      Icons.military_tech, 'Role', marker.role, marker.color),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Description
            Text(marker.description,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6)),
            const SizedBox(height: 12),
            // Fun fact
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _empireRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _empireRed.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: _empireRed.withValues(alpha: 0.6), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The Mongol Empire was the largest contiguous '
                      'land empire in history - spanning 24 million km\u00b2.',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withValues(alpha: 0.5),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color accent) {
    return Row(
      children: [
        Icon(icon, size: 16, color: accent.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Text('$label: ',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5))),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
