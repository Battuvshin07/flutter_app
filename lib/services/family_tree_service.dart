import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/person_model.dart';

/// A node in the family tree, wrapping a [PersonModel] with children.
class FamilyTreeNode {
  final PersonModel person;
  final List<FamilyTreeNode> children;

  FamilyTreeNode({required this.person, List<FamilyTreeNode>? children})
      : children = children ?? [];
}

/// Service to fetch persons from Firestore and build a family tree
/// hierarchy based on [fatherId] relationships.
class FamilyTreeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all persons from Firestore.
  Future<List<PersonModel>> fetchAllPersons() async {
    final snap = await _db
        .collection('persons')
        .orderBy('birthYear', descending: false)
        .get();
    return snap.docs.map((d) => PersonModel.fromFirestore(d)).toList();
  }

  /// Stream all persons from Firestore (real-time updates).
  Stream<List<PersonModel>> watchAllPersons() {
    return _db
        .collection('persons')
        .orderBy('birthYear', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PersonModel.fromFirestore(d)).toList());
  }

  /// Get children of a specific person by querying fatherId.
  Future<List<PersonModel>> getChildrenOf(String personId) async {
    final snap = await _db
        .collection('persons')
        .where('fatherId', isEqualTo: personId)
        .get();
    return snap.docs.map((d) => PersonModel.fromFirestore(d)).toList();
  }

  /// Build a list of root [FamilyTreeNode]s from a flat list of persons.
  /// Root persons are those with no fatherId (and no motherId).
  static List<FamilyTreeNode> buildTree(List<PersonModel> persons) {
    final Map<String, FamilyTreeNode> nodeMap = {};

    // Create a node for every person.
    for (final p in persons) {
      if (p.id == null) continue;
      nodeMap[p.id!] = FamilyTreeNode(person: p);
    }

    final roots = <FamilyTreeNode>[];

    // Link children to parents via fatherId.
    for (final node in nodeMap.values) {
      final fatherId = node.person.fatherId;
      if (fatherId != null && nodeMap.containsKey(fatherId)) {
        nodeMap[fatherId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }

    // Sort children by birthYear within each parent.
    for (final node in nodeMap.values) {
      node.children.sort((a, b) =>
          (a.person.birthYear ?? 0).compareTo(b.person.birthYear ?? 0));
    }

    return roots;
  }

  /// Find a single root ancestor and return the entire subtree.
  /// Useful when you know the root person's Firestore ID.
  static FamilyTreeNode? findSubtree(
      List<FamilyTreeNode> roots, String personId) {
    for (final root in roots) {
      final found = _findNode(root, personId);
      if (found != null) return found;
    }
    return null;
  }

  static FamilyTreeNode? _findNode(FamilyTreeNode node, String personId) {
    if (node.person.id == personId) return node;
    for (final child in node.children) {
      final found = _findNode(child, personId);
      if (found != null) return found;
    }
    return null;
  }
}
