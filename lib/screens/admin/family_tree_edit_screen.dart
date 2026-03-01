import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/family_tree_model.dart';
import 'shared_admin_widgets.dart';

/// Create / Edit screen for a Family Tree.
class FamilyTreeEditScreen extends StatefulWidget {
  final FamilyTreeModel? familyTree;

  const FamilyTreeEditScreen({super.key, this.familyTree});

  @override
  State<FamilyTreeEditScreen> createState() => _FamilyTreeEditScreenState();
}

class _FamilyTreeEditScreenState extends State<FamilyTreeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;

  // Dynamic node & edge lists
  List<_NodeRow> _nodeRows = [];
  List<_EdgeRow> _edgeRows = [];

  bool get _isEditing => widget.familyTree != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.familyTree?.title ?? '');

    if (widget.familyTree != null) {
      _nodeRows = widget.familyTree!.nodes
          .map((n) => _NodeRow(
                idCtrl: TextEditingController(text: n.id),
                personIdCtrl: TextEditingController(text: n.personId),
                xCtrl: TextEditingController(text: '${n.x}'),
                yCtrl: TextEditingController(text: '${n.y}'),
              ))
          .toList();

      _edgeRows = widget.familyTree!.edges
          .map((e) => _EdgeRow(
                fromCtrl: TextEditingController(text: e.from),
                toCtrl: TextEditingController(text: e.to),
                relationCtrl: TextEditingController(text: e.relationType),
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final r in _nodeRows) {
      r.idCtrl.dispose();
      r.personIdCtrl.dispose();
      r.xCtrl.dispose();
      r.yCtrl.dispose();
    }
    for (final r in _edgeRows) {
      r.fromCtrl.dispose();
      r.toCtrl.dispose();
      r.relationCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;

    final nodes = _nodeRows
        .where((r) => r.idCtrl.text.trim().isNotEmpty)
        .map((r) => FamilyTreeNode(
              id: r.idCtrl.text.trim(),
              personId: r.personIdCtrl.text.trim(),
              x: double.tryParse(r.xCtrl.text.trim()) ?? 0,
              y: double.tryParse(r.yCtrl.text.trim()) ?? 0,
            ))
        .toList();

    final edges = _edgeRows
        .where((r) => r.fromCtrl.text.trim().isNotEmpty)
        .map((r) => FamilyTreeEdge(
              from: r.fromCtrl.text.trim(),
              to: r.toCtrl.text.trim(),
              relationType: r.relationCtrl.text.trim(),
            ))
        .toList();

    final model = FamilyTreeModel(
      id: widget.familyTree?.id,
      title: _titleCtrl.text.trim(),
      nodes: nodes,
      edges: edges,
      updatedBy: uid,
    );

    bool success;
    if (_isEditing) {
      success = await admin.updateFamilyTree(model);
    } else {
      success = await admin.createFamilyTree(model);
    }

    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed =
        await showDeleteConfirmDialog(context, itemName: _titleCtrl.text);
    if (!confirmed || !mounted) return;
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteFamilyTree(widget.familyTree!.id!);
    if (success && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Family Tree засах' : 'Family Tree нэмэх',
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    style: AppTheme.body.copyWith(color: AppTheme.textPrimary),
                    decoration: adminInputDecoration(label: 'Гарчиг *'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Гарчиг оруулна уу'
                        : null,
                  ),

                  // ── Nodes ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Nodes',
                          style: AppTheme.sectionTitle.copyWith(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppTheme.accentGold),
                        onPressed: () {
                          setState(() {
                            _nodeRows.add(_NodeRow(
                              idCtrl: TextEditingController(),
                              personIdCtrl: TextEditingController(),
                              xCtrl: TextEditingController(text: '0'),
                              yCtrl: TextEditingController(text: '0'),
                            ));
                          });
                        },
                      ),
                    ],
                  ),
                  ..._nodeRows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: r.idCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration:
                                  adminInputDecoration(label: 'Node ID'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextFormField(
                              controller: r.personIdCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration:
                                  adminInputDecoration(label: 'Person ID'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              controller: r.xCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration: adminInputDecoration(label: 'X'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              controller: r.yCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration: adminInputDecoration(label: 'Y'),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.crimson, size: 20),
                            onPressed: () =>
                                setState(() => _nodeRows.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),

                  // ── Edges ──
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Edges',
                          style: AppTheme.sectionTitle.copyWith(fontSize: 14)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: AppTheme.accentGold),
                        onPressed: () {
                          setState(() {
                            _edgeRows.add(_EdgeRow(
                              fromCtrl: TextEditingController(),
                              toCtrl: TextEditingController(),
                              relationCtrl: TextEditingController(),
                            ));
                          });
                        },
                      ),
                    ],
                  ),
                  ..._edgeRows.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: r.fromCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration: adminInputDecoration(label: 'From'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextFormField(
                              controller: r.toCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration: adminInputDecoration(label: 'To'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextFormField(
                              controller: r.relationCtrl,
                              style: AppTheme.body
                                  .copyWith(color: AppTheme.textPrimary),
                              decoration:
                                  adminInputDecoration(label: 'Relation'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.crimson, size: 20),
                            onPressed: () =>
                                setState(() => _edgeRows.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  AdminSaveButton(
                    onPressed: _save,
                    isLoading: admin.isLoading,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    AdminDeleteButton(onPressed: _delete),
                  ],
                  if (admin.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      admin.error!,
                      style: AppTheme.caption.copyWith(color: AppTheme.crimson),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NodeRow {
  final TextEditingController idCtrl;
  final TextEditingController personIdCtrl;
  final TextEditingController xCtrl;
  final TextEditingController yCtrl;
  _NodeRow({
    required this.idCtrl,
    required this.personIdCtrl,
    required this.xCtrl,
    required this.yCtrl,
  });
}

class _EdgeRow {
  final TextEditingController fromCtrl;
  final TextEditingController toCtrl;
  final TextEditingController relationCtrl;
  _EdgeRow({
    required this.fromCtrl,
    required this.toCtrl,
    required this.relationCtrl,
  });
}
