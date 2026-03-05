import 'package:cloud_firestore/cloud_firestore.dart';

/// A node in the family tree (represents one person).
class FamilyTreeNode {
  final String id;
  final String personId;
  final double x;
  final double y;

  FamilyTreeNode({
    required this.id,
    required this.personId,
    required this.x,
    required this.y,
  });

  factory FamilyTreeNode.fromMap(Map<String, dynamic> map) {
    return FamilyTreeNode(
      id: map['id'] ?? '',
      personId: map['personId'] ?? '',
      x: (map['x'] ?? 0).toDouble(),
      y: (map['y'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() =>
      {'id': id, 'personId': personId, 'x': x, 'y': y};
}

/// An edge connecting two nodes in the family tree.
class FamilyTreeEdge {
  final String from;
  final String to;
  final String relationType; // e.g. "parent", "spouse", "child"

  FamilyTreeEdge({
    required this.from,
    required this.to,
    required this.relationType,
  });

  factory FamilyTreeEdge.fromMap(Map<String, dynamic> map) {
    return FamilyTreeEdge(
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      relationType: map['relationType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() =>
      {'from': from, 'to': to, 'relationType': relationType};
}

/// Firestore model for `family_tree/{treeId}`.
class FamilyTreeModel {
  final String? id;
  final String title;
  final List<FamilyTreeNode> nodes;
  final List<FamilyTreeEdge> edges;
  final DateTime? updatedAt;
  final String? updatedBy;

  FamilyTreeModel({
    this.id,
    required this.title,
    this.nodes = const [],
    this.edges = const [],
    this.updatedAt,
    this.updatedBy,
  });

  factory FamilyTreeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyTreeModel(
      id: doc.id,
      title: data['title'] ?? '',
      nodes: (data['nodes'] as List<dynamic>?)
              ?.map((e) => FamilyTreeNode.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (data['edges'] as List<dynamic>?)
              ?.map((e) => FamilyTreeEdge.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: _parseTimestamp(data['updatedAt']),
      updatedBy: data['updatedBy'],
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'nodes': nodes.map((e) => e.toMap()).toList(),
      'edges': edges.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': updatedBy,
    };
  }

  FamilyTreeModel copyWith({
    String? id,
    String? title,
    List<FamilyTreeNode>? nodes,
    List<FamilyTreeEdge>? edges,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return FamilyTreeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
