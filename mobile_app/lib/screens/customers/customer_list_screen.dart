import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/state_views.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CustomerProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<CustomerProvider>().filterLocally(value);
    context.read<SearchProvider>().setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    return PremiumPage(
      title: 'Customer Database',
      subtitle: 'Clients and purchase history.',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GlassTextField(
              controller: _searchController,
              icon: Icons.search,
              hint: 'Search by name or phone...',
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: provider.loading && provider.customers.isEmpty
                ? const LoadingView()
                : provider.error != null && provider.customers.isEmpty
                    ? ErrorView(
                        message: provider.error!,
                        onRetry: provider.load,
                      )
                    : provider.customers.isEmpty
                        ? EmptyView(
                            title: _searchController.text.isNotEmpty
                                ? 'No customers match "${_searchController.text}"'
                                : 'No customers found',
                          )
                        : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: provider.customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = provider.customers[index];
                          return _CustomerCard(customer: c);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showCustomerDetails(context, customer),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            CircleAvatar(
                backgroundColor: AppColors.premiumPink.withValues(alpha: 0.45),
                child: const Icon(Icons.person_outline, color: AppColors.premiumGold)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name ?? 'Walk-in customer', style: Theme.of(context).textTheme.titleMedium),
                  Text(customer.phone ?? 'No phone', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${customer.totalOrders} orders', style: const TextStyle(color: AppColors.premiumGold, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right, color: AppColors.slate400, size: 20),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (context) => _CustomerDetailModal(customer: customer),
    );
  }
}

class _CustomerDetailModal extends StatefulWidget {
  const _CustomerDetailModal({required this.customer});
  final Customer customer;

  @override
  State<_CustomerDetailModal> createState() => _CustomerDetailModalState();
}

class _CustomerDetailModalState extends State<_CustomerDetailModal> {
  Customer? detail;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final provider = context.read<CustomerProvider>();
    final data = await provider.getCustomerDetail(widget.customer.id);
    if (mounted) {
      setState(() {
        detail = data;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassCard(
        tint: AppColors.premiumPink,
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.customer.name ?? 'Customer Profile', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                        Text(widget.customer.phone ?? 'No phone', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              if (loading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (detail == null)
                const Center(child: Text('Failed to load details.'))
              else
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _statBox('Total Spent', 'Rs. ${detail!.totalSpent.toStringAsFixed(0)}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _statBox('Outstanding', 'Rs. ${(detail!.totalSpent - detail!.totalPaid).toStringAsFixed(0)}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('PURCHASE HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: detail!.purchaseHistory.isEmpty
                            ? const Center(child: Text('No orders found.'))
                            : ListView.builder(
                                itemCount: detail!.purchaseHistory.length,
                                itemBuilder: (context, i) {
                                  final order = detail!.purchaseHistory[i] as Map<String, dynamic>;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Order #${order['token_number']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700)),
                                            Text(order['payment_status'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.slate500)),
                                          ],
                                        ),
                                        Text('Rs. ${order['final_amount']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.premiumGold)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800)),
        ],
      ),
    );
  }
}
