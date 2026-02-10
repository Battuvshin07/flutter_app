/// Mongol Empire territory boundary data and conquest markers.
///
/// The empire polygon is a simplified boundary of the Mongol Empire
/// at its peak (~1279 AD), plotted as lat/lon coordinate pairs.
library;

import 'package:flutter/material.dart';

/// A single conquest/city marker on the 3D globe.
class ConquestMarker {
  final String id;
  final String nameEn;
  final String nameMn;
  final double lat;
  final double lon;
  final String year;
  final String role;
  final String description;
  final Color color;

  const ConquestMarker({
    required this.id,
    required this.nameEn,
    required this.nameMn,
    required this.lat,
    required this.lon,
    required this.year,
    required this.role,
    required this.description,
    required this.color,
  });
}

/// Static data class holding all Mongol Empire geography data.
class EmpireTerritory {
  EmpireTerritory._();

  /// Approximate boundary polygon of the Mongol Empire at peak (lat, lon).
  /// Used to draw connections forming the border outline on the 3D globe.
  static const List<List<double>> boundaryCoords = [
    // Eastern Europe (Golden Horde western edge)
    [55.0, 25.0],
    [56.0, 30.0],
    [57.0, 38.0],
    [58.0, 45.0],
    [56.0, 55.0],
    // Northern Siberia
    [60.0, 65.0],
    [62.0, 75.0],
    [60.0, 85.0],
    [58.0, 95.0],
    [55.0, 105.0],
    [53.0, 115.0],
    // Manchuria / Korea border
    [50.0, 125.0],
    [45.0, 130.0],
    [42.0, 128.0],
    // Eastern China coast
    [38.0, 122.0],
    [34.0, 119.0],
    [30.0, 118.0],
    [25.0, 114.0],
    // Southern China / Vietnam border
    [22.0, 108.0],
    [21.0, 100.0],
    // Tibet / Myanmar border
    [26.0, 92.0],
    [28.0, 85.0],
    [30.0, 78.0],
    // India / Pakistan border
    [32.0, 70.0],
    [30.0, 65.0],
    // Persia / Afghanistan
    [33.0, 60.0],
    [35.0, 55.0],
    // Iraq / Mesopotamia
    [33.0, 45.0],
    [34.0, 40.0],
    // Anatolia / Caucasus
    [38.0, 38.0],
    [40.0, 35.0],
    // Black Sea / Crimea
    [45.0, 35.0],
    [47.0, 33.0],
    // Back to Eastern Europe
    [50.0, 28.0],
    [55.0, 25.0], // close the loop
  ];

  /// Key historical conquest locations.
  static const List<ConquestMarker> markers = [
    ConquestMarker(
      id: 'karakorum',
      nameEn: 'Karakorum',
      nameMn: 'Харахорум',
      lat: 47.2,
      lon: 102.8,
      year: '1220',
      role: 'Imperial Capital',
      description: 'Каракорум — Их Монгол Улсын нийслэл хот. '
          'Өгөдэй хаан 1235 онд барьж байгуулсан. '
          'Дэлхийн олон орноос элчин сайд, худалдаачид ирж байсан олон улсын төв.',
      color: Color(0xFFFFD700),
    ),
    ConquestMarker(
      id: 'beijing',
      nameEn: 'Beijing (Khanbaliq)',
      nameMn: 'Бээжин (Хаанбалиг)',
      lat: 39.9,
      lon: 116.4,
      year: '1271',
      role: 'Yuan Dynasty Capital',
      description:
          'Хубилай хаан Юань гүрнийг үндэслэж, Бээжинг нийслэл болгосон. '
          'Марко Поло энд зочилж, дэлхийд алдаршуулсан.',
      color: Color(0xFF8B0000),
    ),
    ConquestMarker(
      id: 'samarkand',
      nameEn: 'Samarkand',
      nameMn: 'Самарканд',
      lat: 39.65,
      lon: 66.96,
      year: '1220',
      role: 'Khwarezmian Conquest',
      description: 'Хорезмийн эзэнт гүрний нэг гол хот. '
          'Чингис хаан 1220 онд байлдан дагуулсан. '
          'Торгоны замын гол цэг байсан.',
      color: Color(0xFFD2691E),
    ),
    ConquestMarker(
      id: 'baghdad',
      nameEn: 'Baghdad',
      nameMn: 'Багдад',
      lat: 33.3,
      lon: 44.4,
      year: '1258',
      role: 'Fall of the Abbasid Caliphate',
      description:
          'Хүлэгү хаан Багдадыг бүслэн авч, Аббасын халифатыг устгасан. '
          'Энэ нь Ислам ертөнцийн түүхэнд чухал эргэлт болсон.',
      color: Color(0xFFB8860B),
    ),
    ConquestMarker(
      id: 'moscow',
      nameEn: 'Moscow',
      nameMn: 'Москва',
      lat: 55.75,
      lon: 37.62,
      year: '1238',
      role: 'Golden Horde Invasion',
      description:
          'Бат хааны удирдлага дор Москвагийн муж улсыг байлдан дагуулсан. '
          'Алтан Ордны улс 240 жилийн турш Оросыг захирсан.',
      color: Color(0xFF4682B4),
    ),
    ConquestMarker(
      id: 'golden_horde',
      nameEn: 'Sarai (Golden Horde)',
      nameMn: 'Сарай (Алтан Ордны Улс)',
      lat: 48.5,
      lon: 45.0,
      year: '1242',
      role: 'Golden Horde Capital',
      description: 'Бат хаан Алтан Ордны улсыг үндэслэж, '
          'Волга голын эрэг дээр Сарай хотыг нийслэл болгосон.',
      color: Color(0xFF6B8E23),
    ),
  ];
}
