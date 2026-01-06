import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/colors.dart';

/// Modern glassmorphism card widget
/// Creates a frosted glass effect with blur
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultGradient = gradient ?? LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.darkSurface.withOpacity(opacity),
              AppColors.darkSurfaceVariant.withOpacity(opacity),
            ]
          : [
              AppColors.glassWhite,
              AppColors.glassWhite.withOpacity(0.5),
            ],
    );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius ?? 16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          margin: margin,
          decoration: BoxDecoration(
            gradient: defaultGradient,
            borderRadius: BorderRadius.circular(borderRadius ?? 16),
            border: Border.all(
              color: borderColor ?? 
                    (isDark 
                      ? AppColors.glassBorder 
                      : AppColors.glassBorder.withOpacity(0.3)),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: card,
      );
    }

    return card;
  }
}

