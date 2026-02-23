import 'package:flutter/material.dart';

import 'brands_screen.dart';
import 'categories_screen.dart';
import 'products_screen.dart';
import 'sub_categories_screen.dart';
import 'units_screen.dart';

class InventoryDashboardScreen extends StatefulWidget {
  const InventoryDashboardScreen({super.key});

  @override
  State<InventoryDashboardScreen> createState() =>
      _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selected = 0;
  final _search = TextEditingController();

  static const _dashboardIndex = 0;
  static const _productsIndex = 1;
  static const _categoriesIndex = 2;
  static const _subCategoriesIndex = 3;
  static const _brandsIndex = 4;
  static const _unitsIndex = 5;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_MenuEntry> get _menu => [
    _MenuEntry('Dashboard', Icons.dashboard_outlined, const _OverviewScreen()),
    _MenuEntry('Products', Icons.inventory_2_outlined, const ProductsScreen()),
    _MenuEntry('Category', Icons.category_outlined, const CategoriesScreen()),
    _MenuEntry(
      'Sub Category',
      Icons.table_rows_outlined,
      const SubCategoriesScreen(),
    ),
    _MenuEntry('Brands', Icons.storefront_outlined, const BrandsScreen()),
    _MenuEntry('Units', Icons.straighten_outlined, const UnitsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: Row(
          children: [
            if (mobile)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            Expanded(
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search',
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F8FA),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E3EA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E3EA)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(radius: 18, child: Icon(Icons.person_outline)),
            const SizedBox(width: 8),
          ],
        ),
      ),
      drawer: mobile ? Drawer(child: _buildMenuList(onSelect: _select)) : null,
      body: Row(
        children: [
          if (!mobile)
            Container(
              width: 280,
              color: Colors.white,
              child: _buildMenuList(onSelect: _select),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E3EA)),
                ),
                padding: const EdgeInsets.all(16),
                child: _menu[_selected].screen,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: mobile
          ? NavigationBar(
              selectedIndex: _selected > 3 ? 0 : _selected,
              onDestinationSelected: (index) {
                if (index == 0) {
                  _select(_dashboardIndex);
                } else if (index == 1) {
                  _select(_productsIndex);
                } else if (index == 2) {
                  _select(_categoriesIndex);
                } else {
                  _select(_brandsIndex);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.category_outlined),
                  label: 'Category',
                ),
                NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  label: 'Brands',
                ),
              ],
            )
          : null,
    );
  }

  void _select(int index) {
    setState(() => _selected = index);
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildMenuList({required ValueChanged<int> onSelect}) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Isovent Bau Inventory',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E2C5E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _menuTile(onSelect, _dashboardIndex),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            'Products',
            style: TextStyle(
              color: Color(0xFF6A717E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _menuTile(onSelect, _productsIndex),
        _menuTile(onSelect, _categoriesIndex, indent: true),
        _menuTile(onSelect, _subCategoriesIndex, indent: true),
        _menuTile(onSelect, _brandsIndex, indent: true),
        _menuTile(onSelect, _unitsIndex, indent: true),
      ],
    );
  }

  Widget _menuTile(
    ValueChanged<int> onSelect,
    int index, {
    bool indent = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: indent ? 12 : 0),
      child: ListTile(
        leading: Icon(_menu[index].icon),
        title: Text(_menu[index].title),
        dense: true,
        selected: index == _selected,
        selectedTileColor: const Color(0xFFFFF2E3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => onSelect(index),
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry(this.title, this.icon, this.screen);

  final String title;
  final IconData icon;
  final Widget screen;
}

class _OverviewScreen extends StatelessWidget {
  const _OverviewScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
