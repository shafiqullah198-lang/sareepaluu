import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/state_views.dart';

class StockLevelsScreen extends StatefulWidget {
  const StockLevelsScreen({super.key});
  @override
  State<StockLevelsScreen> createState() => _StockLevelsScreenState();
}

class _StockLevelsScreenState extends State<StockLevelsScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CatalogProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<CatalogProvider>().filterLocally(value);
    context.read<SearchProvider>().setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    return PremiumPage(
      title: 'Stock Levels',
      subtitle: 'Audit inventory and update stock counts.',
      child: Column(
        children: [
          _InnerTabBar(
            labels: const ['Stock Control', 'Stock Report'],
            index: _tabIndex,
            onChanged: (index) => setState(() => _tabIndex = index),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GlassTextField(
              controller: _searchController,
              icon: Icons.search,
              hint: 'Search by product or SKU...',
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: catalog.loading && catalog.products.isEmpty
                ? const LoadingView()
                : catalog.error != null && catalog.products.isEmpty
                    ? ErrorView(
                        message: catalog.error!,
                        onRetry: catalog.load,
                      )
                    : _tabIndex == 1
                        ? _StockReportView(products: catalog.products)
                        : catalog.products.isEmpty
                            ? EmptyView(
                                title: _searchController.text.isNotEmpty
                                    ? 'No products match "${_searchController.text}"'
                                    : 'No products found',
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 96),
                                itemCount: catalog.products.length,
                                itemBuilder: (context, i) {
                                  final p = catalog.products[i];
                                  return GlassCard(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 12),
                                        ...p.variants.map((v) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                      child: Text(
                                                          '${v.color} | ${v.size}',
                                                          style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600))),
                                                  Container(
                                                    width: 60,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Text(
                                                        v.stock.toString(),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.edit_outlined,
                                                        size: 18,
                                                        color: AppColors
                                                            .premiumGold),
                                                    onPressed: () =>
                                                        _showUpdateStock(
                                                            context,
                                                            v.id,
                                                            v.stock),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ],
                                    ),
                                  );
                                },
                              ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStock(BuildContext context, int variantId, int currentStock) {
    final controller = TextEditingController(text: currentStock.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('UPDATE STOCK',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GlassTextField(
                controller: controller,
                hint: 'New quantity',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 24),
              GlassButton(
                expanded: true,
                label: 'Save Changes',
                onPressed: () {
                  final stock = int.tryParse(controller.text.trim());
                  if (stock == null || stock < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Enter a valid stock count.')),
                    );
                    return;
                  }
                  context
                      .read<CatalogProvider>()
                      .updateVariantStock(variantId, stock);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InnerTabBar extends StatelessWidget {
  const _InnerTabBar({
    required this.labels,
    required this.index,
    required this.onChanged,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassCard(
        radius: 18,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: index == i
                          ? AppColors.premiumPink.withValues(alpha: 0.55)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      labels[i].toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: index == i
                            ? AppColors.deepMaroon
                            : AppColors.slate500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockReportView extends StatelessWidget {
  const _StockReportView({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyView(title: 'No stock report data');
    }

    final variants = [
      for (final product in products)
        for (final variant in product.variants)
          (product: product, variant: variant),
    ];
    final totalStock = variants.fold<int>(
      0,
      (total, row) => total + row.variant.stock,
    );
    final lowStock = variants.where((row) => row.variant.stock <= 3).length;
    final totalValue = variants.fold<double>(
      0,
      (total, row) => total + (row.variant.stock * row.variant.price),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Row(
          children: [
            Expanded(
                child: _ReportStat(
                    label: 'Total Stock', value: totalStock.toString())),
            const SizedBox(width: 10),
            Expanded(
                child: _ReportStat(
                    label: 'Low Stock', value: lowStock.toString())),
          ],
        ),
        const SizedBox(height: 10),
        _ReportStat(
            label: 'Stock Value',
            value: 'Rs. ${totalValue.toStringAsFixed(0)}'),
        const SizedBox(height: 16),
        ...variants.map((row) {
          final stock = row.variant.stock;
          return GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate800)),
                      const SizedBox(height: 3),
                      Text(
                          '${row.variant.color} | ${row.variant.size} | ${row.variant.sku}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (stock <= 3 ? Colors.red : AppColors.premiumPink)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    stock.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: stock <= 3 ? Colors.red : AppColors.premiumGold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepMaroon)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.slate500,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }
}
