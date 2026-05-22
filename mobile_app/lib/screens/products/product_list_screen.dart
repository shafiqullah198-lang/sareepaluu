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
  int _tabIndex = 0;

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

  void _showAddProduct(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ADD NEW PRODUCT', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              GlassTextField(controller: nameController, hint: 'Product Name', icon: Icons.shopping_bag_outlined),
              const SizedBox(height: 16),
              GlassTextField(controller: categoryController, hint: 'Category', icon: Icons.category_outlined),
              const SizedBox(height: 24),
              GlassButton(
                expanded: true,
                label: 'Save Product',
                onPressed: () {
                  if (nameController.text.isNotEmpty && categoryController.text.isNotEmpty) {
                    context.read<CatalogProvider>().addProduct(nameController.text, categoryController.text);
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

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    return PremiumPage(
      title: 'Products',
      subtitle: 'Browse collections, manage variants, and check stock.',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProduct(context),
        backgroundColor: AppColors.premiumGold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: Column(children: [
        _InnerTabBar(
          labels: const ['Product Catalog', 'Manage Collections'],
          index: _tabIndex,
          onChanged: (index) => setState(() => _tabIndex = index),
        ),
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
                  : _tabIndex == 1
                      ? _CollectionsView(products: catalog.products)
                      : catalog.products.isEmpty
                          ? EmptyView(
                              title: _searchController.text.isNotEmpty
                                  ? 'No products match "${_searchController.text}"'
                                  : 'No products found',
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
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
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
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

class _CollectionsView extends StatelessWidget {
  const _CollectionsView({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const EmptyView(title: 'No collections found');
    }

    final groups = <String, List<Product>>{};
    for (final product in products) {
      final name = product.categoryName?.trim().isNotEmpty == true
          ? product.categoryName!.trim()
          : 'Uncategorized';
      groups.putIfAbsent(name, () => []).add(product);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
      children: groups.entries.map((entry) {
        final stock = entry.value.fold<int>(
          0,
          (total, product) => total + product.totalStock,
        );
        final variants = entry.value.fold<int>(
          0,
          (total, product) => total + product.variants.length,
        );

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          onTap: () => _showCollectionProducts(context, entry.key, entry.value),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.premiumPink.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.category_outlined,
                    color: AppColors.premiumGold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.slate800)),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.value.length} products | $variants variants | $stock stock',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate400),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showCollectionProducts(
      BuildContext context, String title, List<Product> products) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.35,
        builder: (context, controller) => GlassCard(
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.slate500)),
              const SizedBox(height: 12),
              ...products.map((product) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle:
                        Text('${product.variants.length} variants available'),
                    trailing: Text('${product.totalStock}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.premiumGold)),
                  )),
            ],
          ),
        ),
      ),
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                    style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: AppColors.premiumGold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.variants.length} Variants',
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate400),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.premiumPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${product.totalStock} in stock',
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.premiumGold),
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
