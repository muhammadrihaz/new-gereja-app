import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A drop-in image widget backed by `cached_network_image` that:
/// - Lazy-loads and caches on disk for offline / repeat viewing.
/// - Shows a shimmer placeholder while loading.
/// - Falls back to a friendly icon on error.
///
/// Used for news cover, hero images, event thumbs and gallery.
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.fallbackIcon = Icons.image_outlined,
    this.memCacheWidth,
    this.memCacheHeight,
    this.aspectRatio,
  });

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final double? aspectRatio;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);
    Widget child;

    if (url == null || url!.isEmpty) {
      child = _fallback(context);
    } else {
      child = CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (context, _) => _shimmer(context),
        errorWidget: (context, _, _) => _fallback(context),
        fadeInDuration: const Duration(milliseconds: 200),
      );
    }

    Widget wrapped = ClipRRect(borderRadius: radius, child: child);
    if (aspectRatio != null) {
      wrapped = AspectRatio(aspectRatio: aspectRatio!, child: wrapped);
    }
    return wrapped;
  }

  Widget _shimmer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHigh,
      highlightColor: scheme.surfaceContainerLow,
      child: Container(color: Colors.white),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 32, color: scheme.onSurfaceVariant),
    );
  }
}
