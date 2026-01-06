import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color? iconColor;
  final Color? backgroundColor;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  effectiveIconColor.withValues(alpha: 0.1),
                  effectiveIconColor.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: effectiveIconColor,
            ),
          ),
          const SizedBox(height: AppStyles.spacing24),
          Text(
            title,
            style: AppStyles.heading4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppStyles.spacing12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppStyles.spacing24),
              child: Text(
                subtitle!,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: AppStyles.spacing32),
            Material(
              elevation: 0,
              borderRadius: BorderRadius.circular(AppStyles.radius16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveIconColor,
                      effectiveIconColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppStyles.radius16),
                  boxShadow: [
                    BoxShadow(
                      color: effectiveIconColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onButtonPressed,
                    borderRadius: BorderRadius.circular(AppStyles.radius16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacing24,
                        vertical: AppStyles.spacing16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            buttonText!,
                            style: AppStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.add_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

