import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/glass_widgets.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.deepMaroon));
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(title, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.slate600)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.slate400)),
          ],
        ],
      ),
    ),
  );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_off_rounded, size: 40, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          const Text('Connection Issue', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate800)),
          const SizedBox(height: 8),
          Text(message, 
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.deepMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ),
  );
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key,
      required this.label,
      required this.value,
      required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassStatCard(label: label, value: value, icon: icon);
  }
}
