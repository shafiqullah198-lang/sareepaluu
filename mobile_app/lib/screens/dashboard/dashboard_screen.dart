import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/state_views.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _chartLabel(dynamic value) {
    final label = value?.toString() ?? '';
    final end = label.length < 3 ? label.length : 3;
    return label.substring(0, end).toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DashboardProvider>();
    final s = data.summary;

    if (data.loading && s.isEmpty) return const LoadingView();

    if (data.error != null && s.isEmpty) {
      return ErrorView(
        message: data.error!,
        onRetry: data.load,
      );
    }
    return RefreshIndicator(
      color: AppColors.deepMaroon,
      onRefresh: data.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatGrid(s),
          const SizedBox(height: 24),
          _buildManagementHub(context),
          const SizedBox(height: 24),
          _buildWorkflowCard(data),
          const SizedBox(height: 24),
          _buildSalesAnalysis(data),
          const SizedBox(height: 24),
          _buildRecentTransactions(data),
          const SizedBox(height: 24),
          _buildLowStockAlerts(data),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome Back,', style: TextStyle(fontSize: 13, color: AppColors.slate500)),
        Row(children: [
          const Text('Saree by Paalu',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.deepMaroon)),
          const SizedBox(width: 6),
          const Text('👋', style: TextStyle(fontSize: 22)),
        ]),
        const Text("Here's what's happening in your boutique today.",
            style: TextStyle(fontSize: 11, color: AppColors.slate400)),
      ],
    );
  }

  // ── Stat Grid ────────────────────────────────────────────────────────────────
  Widget _buildStatGrid(Map<String, dynamic> s) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _StatCard(
          label: 'Total Sales',
          value: 'Rs. ${_fmt(s['total_revenue'])}',
          icon: Icons.payments_outlined,
          color: const Color(0xFFE91E63),
          subtitle: 'Life-time revenue',
        ),
        _StatCard(
          label: 'Total Orders',
          value: '${s['total_orders'] ?? 0}',
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFF2196F3),
          subtitle: 'Processed orders',
        ),
        _StatCard(
          label: 'Customers',
          value: '${s['total_customers'] ?? 0}',
          icon: Icons.people_outline,
          color: const Color(0xFF9C27B0),
          subtitle: 'Unique clients',
        ),
        _StatCard(
          label: 'Pending Stitching',
          value: '${s['pending_stitching'] ?? 0}',
          icon: Icons.content_cut_outlined,
          color: const Color(0xFFFF9800),
          subtitle: 'Orders in queue',
        ),
      ],
    );
  }

  // ── Management Hub ───────────────────────────────────────────────────────────
  Widget _buildManagementHub(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Management Hub',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _HubAction(icon: Icons.add_circle_outline, label: 'New Sale',
                  color: const Color(0xFFE91E63), bg: const Color(0xFFFCE4EC),
                  onTap: () => context.read<NavigationProvider>().setIndex(1)),
              _HubAction(icon: Icons.rotate_left, label: 'Order Override',
                  color: const Color(0xFF9C27B0), bg: const Color(0xFFF3E5F5),
                  onTap: () => context.read<NavigationProvider>().setIndex(9)),
              _HubAction(icon: Icons.storage_outlined, label: 'Inventory',
                  color: const Color(0xFF2196F3), bg: const Color(0xFFE3F2FD),
                  onTap: () => context.read<NavigationProvider>().setIndex(4)),
              _HubAction(icon: Icons.account_balance_wallet_outlined, label: 'Expense',
                  color: const Color(0xFFFF9800), bg: const Color(0xFFFFF3E0),
                  onTap: () => context.read<NavigationProvider>().setIndex(8)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stitching Workflow ───────────────────────────────────────────────────────
  Widget _buildWorkflowCard(DashboardProvider data) {
    final wf = data.workflow;
    final stages = [
      {'label': 'Pending', 'key': 'pending', 'icon': Icons.access_time_outlined, 'color': const Color(0xFF94A3B8)},
      {'label': 'Sent to Darzi', 'key': 'sent', 'icon': Icons.send_outlined, 'color': const Color(0xFF2196F3)},
      {'label': 'Stitching', 'key': 'stitching', 'icon': Icons.content_cut_outlined, 'color': const Color(0xFFFF9800)},
      {'label': 'Ready', 'key': 'ready', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF4CAF50)},
    ];

    return GestureDetector(
      onTap: () => context.read<NavigationProvider>().setIndex(3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Stitching Workflow',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.premiumGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ACTIVE QUEUE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900,
                        color: AppColors.premiumGold, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 16),
            ...stages.map((stage) {
              final count = wf[stage['key'] as String] ?? 0;
              final color = stage['color'] as Color;
              final icon = stage['icon'] as IconData;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(stage['label'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate700))),
                    Text(count.toString().padLeft(2, '0'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Sales Analysis ───────────────────────────────────────────────────────────
  Widget _buildSalesAnalysis(DashboardProvider data) {
    final chart = data.salesData['chart'] as List? ?? [];
    final maxSales = (data.salesData['max_sales'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Sales Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800)),
              const Text('Performance Insight',
                  style: TextStyle(fontSize: 10, color: AppColors.slate400)),
            ]),
            _PeriodSelector(value: data.period, onChanged: data.setPeriod),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _statBox('TOTAL PERIOD', 'Rs. ${_fmt(data.salesData['total_sales'])}')),
            const SizedBox(width: 12),
            Expanded(child: _statBox('AVG. SALE', 'Rs. ${_fmtDouble(data.salesData['average_sales'])}')),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: chart.isEmpty
                ? const Center(child: Text('No data', style: TextStyle(color: AppColors.slate400)))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: chart.map((c) {
                      final val = (c['total'] as num).toDouble();
                      final pct = maxSales > 0 ? (val / maxSales) : 0.0;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: FractionallySizedBox(
                                  heightFactor: pct > 0.05 ? pct : 0.05,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Color(0xFF4A0E26), Color(0xFFC3316D)],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _chartLabel(c['label']),
                                style: const TextStyle(fontSize: 8, color: AppColors.slate400, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCE4EC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.slate400)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.deepMaroon)),
      ]),
    );
  }

  // ── Recent Transactions ──────────────────────────────────────────────────────
  Widget _buildRecentTransactions(DashboardProvider data) {
    final orders = data.recentOrders;
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800)),
              TextButton(
                onPressed: () => context.read<NavigationProvider>().setIndex(6),
                child: const Row(children: [
                  Text('View All', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.slate500),
                ]),
              ),
            ]),
          ),
          const Divider(height: 1),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No recent orders', style: TextStyle(color: AppColors.slate400)),
            )
          else
            ...orders.map((order) => _buildOrderRow(order)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final status = order['payment_status'] as String? ?? 'Paid';
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Paid':
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        break;
      case 'Partial':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        break;
      default:
        statusColor = const Color(0xFFDC2626);
        statusBg = const Color(0xFFFEE2E2);
    }

    final initials = ((order['customer_name'] as String?) ?? 'WC')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.premiumPink,
          child: Text(initials, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepMaroon)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(order['token_number'] as String? ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate800)),
            Text(order['customer_name'] as String? ?? 'Walk-in',
                style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Rs. ${_fmt(order['final_amount'])}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate800)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
          ),
        ]),
      ]),
    );
  }

  // ── Low Stock Alerts ─────────────────────────────────────────────────────────
  Widget _buildLowStockAlerts(DashboardProvider data) {
    final items = data.lowStockItems;
    return Container(
      decoration: _cardDecoration(borderColor: const Color(0xFFFECACA)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Low Stock Alerts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
              const Spacer(),
              TextButton(
                onPressed: () => context.read<NavigationProvider>().setIndex(4),
                child: const Row(children: [
                  Text('View All', style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                  Icon(Icons.chevron_right, size: 16, color: AppColors.slate500),
                ]),
              ),
            ]),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 36),
                SizedBox(height: 8),
                Text('Stock levels are healthy',
                    style: TextStyle(color: AppColors.slate400, fontStyle: FontStyle.italic)),
              ]),
            )
          else
            ...items.map((item) => _buildStockRow(item)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStockRow(Map<String, dynamic> item) {
    final stock = item['stock'] as int? ?? 0;
    final isLow = stock <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFDE7F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: AppColors.deepMaroon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['product_name'] as String? ?? '',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate800),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${item['color']} • ${item['size']}',
                style: const TextStyle(fontSize: 10, color: AppColors.slate400, fontWeight: FontWeight.bold)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$stock LEFT',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold,
                  color: isLow ? const Color(0xFFDC2626) : const Color(0xFFD97706))),
        ),
      ]),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  BoxDecoration _cardDecoration({Color? borderColor}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: borderColor != null ? Border.all(color: borderColor.withValues(alpha: 0.5)) : null,
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
  );

  String _fmt(dynamic val) {
    if (val == null) return '0';
    final d = (val as num).toDouble();
    if (d >= 100000) return '${(d / 100000).toStringAsFixed(1)}L';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}K';
    return d.toStringAsFixed(0);
  }

  String _fmtDouble(dynamic val) {
    if (val == null) return '0';
    return (val as num).toStringAsFixed(0);
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label, required this.value, required this.icon,
    required this.color, required this.subtitle,
  });
  final String label, value, subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
          ]),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.slate800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 8, color: AppColors.slate400)),
        ],
      ),
    );
  }
}

// ── Hub Action ───────────────────────────────────────────────────────────────
class _HubAction extends StatelessWidget {
  const _HubAction({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});
  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate700)),
      ]),
    );
  }
}

// ── Period Selector ──────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final p in ['week', 'month', 'year'])
          GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: value == p ? AppColors.deepMaroon : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p[0].toUpperCase() + p.substring(1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: value == p ? Colors.white : AppColors.slate500,
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
