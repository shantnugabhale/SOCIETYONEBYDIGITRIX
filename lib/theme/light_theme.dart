import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class LightTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),
      
      // App Bar Theme
      appBarTheme: AppStyles.appBarTheme,
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: AppStyles.bottomNavTheme,
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0, // Use custom shadows instead
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
        margin: const EdgeInsets.all(AppStyles.spacing8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0, // Use custom shadows instead
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadius16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacing24,
            vertical: AppStyles.spacing12,
          ),
          textStyle: AppStyles.button,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadius16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacing24,
            vertical: AppStyles.spacing12,
          ),
          textStyle: AppStyles.button.copyWith(color: AppColors.primary),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadius16,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacing16,
            vertical: AppStyles.spacing8,
          ),
          textStyle: AppStyles.button.copyWith(color: AppColors.primary),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius16,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius16,
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius16,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius16,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius16,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing16,
          vertical: AppStyles.spacing12,
        ),
        labelStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textHint),
        errorStyle: AppStyles.bodySmall.copyWith(color: AppColors.error),
      ),
      
      // Text Theme with Poppins font
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: AppStyles.heading1,
          displayMedium: AppStyles.heading2,
          displaySmall: AppStyles.heading3,
          headlineLarge: AppStyles.heading4,
          headlineMedium: AppStyles.heading5,
          headlineSmall: AppStyles.heading6,
          titleLarge: AppStyles.heading6,
          titleMedium: AppStyles.bodyLarge,
          titleSmall: AppStyles.bodyMedium,
          bodyLarge: AppStyles.bodyLarge,
          bodyMedium: AppStyles.bodyMedium,
          bodySmall: AppStyles.bodySmall,
          labelLarge: AppStyles.button,
          labelMedium: AppStyles.buttonSmall,
          labelSmall: AppStyles.caption,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimary,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.grey300,
        thickness: 1,
        space: 1,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing16,
          vertical: AppStyles.spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
        tileColor: AppColors.surface,
        selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.1),
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.grey300,
        labelStyle: AppStyles.bodySmall,
        secondaryLabelStyle: AppStyles.bodySmall.copyWith(color: AppColors.textOnPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing12,
          vertical: AppStyles.spacing8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.grey300;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.grey400, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.grey400;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.grey300,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primaryLight.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: AppStyles.bodySmall.copyWith(color: AppColors.textOnPrimary),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.grey300,
        circularTrackColor: AppColors.grey300,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0, // Use custom shadows instead
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey800,
        contentTextStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0, // Use custom shadows instead
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0, // Use custom shadows instead
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
        titleTextStyle: AppStyles.heading5,
        contentTextStyle: AppStyles.bodyMedium,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0, // Use custom shadows instead
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppStyles.radius16),
          ),
        ),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppStyles.bodyMedium,
      ),
    );
  }
}
