import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'glass_widgets.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.floatingActionButton,
  });
  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 12), // Increased padding for "neat" look
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title!, 
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    fontSize: 22,
                  )
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(subtitle!, 
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      )
                    ),
                  ),
              ]),
            ),
          Expanded(child: child),
        ]),
      ),
    );
  }
}

class GlassDialog extends StatelessWidget {
  const GlassDialog({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: Colors.transparent, child: GlassCard(child: child));
}
