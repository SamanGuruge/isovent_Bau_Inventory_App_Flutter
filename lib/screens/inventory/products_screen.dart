import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/inventory_repository.dart';
import '../../theme/app_ui.dart';
import 'widgets/inventory_types.dart';
import 'widgets/inventory_ui_kit.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = InventoryRepository();
  final _searchController = TextEditingController();
  late Future<_ProductFormOptions> _optionsFuture;

  String _categoryFilter = 'All';
  String _statusFilter = 'All';
  int _reloadTick = 0;
  bool _refreshing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _optionsFuture = _loadProductFormOptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _reloadTick++;
      _optionsFuture = _loadProductFormOptions();
    });
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product list refreshed.')));
  }

  String _generateSku() {
    final now = DateTime.now();
    final suffix = Random().nextInt(900) + 100;
    final y = now.year.toString().substring(2);
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final ms = (now.millisecond % 100).toString().padLeft(2, '0');
    return 'PRD-$y$m$d$ms-$suffix';
  }

  Future<_ProductFormOptions> _loadProductFormOptions() async {
    final results = await Future.wait([
      _repo.fetchCollection('categories'),
      _repo.fetchCollection('brands'),
      _repo.fetchCollection('units'),
    ]);

    List<String> namesFrom(List<Map<String, dynamic>> rows, String field) {
      return rows
          .map((e) => e[field]?.toString() ?? '')
          .where((e) => e.trim().isNotEmpty)
          .map((e) => e.trim())
          .toSet()
          .toList()
        ..sort();
    }

    return _ProductFormOptions(
      categories: namesFrom(results[0], 'name'),
      brands: namesFrom(results[1], 'name'),
      units: namesFrom(results[2], 'name'),
    );
  }

  Future<void> _showProductDialog({Map<String, dynamic>? existing}) async {
    final options = await _loadProductFormOptions();
    if (!mounted) return;

    final generatedSku = _generateSku();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final skuController = TextEditingController(
      text: existing?['sku']?.toString().trim().isNotEmpty == true
          ? existing!['sku'].toString()
          : generatedSku,
    );
    final priceController = TextEditingController(
      text: existing == null ? '' : (existing['price'] ?? '').toString(),
    );
    final qtyController = TextEditingController(
      text: existing == null ? '' : (existing['qty'] ?? '').toString(),
    );

    String? category = _resolveInitialOption(
      existing?['category']?.toString(),
      options.categories,
    );
    String? brand = _resolveInitialOption(
      existing?['brand']?.toString(),
      options.brands,
    );
    String? unit = _resolveInitialOption(
      existing?['unit']?.toString(),
      options.units,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final compact = MediaQuery.sizeOf(dialogContext).width < 700;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Widget buildDropdown({
              required String label,
              required List<String> items,
              required String? value,
              required ValueChanged<String?> onChanged,
            }) {
              return DropdownButtonFormField<String>(
                initialValue: value,
                decoration: inventoryInputDecoration(label: label),
                items: [
                  for (final item in items)
                    DropdownMenuItem(value: item, child: Text(item)),
                ],
                onChanged: onChanged,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? '$label is required'
                    : null,
              );
            }

            final fields = [
              TextFormField(
                controller: nameController,
                decoration: inventoryInputDecoration(
                  label: 'Product Name *',
                  hint: 'Enter product name',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Product Name is required'
                    : null,
              ),
              TextFormField(
                controller: skuController,
                readOnly: true,
                decoration: inventoryInputDecoration(
                  label: 'SKU *',
                  hint: 'Auto generated',
                  suffixIcon: IconButton(
                    tooltip: 'Regenerate SKU',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      setDialogState(() {
                        skuController.text = _generateSku();
                      });
                    },
                  ),
                ),
              ),
              buildDropdown(
                label: 'Category *',
                items: options.categories,
                value: category,
                onChanged: (v) => setDialogState(() => category = v),
              ),
              buildDropdown(
                label: 'Brand *',
                items: options.brands,
                value: brand,
                onChanged: (v) => setDialogState(() => brand = v),
              ),
              buildDropdown(
                label: 'Unit *',
                items: options.units,
                value: unit,
                onChanged: (v) => setDialogState(() => unit = v),
              ),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: inventoryInputDecoration(
                  label: 'Price *',
                  hint: '0.00',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price is required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: inventoryInputDecoration(
                  label: 'Quantity *',
                  hint: '0',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Quantity is required';
                  }
                  if (int.tryParse(v.trim()) == null) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
            ];

            final content = Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Product details',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (options.categories.isEmpty ||
                      options.brands.isEmpty ||
                      options.units.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5E8),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: const Color(0xFFFFD7A6)),
                      ),
                      child: const Text(
                        'Create Category, Brand and Unit records first to add a product.',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  if (compact)
                    ...fields.expand((w) => [w, const SizedBox(height: 12)])
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < fields.length; i++)
                          SizedBox(width: i == 0 ? 520 : 250, child: fields[i]),
                      ],
                    ),
                ],
              ),
            );

            return InventoryDialogFrame(
              actions: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                InventoryDialogPrimaryAction(
                  label: _saving ? 'Saving...' : 'Save Product',
                  onPressed:
                      _saving ||
                          options.categories.isEmpty ||
                          options.brands.isEmpty ||
                          options.units.isEmpty
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        },
                ),
              ],
              maxWidth: 700,
              subtitle:
                  'Create a product record with category, brand and unit mappings.',
              title: existing == null ? 'Add Product' : 'Edit Product',
              child: content,
            );
          },
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    final createdBy = (user?.displayName?.trim().isNotEmpty == true)
        ? user!.displayName!.trim()
        : (user?.email?.trim().isNotEmpty == true)
        ? user!.email!.trim()
        : user?.uid ?? 'Unknown User';

    setState(() => _saving = true);
    try {
      await _repo.save('products', {
        'sku': skuController.text.trim(),
        'name': nameController.text.trim(),
        'category': category ?? '',
        'brand': brand ?? '',
        'unit': unit ?? '',
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'qty': int.tryParse(qtyController.text.trim()) ?? 0,
        'createdBy':
            existing?['createdBy']?.toString().trim().isNotEmpty == true
            ? existing!['createdBy']
            : createdBy,
        'createdByUid': user?.uid ?? '',
        'status': existing?['status']?.toString() ?? 'Active',
      }, id: existing?['id']?.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Product added successfully.'
                : 'Product updated successfully.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> row) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => InventoryDialogFrame(
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Delete'),
          ),
        ],
        maxWidth: 460,
        subtitle: 'This action cannot be undone.',
        title: 'Delete Product',
        child: Text(
          'Delete "${row['name']?.toString() ?? 'this product'}"?',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        ),
      ),
    );
    if (approved == true) {
      await _repo.delete('products', row['id'].toString());
    }
  }

  Future<void> _toggleProductStatus(Map<String, dynamic> row) async {
    final current = row['status']?.toString() ?? 'Active';
    final nextActive = current != 'Active';
    await _repo.toggleStatus('products', row['id'].toString(), nextActive);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Product marked as ${nextActive ? 'Active' : 'Inactive'}.',
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterRows(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final name = (row['name']?.toString() ?? '').toLowerCase();
        final sku = (row['sku']?.toString() ?? '').toLowerCase();
        if (!name.contains(q) && !sku.contains(q)) {
          return false;
        }
      }
      if (_categoryFilter != 'All' &&
          (row['category']?.toString() ?? '') != _categoryFilter) {
        return false;
      }
      if (_statusFilter != 'All' &&
          (row['status']?.toString() ?? 'Active') != _statusFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 980;
    return FutureBuilder<_ProductFormOptions>(
      future: _optionsFuture,
      builder: (context, optionsSnapshot) {
        final options =
            optionsSnapshot.data ??
            const _ProductFormOptions(categories: [], brands: [], units: []);
        return StreamBuilder<List<Map<String, dynamic>>>(
          key: ValueKey(_reloadTick),
          stream: _repo.streamCollection('products'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load products. Please sign in again.',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allRows = snapshot.data!;
            final rows = _filterRows(allRows);
            final categories = <String>{
              ...options.categories,
              ...allRows
                  .map((e) => e['category']?.toString() ?? '')
                  .where((e) => e.trim().isNotEmpty),
            }.toList()..sort();
            final activeCount = allRows
                .where((e) => (e['status']?.toString() ?? 'Active') == 'Active')
                .length;
            final inactiveCount = allRows.length - activeCount;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: IconButton(
                              tooltip: 'Refresh',
                              visualDensity: VisualDensity.compact,
                              iconSize: 18,
                              onPressed: _refreshing ? null : _refreshProducts,
                              icon: _refreshing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () => _showProductDialog(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                minimumSize: const Size(0, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                              ),
                              label: const Text(
                                'Add Product',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Products',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage inventory products with category, brand and unit mappings.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      InventoryGhostButton(
                        label: _refreshing ? 'Refreshing...' : 'Refresh',
                        icon: Icons.refresh_rounded,
                        onPressed: _refreshing ? null : _refreshProducts,
                      ),
                      const SizedBox(width: 10),
                      InventoryPrimaryButton(
                        label: 'Add Product',
                        icon: Icons.add_circle_outline,
                        onPressed: _saving ? null : () => _showProductDialog(),
                      ),
                    ],
                  ),
                SizedBox(height: mobile ? 8 : 14),
                if (mobile)
                  Column(
                    children: [
                      _mobileSummaryStrip(
                        total: allRows.length,
                        active: activeCount,
                        inactive: inactiveCount,
                      ),
                      const SizedBox(height: 8),
                      InventorySurfaceCard(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              decoration:
                                  inventoryInputDecoration(
                                    label: 'Search',
                                    hint: 'Name or SKU',
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              size: 16,
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {});
                                            },
                                          ),
                                  ).copyWith(
                                    isDense: true,
                                    labelText: null,
                                    hintStyle: const TextStyle(fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      size: 18,
                                    ),
                                  ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _categoryFilter,
                                    isExpanded: true,
                                    isDense: true,
                                    decoration:
                                        inventoryInputDecoration(
                                          label: 'Category',
                                        ).copyWith(
                                          labelText: null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 10,
                                              ),
                                        ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
                                    items: [
                                      const DropdownMenuItem(
                                        value: 'All',
                                        child: Text(
                                          'All',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      for (final category in categories)
                                        DropdownMenuItem(
                                          value: category,
                                          child: Text(
                                            category,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                    onChanged: (value) => setState(
                                      () => _categoryFilter = value ?? 'All',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _statusFilter,
                                    isExpanded: true,
                                    isDense: true,
                                    decoration:
                                        inventoryInputDecoration(
                                          label: 'Status',
                                        ).copyWith(
                                          labelText: null,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 10,
                                              ),
                                        ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                    ),
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
                                    onChanged: (value) => setState(
                                      () => _statusFilter = value ?? 'All',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          total: allRows.length,
                          active: activeCount,
                          inactive: inactiveCount,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: InventorySurfaceCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration:
                                      inventoryInputDecoration(
                                        label: 'Search',
                                        hint: 'Product name or SKU',
                                      ).copyWith(
                                        prefixIcon: const Icon(Icons.search),
                                        labelText: null,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _categoryFilter,
                                  decoration: inventoryInputDecoration(
                                    label: 'Category',
                                  ).copyWith(labelText: null),
                                  items: [
                                    const DropdownMenuItem(
                                      value: 'All',
                                      child: Text('All Categories'),
                                    ),
                                    for (final category in categories)
                                      DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _categoryFilter = value ?? 'All',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 160,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _statusFilter,
                                  decoration: inventoryInputDecoration(
                                    label: 'Status',
                                  ).copyWith(labelText: null),
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
                                  onChanged: (value) => setState(
                                    () => _statusFilter = value ?? 'All',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: mobile ? 8 : 14),
                Expanded(
                  child: InventorySurfaceCard(
                    padding: const EdgeInsets.all(0),
                    child: rows.isEmpty
                        ? _ProductEmptyState(
                            hasAnyProducts: allRows.isNotEmpty,
                            onAdd: () => _showProductDialog(),
                          )
                        : mobile
                        ? ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              return _ProductMobileCard(
                                row: row,
                                onEdit: () => _showProductDialog(existing: row),
                                onToggleStatus: () => _toggleProductStatus(row),
                                onDelete: () => _deleteProduct(row),
                              );
                            },
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.sizeOf(context).width - 380,
                              ),
                              child: DataTable(
                                columnSpacing: 22,
                                headingRowColor: WidgetStateProperty.all(
                                  AppColors.panelBg,
                                ),
                                columns: const [
                                  DataColumn(label: Text('SKU')),
                                  DataColumn(label: Text('Product Name')),
                                  DataColumn(label: Text('Category')),
                                  DataColumn(label: Text('Brand')),
                                  DataColumn(label: Text('Price')),
                                  DataColumn(label: Text('Unit')),
                                  DataColumn(label: Text('Qty')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: [
                                  for (final row in rows)
                                    DataRow(
                                      cells: [
                                        DataCell(
                                          Text(displayValue(row['sku'])),
                                        ),
                                        DataCell(
                                          Text(displayValue(row['name'])),
                                        ),
                                        DataCell(
                                          Text(displayValue(row['category'])),
                                        ),
                                        DataCell(
                                          Text(displayValue(row['brand'])),
                                        ),
                                        DataCell(
                                          Text(_priceText(row['price'])),
                                        ),
                                        DataCell(
                                          Text(displayValue(row['unit'])),
                                        ),
                                        DataCell(
                                          Text(displayValue(row['qty'])),
                                        ),
                                        DataCell(
                                          _statusChip(
                                            row['status']?.toString() ??
                                                'Active',
                                          ),
                                        ),
                                        DataCell(
                                          Wrap(
                                            spacing: 4,
                                            children: [
                                              IconButton(
                                                tooltip: 'Edit',
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                onPressed: () =>
                                                    _showProductDialog(
                                                      existing: row,
                                                    ),
                                              ),
                                              IconButton(
                                                tooltip:
                                                    (row['status']
                                                                ?.toString() ??
                                                            'Active') ==
                                                        'Active'
                                                    ? 'Set Inactive'
                                                    : 'Set Active',
                                                icon: Icon(
                                                  (row['status']?.toString() ??
                                                              'Active') ==
                                                          'Active'
                                                      ? Icons.toggle_on_rounded
                                                      : Icons
                                                            .toggle_off_outlined,
                                                  color:
                                                      (row['status']
                                                                  ?.toString() ??
                                                              'Active') ==
                                                          'Active'
                                                      ? AppColors.success
                                                      : AppColors.inactive,
                                                ),
                                                onPressed: () =>
                                                    _toggleProductStatus(row),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                onPressed: () =>
                                                    _deleteProduct(row),
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _summaryCard({
    required int total,
    required int active,
    required int inactive,
  }) {
    Widget tile(String label, String value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InventorySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          tile('Total', '$total', AppColors.navy),
          const SizedBox(width: 8),
          tile('Active', '$active', AppColors.success),
          const SizedBox(width: 8),
          tile('Inactive', '$inactive', AppColors.inactive),
        ],
      ),
    );
  }

  Widget _mobileSummaryStrip({
    required int total,
    required int active,
    required int inactive,
  }) {
    Widget pill(String label, String value, Color bg, Color fg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: fg.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return InventorySurfaceCard(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          pill('Total', '$total', const Color(0xFFEFF3FF), AppColors.navy),
          pill('Active', '$active', const Color(0xFFEAF9F0), AppColors.success),
          pill(
            'Inactive',
            '$inactive',
            const Color(0xFFF0F0F0),
            AppColors.inactive,
          ),
        ],
      ),
    );
  }

  String _priceText(dynamic value) {
    if (value is num) return '\$${value.toStringAsFixed(2)}';
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) return displayValue(value);
    return '\$${parsed.toStringAsFixed(2)}';
  }

  Widget _statusChip(String status) {
    final active = status == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.success : AppColors.inactive,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String? _resolveInitialOption(String? current, List<String> options) {
    final value = current?.trim();
    if (value == null || value.isEmpty) {
      return options.isNotEmpty ? options.first : null;
    }
    if (options.contains(value)) {
      return value;
    }
    return options.isNotEmpty ? options.first : null;
  }
}

class _ProductFormOptions {
  const _ProductFormOptions({
    required this.categories,
    required this.brands,
    required this.units,
  });

  final List<String> categories;
  final List<String> brands;
  final List<String> units;
}

class _ProductMobileCard extends StatelessWidget {
  const _ProductMobileCard({
    required this.row,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final Map<String, dynamic> row;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = row['status']?.toString() ?? 'Active';
    final active = status == 'Active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSoft),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? AppColors.success : AppColors.inactive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${displayValue(row['name'])} • ${displayValue(row['sku'])} • ${displayValue(row['category'])} • ${_formatPrice(row['price'])} • Q:${displayValue(row['qty'])}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.2,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            iconSize: 16,
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: onToggleStatus,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            iconSize: 18,
            tooltip: active ? 'Set Inactive' : 'Set Active',
            icon: Icon(
              active ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
            ),
            color: active ? AppColors.success : AppColors.inactive,
          ),
          IconButton(
            onPressed: onDelete,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            iconSize: 16,
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            color: Colors.red.shade700,
          ),
        ],
      ),
    );
  }

  String _formatPrice(dynamic value) {
    if (value is num) return '\$${value.toStringAsFixed(2)}';
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) return displayValue(value);
    return '\$${parsed.toStringAsFixed(2)}';
  }
}

class _ProductEmptyState extends StatelessWidget {
  const _ProductEmptyState({required this.hasAnyProducts, required this.onAdd});

  final bool hasAnyProducts;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5E8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.accent,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasAnyProducts
                  ? 'No products match your filters'
                  : 'No products added yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasAnyProducts
                  ? 'Try changing search text or filters.'
                  : 'Start by adding your first product record.',
              style: const TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            InventoryPrimaryButton(
              label: 'Add Product',
              icon: Icons.add_circle_outline,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
