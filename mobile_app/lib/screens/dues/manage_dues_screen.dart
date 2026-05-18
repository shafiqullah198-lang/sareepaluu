import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../providers/order_provider.dart';
import '../../widgets/state_views.dart';

class ManageDuesScreen extends StatefulWidget {
  const ManageDuesScreen({super.key});
  @override
  State<ManageDuesScreen> createState() => _ManageDuesScreenState();
}

class _ManageDuesScreenState extends State<ManageDuesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final dues = provider.orders.where((o) => o.paymentStatus != 'Paid').toList();

    return PremiumPage(
      title: 'Manage Dues',
      subtitle: 'Track and collect outstanding customer balances.',
      child: provider.loading && dues.isEmpty
          ? const LoadingView()
          : provider.error != null && dues.isEmpty
              ? ErrorView(
                  message: provider.error!,
                  onRetry: provider.load,
                )
              : dues.isEmpty
                  ? const EmptyView(title: 'No outstanding dues')
                  : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: dues.length,
                  itemBuilder: (context, i) {
                    final order = dues[i];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(order.token, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.premiumGold)),
                                  Text(order.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('Rs. ${order.balanceDue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ],
                          ),
                          const Divider(height: 32, color: Colors.white38),
                          GlassButton(
                            expanded: true,
                            label: 'Collect Payment',
                            onPressed: () => _showPaymentDialog(context, order.id, order.balanceDue),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  void _showPaymentDialog(BuildContext context, int orderId, double balance) {
    final controller = TextEditingController(text: balance.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('COLLECT PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GlassTextField(
                controller: controller,
                hint: 'Amount to pay',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 24),
              GlassButton(
                expanded: true,
                label: 'Confirm Payment',
                onPressed: () {
                  final amount = double.tryParse(controller.text) ?? 0;
                  if (amount > 0) {
                    context.read<OrderProvider>().addPayment(orderId, amount);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
