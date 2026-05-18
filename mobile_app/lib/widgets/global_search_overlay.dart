import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../providers/search_provider.dart';

/// Full-screen global search overlay.
/// Opens via [GlobalSearchOverlay.show].
class GlobalSearchOverlay extends StatefulWidget {
  const GlobalSearchOverlay({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (context, _, __) => const GlobalSearchOverlay(),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  State<GlobalSearchOverlay> createState() => _GlobalSearchOverlayState();
}

class _GlobalSearchOverlayState extends State<GlobalSearchOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    // Clear query on dismiss so per-screen lists are restored.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final results = search.globalResults;
    final hasQuery = search.hasQuery;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.deepMaroon, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (v) => context.read<SearchProvider>().setQuery(v),
                          decoration: const InputDecoration(
                            hintText: 'Search products, orders, customers…',
                            hintStyle: TextStyle(color: AppColors.slate400, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          style: const TextStyle(fontSize: 15, color: AppColors.slate800, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.slate400, size: 20),
                          onPressed: () {
                            _controller.clear();
                            context.read<SearchProvider>().clearQuery();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.deepMaroon, size: 22),
                        onPressed: () {
                          context.read<SearchProvider>().clearQuery();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Results ─────────────────────────────────────────
            Expanded(
              child: Material(
                color: Colors.white,
                child: !hasQuery
                    ? _buildEmptyPrompt()
                    : results.isEmpty
                        ? _buildNoResults(search.query)
                        : _buildResults(results),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.premiumPink.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, size: 40, color: AppColors.deepMaroon),
          ),
          const SizedBox(height: 20),
          const Text(
            'Search the entire boutique',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Products, orders, customers, tailoring…',
            style: TextStyle(fontSize: 13, color: AppColors.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.slate700),
          ),
          const SizedBox(height: 8),
          const Text('Try different keywords.', style: TextStyle(fontSize: 12, color: AppColors.slate400)),
        ],
      ),
    );
  }

  Widget _buildResults(Map<String, List<SearchResultItem>> results) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: results.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.deepMaroon,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value.length} result${entry.value.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.slate400, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // Result tiles
            ...entry.value.map((item) => _SearchResultTile(item: item)),
          ],
        );
      }).toList(),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.item});
  final SearchResultItem item;

  IconData get _icon {
    switch (item.section) {
      case 'Products':
        return Icons.inventory_2_outlined;
      case 'Orders':
        return Icons.receipt_long_outlined;
      case 'Customers':
        return Icons.person_outline;
      case 'Tailoring':
        return Icons.content_cut_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color get _iconColor {
    switch (item.section) {
      case 'Products':
        return AppColors.premiumGold;
      case 'Orders':
        return Colors.blue.shade400;
      case 'Customers':
        return Colors.green.shade500;
      case 'Tailoring':
        return Colors.orange;
      default:
        return AppColors.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_icon, color: _iconColor, size: 20),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.slate800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.slate500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.slate300),
      ),
    );
  }
}
