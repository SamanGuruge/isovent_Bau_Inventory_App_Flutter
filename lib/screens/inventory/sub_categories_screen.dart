import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/inventory_repository.dart';
import '../../theme/app_ui.dart';
import 'widgets/inventory_types.dart';
import 'widgets/inventory_ui_kit.dart';

class SubCategoriesScreen extends StatefulWidget {
  const SubCategoriesScreen({super.key});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  final _repo = InventoryRepository();
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _categoryFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showSubCategoryDialog({
    required List<String> availableCategories,
    Map<String, dynamic>? existing,
  }) async {
    final name = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final code = TextEditingController(
      text: existing?['code']?.toString() ?? '',
    );
    final description = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );
    final image = TextEditingController(
      text: existing?['image']?.toString() ?? '',
    );
    String category =
        existing?['category']?.toString() ??
        (availableCategories.isNotEmpty ? availableCategories.first : '');
    String status = existing?['status']?.toString() ?? 'Active';
    final formKey = GlobalKey<FormState>();

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => InventoryDialogFrame(
        title: existing == null ? 'Add Sub Category' : 'Edit Sub Category',
        subtitle:
            'Configure category mapping, code, description, image and status.',
        maxWidth: 660,
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
              DropdownButtonFormField<String>(
                initialValue: category.isEmpty ? null : category,
                decoration: inventoryInputDecoration(label: 'Category *'),
                items: [
                  for (final c in availableCategories)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (value) => category = value ?? '',
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Category is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: code,
                decoration: inventoryInputDecoration(label: 'Code *'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Code is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                minLines: 2,
                maxLines: 3,
                decoration: inventoryInputDecoration(label: 'Description'),
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
      await _repo.save('subCategories', {
        'name': name.text.trim(),
        'category': category.trim(),
        'code': code.text.trim(),
        'description': description.text.trim(),
        'image': image.text.trim(),
        'status': status,
      }, id: existing?['id']?.toString());
    }
  }

  Future<void> _deleteSubCategory(Map<String, dynamic> row) async {
    final name = row['name']?.toString() ?? '';
    final code = row['code']?.toString() ?? '';
    final usedByName = name.isNotEmpty
        ? await _repo.existsWhere('products', field: 'subCategory', value: name)
        : false;
    final usedByCode = code.isNotEmpty
        ? await _repo.existsWhere(
            'products',
            field: 'subCategoryCode',
            value: code,
          )
        : false;
    if (usedByName || usedByCode) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sub category is used by products and cannot be deleted.',
          ),
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
        title: 'Delete Sub Category',
        subtitle: 'This action cannot be undone.',
        maxWidth: 500,
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
          'Delete "${row['name'] ?? 'this sub category'}"?',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ),
    );
    if (approved == true) {
      await _repo.delete('subCategories', row['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _repo.streamCollection('categories'),
      builder: (context, categorySnapshot) {
        if (!categorySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final availableCategories = categorySnapshot.data!
            .map((e) => e['name']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _repo.streamCollection('subCategories'),
          builder: (context, subCategorySnapshot) {
            if (!subCategorySnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = subCategorySnapshot.data!.where((row) {
              final q = _searchController.text.trim().toLowerCase();
              if (q.isNotEmpty) {
                final byName = (row['name']?.toString() ?? '').toLowerCase();
                final byCategory = (row['category']?.toString() ?? '')
                    .toLowerCase();
                if (!byName.contains(q) && !byCategory.contains(q)) {
                  return false;
                }
              }
              if (_statusFilter != 'All' &&
                  (row['status']?.toString() ?? 'Active') != _statusFilter) {
                return false;
              }
              if (_categoryFilter != 'All' &&
                  (row['category']?.toString() ?? '') != _categoryFilter) {
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
                        'Sub Category',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InventoryPrimaryButton(
                        label: 'Add Sub Category',
                        icon: Icons.add_circle_outline,
                        expand: true,
                        onPressed: () => _showSubCategoryDialog(
                          availableCategories: availableCategories,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Sub Category',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showSubCategoryDialog(
                          availableCategories: availableCategories,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8A03D),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Sub Category'),
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
                            hint: 'Search by Name / Category',
                            prefixIcon: const Icon(Icons.search, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryFilter,
                          isDense: true,
                          isExpanded: true,
                          decoration: inventoryCompactInputDecoration(),
                          items: [
                            const DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            for (final category in availableCategories)
                              DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() => _categoryFilter = value ?? 'All');
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _statusFilter,
                          isDense: true,
                          isExpanded: true,
                          decoration: inventoryCompactInputDecoration(),
                          items: const [
                            DropdownMenuItem(
                              value: 'All',
                              child: Text(
                                'All',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text(
                                'Active',
                                style: TextStyle(fontSize: 12),
                              ),
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
                            hintText: 'Search by Name or Category',
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
                          initialValue: _categoryFilter,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'All',
                              child: Text('All Category'),
                            ),
                            for (final category in availableCategories)
                              DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                          ],
                          onChanged: (value) {
                            setState(() => _categoryFilter = value ?? 'All');
                          },
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
                                        '${displayValue(row['name'])} • ${displayValue(row['category'])} • ${displayValue(row['code'])}',
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
                                      onPressed: () => _showSubCategoryDialog(
                                        availableCategories:
                                            availableCategories,
                                        existing: row,
                                      ),
                                    ),
                                    InventoryCompactIconButton(
                                      icon: Icons.delete_outline,
                                      tooltip: 'Delete',
                                      color: Colors.red.shade700,
                                      onPressed: () => _deleteSubCategory(row),
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
                              DataColumn(label: Text('Category')),
                              DataColumn(label: Text('Code')),
                              DataColumn(label: Text('Description')),
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
                                    DataCell(
                                      Text(displayValue(row['category'])),
                                    ),
                                    DataCell(Text(displayValue(row['code']))),
                                    DataCell(
                                      Text(displayValue(row['description'])),
                                    ),
                                    DataCell(Text(displayValue(row['image']))),
                                    DataCell(
                                      Text(displayValue(row['createdAt'])),
                                    ),
                                    DataCell(
                                      InventoryStatusChip(
                                        row['status']?.toString() ?? 'Active',
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () =>
                                                _showSubCategoryDialog(
                                                  availableCategories:
                                                      availableCategories,
                                                  existing: row,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () =>
                                                _deleteSubCategory(row),
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
      },
    );
  }
}
