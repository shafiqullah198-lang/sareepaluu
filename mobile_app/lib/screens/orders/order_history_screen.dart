import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/state_views.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});
  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<OrderProvider>().filterLocally(value);
    context.read<SearchProvider>().setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    return PremiumPage(
      title: 'Sales Records',
      subtitle: 'Order history, invoices, and stitching tracking.',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GlassTextField(
              controller: _searchController,
              icon: Icons.search,
              hint: 'Search by token, customer, status...',
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: provider.loading && provider.orders.isEmpty
                ? const LoadingView()
                : provider.error != null && provider.orders.isEmpty
                    ? ErrorView(
                        message: provider.error!,
                        onRetry: provider.load,
                      )
                    : provider.orders.isEmpty
                        ? EmptyView(
                            title: _searchController.text.isNotEmpty
                                ? 'No orders match "${_searchController.text}"'
                                : 'No orders found',
                          )
                        : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: provider.orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = provider.orders[index];
                          return _OrderCard(order: order);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final bool isPaid = order.paymentStatus.toLowerCase() == 'paid';
    return GlassCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPaid ? Colors.green.shade50 : AppColors.premiumPink.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.receipt_long_outlined,
                color: isPaid ? Colors.green.shade600 : AppColors.premiumGold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Token #${order.token}', style: Theme.of(context).textTheme.titleMedium),
                  Text(order.customerName ?? 'Walk-in customer', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${order.finalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.slate800)),
                Text(
                  order.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: isPaid ? Colors.green.shade600 : AppColors.premiumGold,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _OrderDetailModal(order: order),
    );
  }
}

class _OrderDetailModal extends StatelessWidget {
  const _OrderDetailModal({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final dateStr = order.date.isNotEmpty 
        ? DateFormat('MMM d, yyyy - h:mm a').format(DateTime.parse(order.date)) 
        : '';
        
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
                        Text('Order #${order.token}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 24)),
                        Text(dateStr, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate500)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CUSTOMER', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                        Text(order.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate700)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('STATUS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                        Text(order.paymentStatus.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.premiumGold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('INVOICE BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = order.items[i];
                    final variant = item['variant_detail'] ?? {};
                    final bool needsStitching = item['needs_stitching'] ?? false;
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${variant['color']} | ${variant['size']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate700)),
                              Text('Rs. ${item['price']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                            ],
                          ),
                          Text('Qty: ${item['quantity']}', style: const TextStyle(fontSize: 10, color: AppColors.slate500)),
                          if (needsStitching)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.content_cut, size: 12, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text('Stitching: ${item['stitching_status']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  ),
                                  Text('+ Rs. ${item['stitching_price']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.premiumGold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white54),
              const SizedBox(height: 8),
              _summaryRow('Subtotal', order.totalAmount),
              _summaryRow('Discount', order.discount, isDiscount: true),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('FINAL TOTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                  Text('Rs. ${order.finalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.premiumGold)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('Rs. ${order.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  if (order.invoiceUrl == null) return;
                  final url = Uri.parse(order.invoiceUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.print, size: 18, color: Colors.white),
                label: const Text('PRINT INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepMaroon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isDiscount = false}) {
    if (value == 0 && isDiscount) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate500)),
          Text('${isDiscount ? "-" : ""}Rs. ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDiscount ? Colors.red.shade400 : AppColors.slate700)),
        ],
      ),
    );
  }
}
