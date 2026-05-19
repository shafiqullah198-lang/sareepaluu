import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/state_views.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});
  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ExpenseProvider>().load();

      final dashboard = context.read<DashboardProvider>();
      if (dashboard.summary.isEmpty && !dashboard.loading) {
        dashboard.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final total = provider.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final revenue =
        (dashboard.summary['total_revenue'] as num?)?.toDouble() ?? 0.0;
    final netProfit = revenue - total;
    final expenseCount = provider.expenses.length;

    return PremiumPage(
      title: 'Expenses',
      subtitle: 'Manage operational costs and boutique overheads.',
      child: provider.loading
          ? const LoadingView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financial Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryStatCard(
                                label: 'Total Sales',
                                value: 'Rs. ${revenue.toStringAsFixed(0)}',
                                subtitle: 'Gross revenue',
                                icon: Icons.payments_outlined,
                                tint: const Color(0xFFDCFCE7),
                                iconColor: const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryStatCard(
                                label: 'Net Profit',
                                value: 'Rs. ${netProfit.toStringAsFixed(0)}',
                                subtitle: 'Sales minus expenses',
                                icon: Icons.trending_up_outlined,
                                tint: const Color(0xFFFCE7F3),
                                iconColor: AppColors.accentRose,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _CompactSummaryStrip(
                          totalExpenses: total,
                          expenseCount: expenseCount,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    tint: AppColors.premiumPink,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL EXPENSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
                        Text('Rs. ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: provider.expenses.isEmpty
                      ? const EmptyView(title: 'No expenses recorded')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          itemCount: provider.expenses.length,
                          itemBuilder: (context, i) {
                            final e = provider.expenses[i];
                            return GlassCard(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.premiumGold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_outlined, color: AppColors.premiumGold, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.category, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                                        Text(DateFormat('MMM dd, yyyy').format(e.date), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate400)),
                                      ],
                                    ),
                                  ),
                                  Text('Rs. ${e.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.slate800)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpense(context),
        backgroundColor: AppColors.premiumGold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ADD NEW EXPENSE', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GlassTextField(controller: categoryController, hint: 'Category (e.g. Rent, Bills)', icon: Icons.category_outlined),
              const SizedBox(height: 16),
              GlassTextField(controller: amountController, hint: 'Amount', icon: Icons.attach_money_outlined),
              const SizedBox(height: 16),
              GlassTextField(controller: noteController, hint: 'Optional Note', icon: Icons.edit_note),
              const SizedBox(height: 24),
              GlassButton(
                expanded: true,
                label: 'Save Expense',
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0 && categoryController.text.isNotEmpty) {
                    context.read<ExpenseProvider>().addExpense(amount, categoryController.text, noteController.text);
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

class _SummaryStatCard extends StatelessWidget {
  const _SummaryStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.slate400,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.slate800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryStrip extends StatelessWidget {
  const _CompactSummaryStrip({
    required this.totalExpenses,
    required this.expenseCount,
  });

  final double totalExpenses;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.premiumPink.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _stripValue(
              label: 'Total Expenses',
              value: 'Rs. ${totalExpenses.toStringAsFixed(0)}',
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.deepMaroon.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _stripValue(
              label: 'Records',
              value: expenseCount.toString(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stripValue({required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.slate500,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.deepMaroon,
          ),
        ),
      ],
    );
  }
}
