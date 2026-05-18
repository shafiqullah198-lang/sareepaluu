import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass_widgets.dart';
import '../../core/theme/reusable_components.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return PremiumPage(
      title: 'Profile',
      subtitle: 'Session, role, and account settings.',
      child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            GlassCard(
                child: Row(children: [
              CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.premiumPink.withValues(alpha: 0.5),
                  child: const Icon(Icons.person_outline,
                      color: AppColors.premiumGold)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(auth.user?['username'] ?? 'User',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                        auth.user?['is_superuser'] == true
                            ? 'Superuser'
                            : auth.user?['is_staff'] == true
                                ? 'Staff'
                                : 'User',
                        style: Theme.of(context).textTheme.bodySmall),
                  ])),
            ])),
            const SizedBox(height: 12),
            GlassCard(
                child: SwitchListTile(
                    value: true,
                    onChanged: (_) {},
                    title: const Text('Protected API access'),
                    activeThumbColor: AppColors.premiumGold)),
            const SizedBox(height: 12),
            GlassButton(
              icon: Icons.logout,
              label: 'Logout',
              expanded: true,
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, AppRoutes.login, (_) => false);
                }
              },
            ),
          ]),
    );
  }
}
