import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../models/tailoring.dart';
import '../../providers/tailoring_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/state_views.dart';

class TailoringCenterScreen extends StatefulWidget {
  const TailoringCenterScreen({super.key});
  @override
  State<TailoringCenterScreen> createState() => _TailoringCenterScreenState();
}

class _TailoringCenterScreenState extends State<TailoringCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _tabIndex = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TailoringProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    if (_tabIndex == 0) {
      context.read<TailoringProvider>().filterLocally(value);
    }
    context.read<SearchProvider>().setQuery(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TailoringProvider>();
    return PremiumPage(
      title: 'Tailoring Center',
      subtitle: 'Manage stitching statuses and darzi assignments.',
      child: Column(
        children: [
          _InnerTabBar(
            labels: const ['Stitching Orders', 'Tailor Team'],
            index: _tabIndex,
            onChanged: (index) {
              setState(() => _tabIndex = index);
              if (index == 0) {
                context.read<TailoringProvider>().filterLocally(_query);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: GlassTextField(
              controller: _searchController,
              icon: Icons.search,
              hint: _tabIndex == 0
                  ? 'Search by token, customer, product...'
                  : 'Search tailor by name or phone...',
              onChanged: _onQueryChanged,
            ),
          ),
          Expanded(
            child: provider.loading && provider.items.isEmpty
                ? const LoadingView()
                : provider.error != null && provider.items.isEmpty
                    ? ErrorView(
                        message: provider.error!,
                        onRetry: provider.load,
                      )
                    : _tabIndex == 1
                        ? _TailorTeamView(provider: provider, query: _query)
                        : provider.items.isEmpty
                            ? EmptyView(
                                title: _searchController.text.isNotEmpty
                                    ? 'No tailoring items match "${_searchController.text}"'
                                    : 'No pending stitching',
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 96),
                                itemCount: provider.items.length,
                                itemBuilder: (context, i) {
                                  final item = provider.items[i];
                                  return _TailoringCard(item: item);
                                },
                              ),
          ),
        ],
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

class _TailorTeamView extends StatelessWidget {
  const _TailorTeamView({required this.provider, required this.query});
  final TailoringProvider provider;
  final String query;

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final darzis = provider.darzis.where((darzi) {
      if (q.isEmpty) return true;
      return darzi.name.toLowerCase().contains(q) ||
          (darzi.phone ?? '').toLowerCase().contains(q);
    }).toList();

    if (darzis.isEmpty) {
      return EmptyView(
        title: q.isEmpty ? 'No tailors found' : 'No tailors match "$query"',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: darzis.length,
      itemBuilder: (context, index) {
        final darzi = darzis[index];
        final assigned = provider.items
            .where((item) => item.darziName == darzi.name)
            .toList();
        final ready = assigned.where((item) => item.status == 'Ready').length;

        return GlassCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.premiumPink.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.premiumGold),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(darzi.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.slate800)),
                        if (darzi.phone != null)
                          Text(darzi.phone!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate500)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white38),
              Row(
                children: [
                  Expanded(
                      child: _MiniStat(
                          label: 'Assigned',
                          value: assigned.length.toString())),
                  Expanded(
                      child:
                          _MiniStat(label: 'Ready', value: ready.toString())),
                  Expanded(
                      child: _MiniStat(
                          label: 'Pending',
                          value: (assigned.length - ready).toString())),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.deepMaroon)),
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.slate400,
                letterSpacing: 0.6)),
      ],
    );
  }
}

class _TailoringCard extends StatelessWidget {
  const _TailoringCard({required this.item});
  final TailoringItem item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.tokenNumber,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.premiumGold)),
              _StatusChip(status: item.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.productName,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate800)),
          Text('${item.color} | ${item.customerName}',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500)),
          const Divider(height: 24, color: Colors.white38),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.slate400),
              const SizedBox(width: 6),
              Text(item.darziName ?? 'Unassigned',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate700)),
              const Spacer(),
              _ActionMenu(item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.blue;
    if (status == 'Ready') color = Colors.green;
    if (status == 'Sent To Darzi') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.item});
  final TailoringItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.person_add_alt_1_outlined,
              size: 18, color: AppColors.premiumGold),
          onPressed: () => _showDarziPicker(context, item),
        ),
        IconButton(
          icon: const Icon(Icons.edit_note_outlined,
              size: 18, color: AppColors.slate500),
          onPressed: () => _showStatusPicker(context, item),
        ),
      ],
    );
  }

  void _showDarziPicker(BuildContext context, TailoringItem item) {
    final provider = context.read<TailoringProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ASSIGN DARZI',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ...provider.darzis.map((d) => ListTile(
                  title: Text(d.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    provider.assignDarzi(item.id, d.id);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, TailoringItem item) {
    final provider = context.read<TailoringProvider>();
    final statuses = ['Pending', 'Cutting', 'Stitching', 'Ready', 'Delivered'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('UPDATE STATUS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 16),
            ...statuses.map((s) => ListTile(
                  title: Text(s,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    provider.updateStatus(item.id, s);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
