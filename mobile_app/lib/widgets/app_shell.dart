import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/tailoring/tailoring_center_screen.dart';
import '../screens/inventory/stock_levels_screen.dart';
import '../screens/dues/manage_dues_screen.dart';
import '../screens/expenses/expense_screen.dart';
import '../providers/navigation_provider.dart';
import 'global_search_overlay.dart';

class NavItem {
  final IconData icon;
  final String label;

  const NavItem({
    required this.icon,
    required this.label,
  });
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> screens = const [
    DashboardScreen(),
    PosScreen(),
    ProductListScreen(),
    TailoringCenterScreen(),
    StockLevelsScreen(),
    ManageDuesScreen(),
    OrderHistoryScreen(),
    CustomerListScreen(),
    ExpenseScreen(),
    OrderHistoryScreen(),
  ];

  final List<NavItem> navItems = const [
    NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    NavItem(icon: Icons.shopping_cart_outlined, label: 'POS System'),
    NavItem(icon: Icons.inventory_2_outlined, label: 'Products'),
    NavItem(icon: Icons.content_cut_outlined, label: 'Tailoring Center'),
    NavItem(icon: Icons.storage_outlined, label: 'Stock Levels'),
    NavItem(icon: Icons.account_balance_wallet_outlined, label: 'Manage Dues'),
    NavItem(icon: Icons.receipt_long_outlined, label: 'Sales Records'),
    NavItem(icon: Icons.people_outline, label: 'Customers'),
    NavItem(icon: Icons.attach_money_outlined, label: 'Expenses'),
    NavItem(icon: Icons.rotate_left, label: 'Order Override'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final index = nav.currentIndex;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, index),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(color: Color(0xFFFFF9FB))),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(child: screens[index]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, index),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.deepMaroon),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          // Global search entry point
          Tooltip(
            message: 'Global Search',
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.deepMaroon),
              onPressed: () => GlobalSearchOverlay.show(context),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.deepMaroon),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.premiumGold,
            child: Text('DS', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, int currentIndex) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              itemCount: navItems.length,
              itemBuilder: (context, i) {
                final item = navItems[i];
                final isSelected = currentIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.deepMaroon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(item.icon, color: isSelected ? Colors.white : AppColors.slate600),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.slate800,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      context.read<NavigationProvider>().setIndex(i);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: () {},
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Center(child: Text('SBP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saree by Paalu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.deepMaroon)),
                  Text('PREMIUM COLLECTION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.accentRose, letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('DEVI SHARMA (ADMIN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.slate800)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.green, size: 14),
              const SizedBox(width: 6),
              const Text('+91 98765 43210', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE7F0).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE7F0)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Upgrade to Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Unlock advanced features and grow your business.', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomNavItem(0, Icons.dashboard_outlined, 'Dashboard', currentIndex),
              _bottomNavItem(1, Icons.shopping_cart_outlined, 'POS System', currentIndex),
              _buildFab(context),
              _bottomNavItem(6, Icons.receipt_long_outlined, 'Orders', currentIndex),
              _bottomNavItem(9, Icons.grid_view_rounded, 'More', currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(int index, IconData icon, String label, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? AppColors.accentRose : AppColors.slate400, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.accentRose : AppColors.slate400)),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setIndex(1),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(color: AppColors.deepMaroon, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
