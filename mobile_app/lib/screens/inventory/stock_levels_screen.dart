import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
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
                    : catalog.products.isEmpty
                        ? EmptyView(
                            title: _searchController.text.isNotEmpty
                                ? 'No products match "${_searchController.text}"'
                                : 'No products found',
                          )
                        : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: catalog.products.length,
                        itemBuilder: (context, i) {
                          final p = catalog.products[i];
                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ...p.variants.map((v) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(child: Text('${v.color} | ${v.size}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                          Container(
                                            width: 60,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(v.stock.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.premiumGold),
                                            onPressed: () => _showUpdateStock(context, v.id, v.stock),
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
              const Text('UPDATE STOCK', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  // TODO: Add update method to CatalogProvider
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
