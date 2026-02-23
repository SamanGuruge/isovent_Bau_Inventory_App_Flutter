import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/inventory_repository.dart';
import 'widgets/inventory_list_page.dart';
import 'widgets/inventory_types.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _repo = InventoryRepository();
  final _searchController = TextEditingController();
  String _categoryFilter = 'All';
  String _statusFilter = 'All';
  int _reloadTick = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _reloadTick++);
    await _repo.seedProductsIfEmpty();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Product list refreshed.')));
  }

  Future<void> _showProductDialog({Map<String, dynamic>? existing}) async {
    final sku = TextEditingController(text: existing?['sku']?.toString() ?? '');
    final name = TextEditingController(
      text: existing?['name']?.toString() ?? '',
    );
    final category = TextEditingController(
      text: existing?['category']?.toString() ?? '',
    );
    final brand = TextEditingController(
      text: existing?['brand']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: (existing?['price'] ?? '').toString(),
    );
    final unit = TextEditingController(
      text: existing?['unit']?.toString() ?? '',
    );
    final qty = TextEditingController(
      text: (existing?['qty'] ?? '').toString(),
    );
    final createdBy = TextEditingController(
      text: existing?['createdBy']?.toString() ?? '',
    );
    String status = existing?['status']?.toString() ?? 'Active';
    final formKey = GlobalKey<FormState>();

    final submit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add Product' : 'Edit Product'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(sku, 'SKU', required: true),
                    _dialogField(name, 'Product Name', required: true),
                    _dialogField(category, 'Category', required: true),
                    _dialogField(brand, 'Brand', required: true),
                    _dialogField(
                      price,
                      'Price',
                      required: true,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    _dialogField(unit, 'Unit', required: true),
                    _dialogField(
                      qty,
                      'Quantity',
                      required: true,
                      keyboard: TextInputType.number,
                    ),
                    _dialogField(createdBy, 'Created By', required: true),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) => status = value ?? 'Active',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (submit == true) {
      await _repo.save('products', {
        'sku': sku.text.trim(),
        'name': name.text.trim(),
        'category': category.text.trim(),
        'brand': brand.text.trim(),
        'price': double.tryParse(price.text.trim()) ?? 0,
        'unit': unit.text.trim(),
        'qty': int.tryParse(qty.text.trim()) ?? 0,
        'createdBy': createdBy.text.trim(),
        'status': status,
      }, id: existing?['id']?.toString());
    }
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                  ? '$label is required'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Map<String, dynamic> row) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Delete "${row['name']?.toString() ?? 'this product'}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (approved == true) {
      await _repo.delete('products', row['id'].toString());
    }
  }

  List<Map<String, dynamic>> _filterRows(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final hay = row.values
            .map((e) => (e ?? '').toString().toLowerCase())
            .join(' ');
        if (!hay.contains(q)) {
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

  Future<void> _exportExcel(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      _toast('No products to export.');
      return;
    }
    setState(() => _busy = true);
    try {
      final csv = const ListToCsvConverter().convert([
        const [
          'sku',
          'name',
          'category',
          'brand',
          'price',
          'unit',
          'qty',
          'createdBy',
          'status',
        ],
        ...rows.map(
          (row) => [
            row['sku'] ?? '',
            row['name'] ?? '',
            row['category'] ?? '',
            row['brand'] ?? '',
            row['price'] ?? '',
            row['unit'] ?? '',
            row['qty'] ?? '',
            row['createdBy'] ?? '',
            row['status'] ?? 'Active',
          ],
        ),
      ]);
      await FileSaver.instance.saveFile(
        name: 'products_export',
        fileExtension: 'csv',
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: MimeType.csv,
      );
      _toast('Excel export complete (CSV format).');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _exportPdf(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      _toast('No products to export.');
      return;
    }
    setState(() => _busy = true);
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'Products Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              headers: const [
                'SKU',
                'Product',
                'Category',
                'Brand',
                'Price',
                'Unit',
                'Qty',
                'Status',
              ],
              data: rows
                  .map(
                    (row) => [
                      '${row['sku'] ?? ''}',
                      '${row['name'] ?? ''}',
                      '${row['category'] ?? ''}',
                      '${row['brand'] ?? ''}',
                      '${row['price'] ?? ''}',
                      '${row['unit'] ?? ''}',
                      '${row['qty'] ?? ''}',
                      '${row['status'] ?? 'Active'}',
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );
      await FileSaver.instance.saveFile(
        name: 'products_export',
        fileExtension: 'pdf',
        bytes: await doc.save(),
        mimeType: MimeType.pdf,
      );
      _toast('PDF export complete.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _importProductsCsv() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      _toast('Unable to read selected file.');
      return;
    }

    setState(() => _busy = true);
    try {
      final csvText = utf8.decode(bytes);
      final parsed = const CsvToListConverter().convert(csvText);
      if (parsed.length < 2) {
        _toast('CSV has no product rows.');
        return;
      }

      final headers = parsed.first
          .map((e) => e.toString().trim().toLowerCase())
          .toList();
      final rows = <Map<String, dynamic>>[];
      for (final row in parsed.skip(1)) {
        if (row.every((cell) => cell.toString().trim().isEmpty)) {
          continue;
        }
        final map = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < row.length; i++) {
          map[headers[i]] = row[i];
        }
        rows.add({
          'sku': map['sku']?.toString() ?? '',
          'name': map['name']?.toString() ?? '',
          'category': map['category']?.toString() ?? '',
          'brand': map['brand']?.toString() ?? '',
          'price': double.tryParse(map['price']?.toString() ?? '0') ?? 0,
          'unit': map['unit']?.toString() ?? 'Pc',
          'qty': int.tryParse(map['qty']?.toString() ?? '0') ?? 0,
          'qtyAlert': int.tryParse(map['qtyalert']?.toString() ?? '0') ?? 0,
          'createdBy': map['createdby']?.toString() ?? 'Imported User',
          'status': map['status']?.toString().toLowerCase() == 'inactive'
              ? 'Inactive'
              : 'Active',
        });
      }

      await _repo.saveManyProducts(rows);
      _toast('Imported ${rows.length} products.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _importSampleProducts() async {
    setState(() => _busy = true);
    try {
      await _repo.seedProductsIfEmpty();
      _toast('Sample products checked/loaded.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;
    return StreamBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_reloadTick),
      stream: _repo.streamCollection('products'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final err = snapshot.error;
          var message = 'Failed to load products.';
          if (err is PlatformException && err.code == 'permission-denied') {
            message = 'Firestore permission denied. Update Firestore rules.';
          } else if (err.toString().contains('permission-denied')) {
            message = 'Firestore permission denied. Update Firestore rules.';
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '$message\n\nDetails: $err',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final rows = snapshot.data ?? <Map<String, dynamic>>[];
        final filteredRows = _filterRows(rows);
        final categories = <String>{
          'All',
          ...rows
              .map((e) => e['category']?.toString() ?? '')
              .where((e) => e.isNotEmpty),
        }.toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionIcon(
                        icon: Icons.picture_as_pdf_outlined,
                        onTap: _busy ? null : () => _exportPdf(filteredRows),
                      ),
                      _actionIcon(
                        icon: Icons.table_chart_outlined,
                        onTap: _busy ? null : () => _exportExcel(filteredRows),
                      ),
                      _actionIcon(
                        icon: Icons.refresh,
                        onTap: _busy ? null : _onRefresh,
                      ),
                      ElevatedButton.icon(
                        onPressed: _busy ? null : () => _showProductDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8A03D),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Add Product'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _importProductsCsv,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF163560),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Import Product'),
                      ),
                      OutlinedButton(
                        onPressed: _busy ? null : _importSampleProducts,
                        child: const Text('Load Samples'),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Products',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _actionIcon(
                    icon: Icons.picture_as_pdf_outlined,
                    onTap: _busy ? null : () => _exportPdf(filteredRows),
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(
                    icon: Icons.table_chart_outlined,
                    onTap: _busy ? null : () => _exportExcel(filteredRows),
                  ),
                  const SizedBox(width: 8),
                  _actionIcon(
                    icon: Icons.refresh,
                    onTap: _busy ? null : _onRefresh,
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : () => _showProductDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF8A03D),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Product'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _importProductsCsv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF163560),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Import Product'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _busy ? null : _importSampleProducts,
                    child: const Text('Load Samples'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (mobile)
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(
                            category == 'All' ? 'Category' : category,
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value ?? 'All');
                    },
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
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
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      initialValue: _categoryFilter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final category in categories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(
                              category == 'All' ? 'Category' : category,
                            ),
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
            const SizedBox(height: 12),
            Expanded(
              child: filteredRows.isEmpty
                  ? const Center(child: Text('No Data Available'))
                  : mobile
                  ? _buildMobileList(filteredRows)
                  : _buildDesktopTable(filteredRows),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> rows) {
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
                        displayValue(row['name']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    _statusChip(row['status']?.toString() ?? 'Active'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('SKU: ${displayValue(row['sku'])}'),
                Text('Category: ${displayValue(row['category'])}'),
                Text('Brand: ${displayValue(row['brand'])}'),
                Text('Price: \$${displayValue(row['price'])}'),
                Text('Unit: ${displayValue(row['unit'])}'),
                Text('Qty: ${displayValue(row['qty'])}'),
                Text('Created By: ${displayValue(row['createdBy'])}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _showProductDialog(existing: row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteProduct(row),
                      icon: const Icon(Icons.delete_outline),
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

  Widget _buildDesktopTable(List<Map<String, dynamic>> rows) {
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('SKU')),
          DataColumn(label: Text('Product Name')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Brand')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Qty')),
          DataColumn(label: Text('Created By')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(Text(displayValue(row['sku']))),
                DataCell(Text(displayValue(row['name']))),
                DataCell(Text(displayValue(row['category']))),
                DataCell(Text(displayValue(row['brand']))),
                DataCell(Text('\$${displayValue(row['price'])}')),
                DataCell(Text(displayValue(row['unit']))),
                DataCell(Text(displayValue(row['qty']))),
                DataCell(Text(displayValue(row['createdBy']))),
                DataCell(_statusChip(row['status']?.toString() ?? 'Active')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _showProductDialog(existing: row),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () => _deleteProduct(row),
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

  Widget _actionIcon({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E3EA)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class VariantAttributesScreen extends StatelessWidget {
  const VariantAttributesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InventoryListPage(
      title: 'Variant Attributes',
      collection: 'variantAttributes',
      addLabel: 'Add Variant',
      formFields: ['name', 'values'],
      columns: [
        InventoryColumn('Variant', 'name'),
        InventoryColumn('Values', 'values'),
        InventoryColumn('Created Date', 'createdAt'),
      ],
    );
  }
}

class WarrantiesScreen extends StatelessWidget {
  const WarrantiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const InventoryListPage(
      title: 'Warranties',
      collection: 'warranties',
      addLabel: 'Add Warranty',
      formFields: ['name', 'description', 'duration'],
      columns: [
        InventoryColumn('Warranty', 'name'),
        InventoryColumn('Description', 'description'),
        InventoryColumn('Duration', 'duration'),
      ],
    );
  }
}

class ExpiredProductsScreen extends StatelessWidget {
  const ExpiredProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DerivedProductsPage(
      title: 'Expired Products',
      predicate: (row) {
        final expiry = row['expiryDate'];
        if (expiry == null) {
          return false;
        }
        try {
          final date = (expiry as dynamic).toDate() as DateTime;
          return date.isBefore(DateTime.now());
        } catch (_) {
          return false;
        }
      },
    );
  }
}

class LowStocksScreen extends StatefulWidget {
  const LowStocksScreen({super.key});

  @override
  State<LowStocksScreen> createState() => _LowStocksScreenState();
}

class _LowStocksScreenState extends State<LowStocksScreen> {
  bool _notify = true;

  @override
  Widget build(BuildContext context) {
    return _DerivedProductsPage(
      title: 'Low Stocks',
      headerExtra: [
        Row(
          children: [
            const Text('Notify'),
            Switch(
              value: _notify,
              onChanged: (v) => setState(() => _notify = v),
            ),
          ],
        ),
      ],
      predicate: (row) {
        final qty = (row['qty'] as num?)?.toInt() ?? 0;
        final alert = (row['qtyAlert'] as num?)?.toInt() ?? 0;
        return qty <= alert;
      },
    );
  }
}

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _repo = InventoryRepository();
  final _formKey = GlobalKey<FormState>();

  final _store = TextEditingController(text: 'Electro Mart');
  final _warehouse = TextEditingController(text: 'Lavish Warehouse');
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _category = TextEditingController();
  final _subCategory = TextEditingController();
  final _brand = TextEditingController();
  final _unit = TextEditingController(text: 'Pc');
  final _description = TextEditingController();
  final _qty = TextEditingController(text: '0');
  final _price = TextEditingController(text: '0');
  final _qtyAlert = TextEditingController(text: '0');
  final _createdBy = TextEditingController(text: 'Current User');
  final _expiryDate = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _store,
      _warehouse,
      _name,
      _sku,
      _category,
      _subCategory,
      _brand,
      _unit,
      _description,
      _qty,
      _price,
      _qtyAlert,
      _createdBy,
      _expiryDate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.save('products', {
        'store': _store.text.trim(),
        'warehouse': _warehouse.text.trim(),
        'name': _name.text.trim(),
        'sku': _sku.text.trim(),
        'category': _category.text.trim(),
        'subCategory': _subCategory.text.trim(),
        'brand': _brand.text.trim(),
        'unit': _unit.text.trim(),
        'description': _description.text.trim(),
        'qty': int.tryParse(_qty.text.trim()) ?? 0,
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'qtyAlert': int.tryParse(_qtyAlert.text.trim()) ?? 0,
        'createdBy': _createdBy.text.trim(),
        'status': 'Active',
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product created successfully.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_store, 'Store'),
              _field(_warehouse, 'Warehouse'),
              _field(_name, 'Product Name', required: true),
              _field(_sku, 'SKU', required: true),
              _field(_category, 'Category', required: true),
              _field(_subCategory, 'Sub Category', required: true),
              _field(_brand, 'Brand', required: true),
              _field(_unit, 'Unit', required: true),
              _field(_description, 'Description', lines: 3),
              _field(
                _qty,
                'Quantity',
                keyboard: TextInputType.number,
                required: true,
              ),
              _field(
                _price,
                'Price',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                required: true,
              ),
              _field(
                _qtyAlert,
                'Quantity Alert',
                keyboard: TextInputType.number,
              ),
              _field(_createdBy, 'Created By'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF8A03D),
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int lines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        minLines: lines,
        maxLines: lines,
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                  ? '$label is required'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class PrintBarcodeScreen extends StatefulWidget {
  const PrintBarcodeScreen({super.key});

  @override
  State<PrintBarcodeScreen> createState() => _PrintBarcodeScreenState();
}

class _PrintBarcodeScreenState extends State<PrintBarcodeScreen> {
  final _productSearch = TextEditingController();
  String _code = 'PT001';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Print Barcode',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _productSearch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search Product by Code',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _code = v.isEmpty ? 'PT001' : v),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E3EA)),
          ),
          child: Column(
            children: [
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: _code,
                width: 320,
                height: 120,
              ),
              const SizedBox(height: 12),
              Text(
                'Barcode: $_code',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8A03D),
                foregroundColor: Colors.white,
              ),
              label: const Text('Generate Barcode'),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _code = 'PT001'),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset Barcode'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Print command sent.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print),
              label: const Text('Print Barcode'),
            ),
          ],
        ),
      ],
    );
  }
}

class PrintQrCodeScreen extends StatefulWidget {
  const PrintQrCodeScreen({super.key});

  @override
  State<PrintQrCodeScreen> createState() => _PrintQrCodeScreenState();
}

class _PrintQrCodeScreenState extends State<PrintQrCodeScreen> {
  final _productSearch = TextEditingController();
  String _code = 'PT001';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Print QR Code',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _productSearch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search Product by Code',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _code = v.isEmpty ? 'PT001' : v),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E3EA)),
          ),
          child: Column(
            children: [
              QrImageView(
                data: _code,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                'QR Data: $_code',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.visibility_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF8A03D),
                foregroundColor: Colors.white,
              ),
              label: const Text('Generate QR Code'),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _code = 'PT001'),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset QR Code'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Print command sent.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print),
              label: const Text('Print QR Code'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DerivedProductsPage extends StatelessWidget {
  const _DerivedProductsPage({
    required this.title,
    required this.predicate,
    this.headerExtra,
  });

  final String title;
  final bool Function(Map<String, dynamic>) predicate;
  final List<Widget>? headerExtra;

  @override
  Widget build(BuildContext context) {
    final repo = InventoryRepository();
    final search = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (headerExtra != null) ...headerExtra!,
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: repo.streamCollection('products'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = snapshot.data!.where(predicate).where((row) {
                    final q = search.text.trim().toLowerCase();
                    if (q.isEmpty) {
                      return true;
                    }
                    return row.values
                        .map((e) => (e ?? '').toString().toLowerCase())
                        .join(' ')
                        .contains(q);
                  }).toList();

                  if (rows.isEmpty) {
                    return const Center(child: Text('No Data Available'));
                  }

                  final mobile = MediaQuery.sizeOf(context).width < 900;
                  if (mobile) {
                    return ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final row = rows[i];
                        return Card(
                          child: ListTile(
                            title: Text(row['name']?.toString() ?? '-'),
                            subtitle: Text(
                              'SKU: ${row['sku'] ?? '-'} | Qty: ${row['qty'] ?? 0} | Alert: ${row['qtyAlert'] ?? 0}',
                            ),
                            trailing: Text('${row['status'] ?? 'Active'}'),
                          ),
                        );
                      },
                    );
                  }

                  return SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('SKU')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Qty Alert')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: [
                        for (final row in rows)
                          DataRow(
                            cells: [
                              DataCell(Text(displayValue(row['sku']))),
                              DataCell(Text(displayValue(row['name']))),
                              DataCell(Text(displayValue(row['category']))),
                              DataCell(Text(displayValue(row['qty']))),
                              DataCell(Text(displayValue(row['qtyAlert']))),
                              DataCell(Text(displayValue(row['status']))),
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
      },
    );
  }
}
