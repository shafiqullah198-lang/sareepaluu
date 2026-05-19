import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/product_image.dart';
import '../../widgets/state_views.dart';
import 'package:url_launcher/url_launcher.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController _partialAmountController =
      TextEditingController();
  String query = '';
  String _paymentType = 'Full';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CatalogProvider>().load();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _partialAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w > 900;

    return PremiumPage(
      title: 'Boutique POS System',
      subtitle: 'Here\'s what\'s happening in your boutique today.',
      child: isDesktop
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 3,
                      child: _buildProductSection(context, isMobile: false)),
                  const SizedBox(width: 32),
                  Expanded(flex: 2, child: _buildCartSection(context)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _buildProductSection(context, isMobile: true),
                const SizedBox(height: 24),
                _buildCartSection(context),
              ],
            ),
    );
  }

  Widget _buildProductSection(BuildContext context, {bool isMobile = false}) {
    final catalog = context.watch<CatalogProvider>();
    List<Product> products = catalog.products;
    if (query.isNotEmpty) {
      products = products
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    Widget grid = catalog.loading && products.isEmpty
        ? const LoadingView()
        : catalog.error != null && products.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child:
                      ErrorView(message: catalog.error!, onRetry: catalog.load),
                ),
              )
            : products.isEmpty
                ? _buildEmptyState()
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final p = products[index];
                        return _ProductCard(
                          product: p,
                          onTap: () => _showVariantModal(context, p),
                        );
                      },
                    ),
                  );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.premiumPink.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: searchController,
            onChanged: (v) {
              setState(() => query = v);
              context.read<CatalogProvider>().filterLocally(v);
              context.read<SearchProvider>().setQuery(v);
            },
            decoration: const InputDecoration(
              hintText: 'Search products, colors, customers...',
              hintStyle: TextStyle(color: AppColors.slate400, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: AppColors.deepMaroon),
              suffixIcon:
                  Icon(Icons.qr_code_scanner, color: AppColors.deepMaroon),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Products',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.slate800)),
            Row(
              children: [
                const Text('View All',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.deepMaroon,
                        fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.deepMaroon),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile) grid else Expanded(child: grid),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.premiumPink.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 40, color: AppColors.deepMaroon),
          ),
          const SizedBox(height: 24),
          const Text('Ready for a new sale?',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800)),
          const SizedBox(height: 12),
          const Text(
              'Search for a product above to start\nadding items to the current transaction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: AppColors.slate500, height: 1.5)),
        ],
      ),
    );
  }

  void _showVariantModal(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => _VariantModal(product: product),
    );
  }

  Widget _buildCartSection(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCF5F7), // very faint pink
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Current Cart',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFFDE7F0),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                    '${cart.lines.length} Item${cart.lines.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepMaroon)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (cart.lines.isEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_outlined,
                    size: 40, color: AppColors.deepMaroon),
                const SizedBox(height: 8),
                const Text('Cart is empty',
                    style: TextStyle(
                        color: AppColors.slate500,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
              ],
            )
          else
            ...cart.lines.map((line) => _CartItemTile(line: line)),
          const SizedBox(height: 8),
          _buildTextField(Icons.person_outline, 'Customer Name (Optional)',
              (v) => cart.customerName = v),
          const SizedBox(height: 12),
          _buildTextField(Icons.phone_outlined, 'Phone Number (Optional)',
              (v) => cart.customerPhone = v),
          const SizedBox(height: 24),
          _summaryRow('Subtotal', cart.subtotal),
          _summaryRow('Stitching Total', cart.stitchingTotal),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800)),
              Row(
                children: [
                  const Text('Rs. ',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.slate500)),
                  Container(
                    width: 60,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: (v) => cart.discount = double.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.slate200),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manual Product Total',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800)),
              Row(
                children: [
                  const Text('Rs. ',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.slate500)),
                  Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color:
                                AppColors.premiumPink.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8)),
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon),
                      onChanged: (v) {
                        if (v.isEmpty)
                          cart.setManualTotal(null);
                        else
                          cart.setManualTotal(double.tryParse(v));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow('Calculated', cart.calculatedTotal),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Payable',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate800)),
              Text('Rs. ${cart.finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepMaroon)),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
                color: const Color(0xFFFDE7F0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    const Text('Payment Type',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate800)),
                    Radio<String>(
                        value: 'Full',
                        groupValue: _paymentType,
                        activeColor: AppColors.deepMaroon,
                        onChanged: (v) {
                          setState(() => _paymentType = v!);
                          cart.setPaymentType(v!);
                        }),
                    const Text('Full',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    Radio<String>(
                        value: 'Partial',
                        groupValue: _paymentType,
                        activeColor: AppColors.deepMaroon,
                        onChanged: (v) {
                          setState(() => _paymentType = v!);
                          cart.setPaymentType(v!);
                        }),
                    const Text('Partial',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (_paymentType == 'Partial')
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 12),
                    child: TextField(
                      controller: _partialAmountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Enter amount',
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                      onChanged: (v) {
                        cart.setPartialAmount(double.tryParse(v));
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: cart.lines.isEmpty || cart.loading
                      ? null
                      : () async {
                          final order = await cart.checkout();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(order == null
                                ? (cart.error ?? 'Could not save order.')
                                : 'Order ${order.token} saved.'),
                          ));
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: AppColors.premiumPink.withValues(alpha: 0.4),
                        width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE ONLY',
                      style: TextStyle(
                          color: AppColors.deepMaroon,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: cart.lines.isEmpty || cart.loading
                      ? null
                      : () async {
                          final order = await cart.checkout();
                          if (!context.mounted) return;
                          if (order != null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Order Completed! Token: ${order.token}'),
                              backgroundColor: Colors.green.shade700,
                              action: SnackBarAction(
                                label: 'PRINT',
                                textColor: Colors.white,
                                onPressed: () async {
                                  if (order.invoiceUrl == null) return;
                                  final url = Uri.parse(order.invoiceUrl!);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.deepMaroon,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('COMPLETE & PRINT',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      IconData icon, String hint, ValueChanged<String> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.premiumPink.withValues(alpha: 0.3)),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.deepMaroon, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800)),
          Text('Rs. ${value.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800)),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.premiumPink.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ProductImageWidget(
                imageUrl: product.imageUrl,
                height: double.infinity,
                iconSize: 48,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate800)),
                  const SizedBox(height: 8),
                  Text(
                      'Rs. ${product.variants.isNotEmpty ? product.variants.first.price.toStringAsFixed(0) : '0'}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepMaroon)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE7F0).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImageWidget(
                imageUrl: line.product.imageUrl,
                width: 48,
                height: 48,
                iconSize: 24,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.product.name,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate800)),
                    const SizedBox(height: 4),
                    Text('${line.variant.color} | Qty: ${line.quantity}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate500)),
                  ],
                ),
              ),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppColors.slate500),
                  onPressed: () => cart.remove(line)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: line.needsStitching,
                  activeColor: AppColors.deepMaroon,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) {
                    line.needsStitching = v ?? false;
                    cart.updateLine(line);
                  },
                ),
              ),
              const SizedBox(width: 8),
              const Text('STITCHING',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepMaroon)),
              const Spacer(),
              const Text('Fee (Rs.)',
                  style: TextStyle(fontSize: 11, color: AppColors.slate500)),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8)),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                  onChanged: (v) {
                    line.stitchingPrice = double.tryParse(v) ?? 0.0;
                    cart.updateLine(line);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariantModal extends StatefulWidget {
  const _VariantModal({required this.product});
  final Product product;

  @override
  State<_VariantModal> createState() => _VariantModalState();
}

class _VariantModalState extends State<_VariantModal> {
  ProductVariant? selectedVariant;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      selectedVariant = widget.product.variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        tint: Colors.white,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.product.name,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('SELECT COLOR & QUANTITY',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate400,
                    letterSpacing: 1.2)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.product.variants.map((v) {
                final isSel = selectedVariant?.id == v.id;
                return InkWell(
                  onTap: () => setState(() => selectedVariant = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.premiumPink.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isSel
                              ? AppColors.premiumGold
                              : Colors.white.withValues(alpha: 0.6),
                          width: 1.5),
                    ),
                    child: Text(v.color,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? AppColors.premiumGold
                                : AppColors.slate700)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quantity',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate700)),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                              if (quantity > 1) quantity--;
                            })),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(quantity.toString(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => quantity++)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            GlassButton(
              expanded: true,
              label: 'Add to Cart',
              onPressed: selectedVariant == null
                  ? null
                  : () {
                      final cart = context.read<CartProvider>();
                      for (int i = 0; i < quantity; i++) {
                        cart.add(widget.product, selectedVariant!);
                      }
                      Navigator.pop(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
