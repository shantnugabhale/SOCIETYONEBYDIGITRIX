import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class DarkTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryLight,
        surface: AppColors.darkSurface,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.darkTextPrimary,
        onError: AppColors.textOnPrimary,
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppStyles.heading6.copyWith(color: AppColors.darkTextPrimary),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceVariant,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius12,
        ),
        margin: const EdgeInsets.all(AppStyles.spacing8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadius8,
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
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadius8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacing24,
            vertical: AppStyles.spacing12,
          ),
          textStyle: AppStyles.button.copyWith(color: AppColors.primaryLight),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyles.borderRadius8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacing16,
            vertical: AppStyles.spacing8,
          ),
          textStyle: AppStyles.button.copyWith(color: AppColors.primaryLight),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius8,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius8,
          borderSide: const BorderSide(color: AppColors.grey600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius8,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius8,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppStyles.borderRadius8,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacing16,
          vertical: AppStyles.spacing12,
        ),
        labelStyle: AppStyles.bodyMedium.copyWith(color: AppColors.grey400),
        hintStyle: AppStyles.bodyMedium.copyWith(color: AppColors.grey500),
        errorStyle: AppStyles.bodySmall.copyWith(color: AppColors.error),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
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
      ).apply(
        bodyColor: AppColors.textOnPrimary,
        displayColor: AppColors.textOnPrimary,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textOnPrimary,
        size: 24,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnPrimary,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.grey600,
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
          borderRadius: AppStyles.borderRadius8,
        ),
        tileColor: const Color(0xFF2D2D2D),
        selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.1),
        textColor: AppColors.textOnPrimary,
        iconColor: AppColors.grey400,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        selectedColor: AppColors.primaryLight,
        disabledColor: AppColors.grey600,
        labelStyle: AppStyles.bodySmall.copyWith(color: AppColors.textOnPrimary),
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
            return AppColors.primaryLight;
          }
          return AppColors.grey500;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight.withValues(alpha: 0.5);
          }
          return AppColors.grey600;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return const Color(0xFF2D2D2D);
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.grey500, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius4,
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return AppColors.grey500;
        }),
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryLight,
        inactiveTrackColor: AppColors.grey600,
        thumbColor: AppColors.primaryLight,
        overlayColor: AppColors.primaryLight.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.primaryLight,
        valueIndicatorTextStyle: AppStyles.bodySmall.copyWith(color: AppColors.textOnPrimary),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryLight,
        linearTrackColor: AppColors.grey600,
        circularTrackColor: AppColors.grey600,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey800,
        contentTextStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius8,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadius16,
        ),
        titleTextStyle: AppStyles.heading5.copyWith(color: AppColors.textOnPrimary),
        contentTextStyle: AppStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF2D2D2D),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppStyles.radius16),
          ),
        ),
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.grey400,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        labelStyle: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppStyles.bodyMedium,
      ),
    );
  }
}
