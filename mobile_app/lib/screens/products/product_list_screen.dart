import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../models/product.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/product_image.dart';
import '../../widgets/state_views.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final catalog = context.read<CatalogProvider>();
      if (catalog.products.isEmpty && !catalog.loading) {
        catalog.load();
      }
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
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    return PremiumPage(
      title: 'Products',
      subtitle: 'Browse collections, manage variants, and check stock.',
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
          child: GlassTextField(
            controller: _searchController,
            icon: Icons.search,
            hint: 'Search by name, SKU, color, category…',
            onChanged: _onQueryChanged,
            onSubmitted: (_) {},
          ),
        ),
        Expanded(
          child: catalog.loading && catalog.products.isEmpty
              ? const LoadingView()
              : catalog.error != null && catalog.products.isEmpty
                  ? ErrorView(
                      message: catalog.error!,
                      onRetry: () => catalog.load(),
                    )
                  : catalog.products.isEmpty
                      ? EmptyView(
                          title: _searchController.text.isNotEmpty
                              ? 'No products match "${_searchController.text}"'
                              : 'No products found',
                        )
                      : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        mainAxisExtent: 300,
                      ),
                      itemCount: catalog.products.length,
                      itemBuilder: (context, index) {
                        final p = catalog.products[index];
                        return _ProductGridCard(product: p);
                      },
                    ),
        ),
      ]),
    );
  }
}


class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: ProductImageWidget(
              imageUrl: product.imageUrl,
              height: double.infinity,
              iconSize: 48,
              iconColor: AppColors.premiumGold,
              backgroundColor: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.categoryName?.toUpperCase() ?? 'UNCATEGORIZED',
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.premiumGold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate800),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.variants.length} Variants',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.premiumPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.totalStock} in stock',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.premiumGold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
