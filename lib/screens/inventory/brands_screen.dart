import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/inventory_repository.dart';
import '../../theme/app_ui.dart';
import 'widgets/inventory_types.dart';
import 'widgets/inventory_ui_kit.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  final _repo = InventoryRepository();
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showBrandDialog({Map<String, dynamic>? existing}) async {
    final name = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final image = TextEditingController(
      text: existing?['image']?.toString() ?? '',
    );
    String status = existing?['status']?.toString() ?? 'Active';
    final formKey = GlobalKey<FormState>();

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => InventoryDialogFrame(
        title: existing == null ? 'Add Brand' : 'Edit Brand',
        subtitle: 'Maintain brand name, image and status.',
        maxWidth: 560,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          InventoryDialogPrimaryAction(
            label: 'Save',
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
          ),
        ],
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: inventoryInputDecoration(label: 'Name *'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: image,
                readOnly: true,
                decoration: inventoryInputDecoration(
                  label: 'Image',
                  suffixIcon: IconButton(
                    tooltip: 'Pick Image',
                    icon: const Icon(Icons.image_outlined),
                    onPressed: () async {
                      final picked = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );
                      if (picked == null || picked.files.isEmpty) {
                        return;
                      }
                      image.text = picked.files.first.name;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: inventoryInputDecoration(label: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                ],
                onChanged: (value) => status = value ?? 'Active',
              ),
            ],
          ),
        ),
      ),
    );

    if (submit == true) {
      await _repo.save('brands', {
        'name': name.text.trim(),
        'image': image.text.trim(),
        'status': status,
      }, id: existing?['id']?.toString());
    }
  }

  Future<void> _deleteBrand(Map<String, dynamic> row) async {
    final name = row['name']?.toString() ?? '';
    final used = name.isNotEmpty
        ? await _repo.existsWhere('products', field: 'brand', value: name)
        : false;
    if (used) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brand is used by products and cannot be deleted.'),
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => InventoryDialogFrame(
        title: 'Delete Brand',
        subtitle: 'This action cannot be undone.',
        maxWidth: 440,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          InventoryDialogDangerAction(
            label: 'Delete',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
        child: Text(
          'Delete "${row['name'] ?? 'this brand'}"?',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ),
    );
    if (approved == true) {
      await _repo.delete('brands', row['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.streamCollection('brands'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!.where((row) {
          final q = _searchController.text.trim().toLowerCase();
          if (q.isNotEmpty) {
            final byName = (row['name']?.toString() ?? '').toLowerCase();
            if (!byName.contains(q)) {
              return false;
            }
          }
          if (_statusFilter != 'All' &&
              (row['status']?.toString() ?? 'Active') != _statusFilter) {
            return false;
          }
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Brands',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InventoryPrimaryButton(
                    label: 'Add Brand',
                    icon: Icons.add_circle_outline,
                    expand: true,
                    onPressed: () => _showBrandDialog(),
                  ),
                ],
              )
            else
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Brands',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showBrandDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8A03D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Brand'),
                  ),
                ],
              ),
            SizedBox(height: mobile ? 8 : 12),
            if (mobile)
              InventorySurfaceCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: inventoryCompactInputDecoration(
                        hint: 'Search by Name',
                        prefixIcon: const Icon(Icons.search, size: 18),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      isDense: true,
                      decoration: inventoryCompactInputDecoration(),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text(
                            'Inactive',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _statusFilter = value ?? 'All');
                      },
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by Name',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      initialValue: _statusFilter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _statusFilter = value ?? 'All');
                      },
                    ),
                  ),
                ],
              ),
            SizedBox(height: mobile ? 8 : 12),
            Expanded(
              child: rows.isEmpty
                  ? const Center(child: Text('No Data Available'))
                  : mobile
                  ? ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: InventorySurfaceCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${displayValue(row['name'])} • ${displayValue(row['image'])}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InventoryStatusChip(
                                  row['status']?.toString() ?? 'Active',
                                  compact: true,
                                ),
                                const SizedBox(width: 4),
                                InventoryCompactIconButton(
                                  icon: Icons.edit_outlined,
                                  tooltip: 'Edit',
                                  onPressed: () =>
                                      _showBrandDialog(existing: row),
                                ),
                                InventoryCompactIconButton(
                                  icon: Icons.delete_outline,
                                  tooltip: 'Delete',
                                  color: Colors.red.shade700,
                                  onPressed: () => _deleteBrand(row),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Image')),
                          DataColumn(label: Text('Created Date')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final row in rows)
                            DataRow(
                              cells: [
                                DataCell(Text(displayValue(row['name']))),
                                DataCell(Text(displayValue(row['image']))),
                                DataCell(Text(displayValue(row['createdAt']))),
                                DataCell(
                                  InventoryStatusChip(
                                    row['status']?.toString() ?? 'Active',
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () =>
                                            _showBrandDialog(existing: row),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _deleteBrand(row),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
