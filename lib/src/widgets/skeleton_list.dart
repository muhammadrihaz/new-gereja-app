import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer skeleton that mimics a news / event card list. Adaptive to
/// available width and works for both mobile and desktop.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 120,
    this.padding = const EdgeInsets.all(16),
  });

  final int itemCount;
  final double itemHeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHigh;
    final highlightColor = scheme.surfaceContainerLow;

    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: itemHeight,
            decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: itemHeight,
                  height: itemHeight,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        color: baseColor,
                      ),
                      const SizedBox(height: 8),
                      Container(height: 12, width: 220, color: baseColor),
                      const SizedBox(height: 6),
                      Container(height: 12, width: 160, color: baseColor),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A shimmer skeleton for grid layouts (used by the Gallery).
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    this.itemCount = 9,
    this.crossAxisCount = 3,
    this.padding = const EdgeInsets.all(12),
  });

  final int itemCount;
  final int crossAxisCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: scheme.surfaceContainerHigh,
            highlightColor: scheme.surfaceContainerLow,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      ),
    );
  }
}
