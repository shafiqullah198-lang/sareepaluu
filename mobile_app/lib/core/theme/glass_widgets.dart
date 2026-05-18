import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'spacing.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
    this.tint = Colors.white,
    this.borderColor,
    this.blur = 25,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color tint;
  final Color? borderColor;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepMaroon.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: content,
      );
    }
    return GlassTapScale(onTap: onTap!, child: content);
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.margin,
    this.tint = Colors.white,
    this.radius = 32, // More rounded for "neat" look
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color tint;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: GlassSurface(
          padding: padding,
          tint: tint,
          radius: radius,
          onTap: onTap,
          child: child,
        ),
      );
}

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expanded = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = GlassTapScale(
      onTap: onPressed,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: BoxDecoration(
          gradient: onPressed == null ? null : AppColors.premiumGradient,
          color: onPressed == null ? Colors.white.withValues(alpha: 0.3) : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: onPressed == null
              ? []
              : [
                  BoxShadow(
                    color: AppColors.premiumGold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
        ),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
              ],
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ]),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.hint,
    this.label,
    this.icon,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
  });
  final TextEditingController? controller;
  final String? hint;
  final String? label;
  final IconData? icon;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              label!.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppColors.slate500,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                onSubmitted: onSubmitted,
                onChanged: onChanged,
                keyboardType: keyboardType,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.slate400.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                  prefixIcon: icon == null
                      ? null
                      : Icon(icon, color: AppColors.slate400, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class GlassTapScale extends StatefulWidget {
  const GlassTapScale({required this.child, this.onTap, super.key});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<GlassTapScale> createState() => _GlassTapScaleState();
}

class _GlassTapScaleState extends State<GlassTapScale> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => pressed = true),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => pressed = false),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.index,
    required this.onSelected,
    required this.items,
  });
  final int index;
  final ValueChanged<int> onSelected;
  final List<NavigationDestination> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GlassSurface(
        radius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: index,
          onDestinationSelected: onSelected,
          indicatorColor: AppColors.premiumPink.withValues(alpha: 0.3),
          destinations: items,
        ),
      ),
    );
  }
}

class GlassStatCard extends StatelessWidget {
  const GlassStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint = AppColors.premiumPink,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.premiumGold, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate500, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.slate800)),
            ])),
      ]),
    );
  }
}
