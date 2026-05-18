import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A reusable widget that displays a product image fetched from a Django media URL.
///
/// - Shows a [CircularProgressIndicator] while the image loads.
/// - If the image fails to load (404, network error, null/empty URL) it falls back
///   to the boutique placeholder icon (`Icons.checkroom_outlined`).
/// - Appends a timestamp query parameter to bust the cache and retry later when
///   the image becomes available.
/// - All visual parameters (size, border radius, background colour) are configurable
///   so the widget can be used in cards, lists, grids, etc.
class ProductImageWidget extends StatelessWidget {
  const ProductImageWidget({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.borderRadius,
    this.iconSize = 40,
    this.iconColor,
    this.backgroundColor,
    this.fit = BoxFit.cover,
  });

  /// The raw image URL coming from the Django backend. If null or empty, the placeholder is shown.
  final String? imageUrl;

  /// Desired height of the image container.
  final double? height;

  /// Desired width of the image container.
  final double? width;

  /// Border radius for the image – usually matches the card’s radius.
  final BorderRadiusGeometry? borderRadius;

  /// Size of the placeholder icon.
  final double iconSize;

  /// Colour of the placeholder icon – defaults to the boutique deep‑maroon.
  final Color? iconColor;

  /// Background colour behind the placeholder – defaults to white.
  final Color? backgroundColor;

  /// How the image should be fitted inside its container.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    // If an image URL is provided, add a timestamp to force a refresh when the
    // resource becomes available later.
    final String? refreshedUrl = (imageUrl != null && imageUrl!.isNotEmpty)
        ? '${imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}'
        : null;

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: refreshedUrl != null
          ? Image.network(
              refreshedUrl,
              height: height,
              width: width,
              fit: fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return SizedBox(
                  height: height,
                  width: width,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: backgroundColor ?? Colors.white,
      alignment: Alignment.center,
      child: Icon(
        Icons.checkroom_outlined,
        size: iconSize,
        color: iconColor ?? AppColors.deepMaroon,
      ),
    );
  }
}
