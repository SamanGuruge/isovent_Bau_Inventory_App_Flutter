import 'package:flutter/material.dart';

import '../../../services/inventory_repository.dart';
import 'inventory_types.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({
    super.key,
    required this.title,
    required this.collection,
    required this.columns,
    required this.addLabel,
    required this.formFields,
    this.extraActions,
    this.defaultValues,
    this.onBuildData,
  });

  final String title;
  final String collection;
  final List<InventoryColumn> columns;
  final String addLabel;
  final List<String> formFields;
  final List<Widget>? extraActions;
  final Map<String, dynamic>? defaultValues;
  final Map<String, dynamic> Function(Map<String, dynamic>)? onBuildData;

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _repo = InventoryRepository();
  final _search = TextEditingController();
  String _status = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _saveDialog({Map<String, dynamic>? existing}) async {
    final map = <String, TextEditingController>{
      for (final field in widget.formFields)
        field: TextEditingController(text: existing?[field]?.toString() ?? ''),
    };
    String status = (existing?['status']?.toString() ?? 'Active');

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existing == null ? widget.addLabel : 'Edit ${widget.title}',
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in widget.formFields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: map[field],
                        decoration: InputDecoration(
                          labelText: _label(field),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => status = value ?? 'Active',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (submit != true) {
      for (final c in map.values) {
        c.dispose();
      }
      return;
    }

    final data = <String, dynamic>{
      ...?widget.defaultValues,
      for (final f in widget.formFields) f: map[f]!.text.trim(),
      'status': status,
    };

    final payload = widget.onBuildData?.call(data) ?? data;
    await _repo.save(
      widget.collection,
      payload,
      id: existing?['id']?.toString(),
    );

    for (final c in map.values) {
      c.dispose();
    }
  }

  String _label(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _saveDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8A03D),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(widget.addLabel),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Status')),
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (v) {
                  setState(() => _status = v ?? 'All');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.extraActions != null) ...[
          Wrap(spacing: 8, runSpacing: 8, children: widget.extraActions!),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _repo.streamCollection(widget.collection),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final rows = (snapshot.data ?? []).where((row) {
                final q = _search.text.trim().toLowerCase();
                if (q.isNotEmpty) {
                  final hay = row.values
                      .map((e) => (e ?? '').toString().toLowerCase())
                      .join(' ');
                  if (!hay.contains(q)) {
                    return false;
                  }
                }
                if (_status != 'All' &&
                    (row['status']?.toString() ?? 'Active') != _status) {
                  return false;
                }
                return true;
              }).toList();

              if (rows.isEmpty) {
                return const Center(child: Text('No Data Available'));
              }

              if (mobile) {
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    displayValue(row[widget.columns.first.key]),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                _statusChip(
                                  row['status']?.toString() ?? 'Active',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final col in widget.columns.skip(1))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '${col.label}: ${displayValue(row[col.key])}',
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _saveDialog(existing: row),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _repo.delete(
                                    widget.collection,
                                    row['id'].toString(),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                const Spacer(),
                                Switch(
                                  value:
                                      (row['status']?.toString() ?? 'Active') ==
                                      'Active',
                                  onChanged: (value) => _repo.toggleStatus(
                                    widget.collection,
                                    row['id'].toString(),
                                    value,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              return SingleChildScrollView(
                child: DataTable(
                  columns: [
                    for (final col in widget.columns)
                      DataColumn(label: Text(col.label)),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final row in rows)
                      DataRow(
                        cells: [
                          for (final col in widget.columns)
                            DataCell(Text(displayValue(row[col.key]))),
                          DataCell(
                            _statusChip(row['status']?.toString() ?? 'Active'),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _saveDialog(existing: row),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _repo.delete(
                                    widget.collection,
                                    row['id'].toString(),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF35B36C) : const Color(0xFF999999),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
