import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  // Text Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle heading5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle heading6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
    height: 1.3,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );
  
  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    height: 1.4,
  );
  
  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  
  // Border Radius
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;
  static const double radius32 = 32.0;
  
  // Border Radius Objects
  static const BorderRadius borderRadius4 = BorderRadius.all(Radius.circular(4));
  static const BorderRadius borderRadius8 = BorderRadius.all(Radius.circular(8));
  static const BorderRadius borderRadius12 = BorderRadius.all(Radius.circular(12));
  static const BorderRadius borderRadius16 = BorderRadius.all(Radius.circular(16));
  static const BorderRadius borderRadius20 = BorderRadius.all(Radius.circular(20));
  static const BorderRadius borderRadius24 = BorderRadius.all(Radius.circular(24));
  static const BorderRadius borderRadius32 = BorderRadius.all(Radius.circular(32));
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryLight,
      AppColors.primary,
      AppColors.primaryDark,
    ],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      AppColors.grey50,
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCCFFFFFF), // 80% White
      Color(0x99FFFFFF), // 60% White
    ],
  );

  // Shadows - Soft, diffused elevation for premium look
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x0F1E293B), // Slate 800 with low opacity
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];
  
  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x141E293B), // Slate 800 with low opacity
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -2,
    ),
  ];
  
  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x1F1E293B), // Slate 800 with low opacity
      offset: Offset(0, 12),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];
  
  static const List<BoxShadow> shadowXLarge = [
    BoxShadow(
      color: Color(0x291E293B), // Slate 800 with low opacity
      offset: Offset(0, 24),
      blurRadius: 48,
      spreadRadius: -12,
    ),
  ];
  
  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface,
    borderRadius: borderRadius16,
    boxShadow: shadowSmall,
    border: Border.all(color: AppColors.grey200),
  );
  
  static BoxDecoration cardDecorationElevated = BoxDecoration(
    color: AppColors.surface,
    borderRadius: borderRadius16,
    boxShadow: shadowMedium,
    border: Border.all(color: AppColors.grey100),
  );

  // Glassmorphism Styles
  static BoxDecoration glassDecoration = BoxDecoration(
    gradient: glassGradient,
    borderRadius: borderRadius24,
    border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
    boxShadow: shadowMedium,
  );
  
  // Button Styles
  static BoxDecoration primaryButtonDecoration = BoxDecoration(
    gradient: primaryGradient,
    borderRadius: borderRadius12,
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        offset: const Offset(0, 4),
        blurRadius: 12,
        spreadRadius: 0,
      ),
    ],
  );
  
  static BoxDecoration secondaryButtonDecoration = BoxDecoration(
    color: AppColors.secondary,
    borderRadius: borderRadius12,
    boxShadow: shadowSmall,
  );
  
  static BoxDecoration outlineButtonDecoration = BoxDecoration(
    color: Colors.transparent,
    borderRadius: borderRadius12,
    border: Border.all(color: AppColors.primary, width: 1.5),
  );
  
  // Input Field Styles
  static InputDecoration inputDecoration = InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: borderRadius12,
      borderSide: BorderSide(color: AppColors.grey200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius12,
      borderSide: BorderSide(color: AppColors.grey200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius12,
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius12,
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius12,
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: spacing16,
      vertical: spacing16,
    ),
    hintStyle: bodyMedium.copyWith(color: AppColors.textHint),
    labelStyle: bodyMedium.copyWith(color: AppColors.textSecondary),
  );
  
  // App Bar Styles
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: heading5.copyWith(color: AppColors.textOnPrimary),
    iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
  );
  
  // Bottom Navigation Bar Styles
  static BottomNavigationBarThemeData bottomNavTheme = BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
}
