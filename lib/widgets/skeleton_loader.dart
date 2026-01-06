import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/colors.dart';

/// Skeleton loader widget for loading states
/// Provides shimmer effect for better UX
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? 
                (isDark 
                  ? AppColors.darkSurfaceVariant 
                  : AppColors.grey200),
      highlightColor: highlightColor ?? 
                      (isDark 
                        ? AppColors.darkSurface 
                        : AppColors.grey100),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.darkSurfaceVariant 
              : AppColors.grey300,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Pre-built skeleton widgets for common UI elements
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16.0,
    this.borderRadius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;

  const SkeletonCard({
    super.key,
    this.width,
    this.height = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width ?? double.infinity,
      height: height,
      borderRadius: 16.0,
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;

  const SkeletonAvatar({
    super.key,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}

