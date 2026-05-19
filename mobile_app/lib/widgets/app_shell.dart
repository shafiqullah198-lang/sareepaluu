import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/theme/app_colors.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/tailoring/tailoring_center_screen.dart';
import '../screens/inventory/stock_levels_screen.dart';
import '../screens/dues/manage_dues_screen.dart';
import '../screens/expenses/expense_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/navigation_provider.dart';
import '../routes/app_routes.dart';
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

    final safeIndex = index.clamp(0, screens.length - 1).toInt();

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, safeIndex),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(color: Color(0xFFFFF9FB))),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(child: screens[safeIndex]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, safeIndex),
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
              icon:
                  const Icon(Icons.search_rounded, color: AppColors.deepMaroon),
              onPressed: () => GlobalSearchOverlay.show(context),
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppColors.deepMaroon),
                onPressed: () => _showNotifications(context),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAccountMenu(context),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.premiumGold,
              child: Text(_userInitials(context),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, int currentIndex) {
    final width = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: width < 380 ? width * 0.82 : 320,
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              children: [
                for (var i = 0; i < navItems.length; i++)
                  _DrawerNavTile(
                    item: navItems[i],
                    selected: currentIndex == i,
                    onTap: () {
                      context.read<NavigationProvider>().setIndex(i);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: _DrawerActionTile(
              icon: Icons.settings_outlined,
              label: 'Profile & Settings',
              onTap: () {
                Navigator.pop(context);
                _openProfile(context);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: _DrawerActionTile(
              icon: Icons.logout_rounded,
              label: 'Logout',
              danger: true,
              onTap: () => _confirmLogout(context),
            ),
          ),
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
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: _BrandLogo(imageUrl: _logoUrl),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Saree by Paalu',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.deepMaroon)),
                  Text('PREMIUM COLLECTION',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentRose,
                          letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('SHAFIQ ULLAH',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.slate800)),
          const SizedBox(height: 4),
          const Row(
            children: [
              _WhatsAppSvgIcon(size: 15),
              SizedBox(width: 6),
              Text('03480235167',
                  style: TextStyle(fontSize: 11, color: AppColors.slate500)),
            ],
          ),
        ],
      ),
    );
  }

  String _userName(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final fullName =
        '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
    return fullName.isNotEmpty
        ? fullName
        : (user?['username']?.toString() ?? 'User');
  }

  String _userInitials(BuildContext context) {
    final name = _userName(context).trim();
    if (name.isEmpty) return 'U';
    final parts =
        name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length < 2 ? name.length : 2).toUpperCase();
  }

  static String get _logoUrl {
    final base = AppConfig.apiBaseUrl.replaceFirst('/api/v1', '');
    return '$base/static/images/sbp_logo.png';
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.premiumGold,
                      child: Text(
                        _userInitials(context),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800,
                            ),
                          ),
                          const Text(
                            'Account options',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _AccountMenuTile(
                  icon: Icons.person_outline,
                  label: 'Open Profile',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openProfile(context);
                  },
                ),
                _AccountMenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  danger: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmLogout(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to end this session?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (shouldLogout != true || !context.mounted) return;
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _showNotifications(BuildContext context) async {
    final dashboard = context.read<DashboardProvider>();
    if (dashboard.summary.isEmpty && !dashboard.loading) {
      await dashboard.load();
    }
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final data = sheetContext.watch<DashboardProvider>();
        final items = [
          ...data.lowStockItems.map((item) => _NotificationItem(
                icon: Icons.warning_amber_rounded,
                title: 'Low stock',
                message:
                    '${item['product_name'] ?? item['product'] ?? 'Product'} ${item['color'] ?? ''} has ${item['stock'] ?? 0} left.',
                color: Colors.red,
              )),
          ...data.recentOrders.take(5).map((order) => _NotificationItem(
                icon: Icons.receipt_long_outlined,
                title: 'Recent order',
                message:
                    '#${order['token_number'] ?? '-'} - Rs. ${order['final_amount'] ?? order['amount'] ?? 0}',
                color: AppColors.premiumGold,
              )),
        ];

        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(8))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                        child: Text('Notifications',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slate800))),
                    IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              if (data.loading && items.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator())
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No notifications right now.',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => items[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _bottomNavItem(
                  0, Icons.dashboard_outlined, 'Dashboard', currentIndex),
              _bottomNavItem(
                  9, Icons.rotate_left, 'Order Override', currentIndex),
              _buildFab(context),
              _bottomNavItem(
                  6, Icons.receipt_long_outlined, 'Orders', currentIndex),
              _bottomNavItem(
                  8, Icons.attach_money_outlined, 'Expenses', currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(
      int index, IconData icon, String label, int currentIndex) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? AppColors.accentRose : AppColors.slate400,
              size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color:
                      isSelected ? AppColors.accentRose : AppColors.slate400)),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setIndex(1),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
            color: AppColors.deepMaroon, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFFFFF6FA),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text(
          'SBP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _WhatsAppSvgIcon extends StatelessWidget {
  const _WhatsAppSvgIcon({this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _WhatsAppSvgPainter(),
    );
  }
}

class _WhatsAppSvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = const Color(0xFF25D366)
      ..style = PaintingStyle.fill;
    final whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2, green);

    final tail = Path()
      ..moveTo(size.width * 0.22, size.height * 0.78)
      ..lineTo(size.width * 0.16, size.height * 0.96)
      ..lineTo(size.width * 0.36, size.height * 0.88)
      ..close();
    canvas.drawPath(tail, green);

    final handset = Path()
      ..moveTo(size.width * 0.36, size.height * 0.34)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.46,
        size.width * 0.43,
        size.height * 0.72,
        size.width * 0.66,
        size.height * 0.66,
      )
      ..lineTo(size.width * 0.72, size.height * 0.56);
    canvas.drawPath(handset, whiteStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DrawerNavTile extends StatelessWidget {
  const _DrawerNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.deepMaroon,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minLeadingWidth: 34,
        leading: Icon(item.icon,
            color: selected ? Colors.white : AppColors.slate600, size: 24),
        title: Text(
          item.label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.slate800,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade500 : AppColors.slate700;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      minLeadingWidth: 34,
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade500 : AppColors.deepMaroon;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate400),
      onTap: onTap,
    );
  }
}
