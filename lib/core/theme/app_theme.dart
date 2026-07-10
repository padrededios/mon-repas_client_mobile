import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ThemeData clair/sombre construits depuis les tokens shadcn de la webapp.
/// Rayon des cartes et champs : 8 px (--radius: 0.5rem).
class AppTheme {
  AppTheme._();

  static const double cardRadius = 8;

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  /// Thème « BD » : le thème clair reconstruit sur la palette comic
  /// (bordures noires), avec des contours épaissis façon cases de BD.
  static ThemeData get comic {
    const c = AppColors.comic;
    final base = _build(c, Brightness.light);
    final radius = BorderRadius.circular(cardRadius);
    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        shape: const Border(
          bottom: BorderSide(color: Color(0xFF1C1917), width: 2),
        ),
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: Color(0xFF1C1917), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryForeground,
          elevation: 0,
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: const BorderSide(color: Color(0xFF1C1917), width: 2),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          side: const BorderSide(color: Color(0xFF1C1917), width: 2),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.secondary,
      onSecondary: c.secondaryForeground,
      error: c.destructive,
      onError: c.destructiveForeground,
      surface: c.background,
      onSurface: c.foreground,
      surfaceContainerHighest: c.muted,
      surfaceContainerHigh: c.card,
      surfaceContainer: c.card,
      surfaceContainerLow: c.card,
      onSurfaceVariant: c.mutedForeground,
      outline: c.border,
      outlineVariant: c.border,
      tertiary: AppColors.brandOrange,
      onTertiary: Colors.white,
    );

    final radius = BorderRadius.circular(cardRadius);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: c.border)),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c.input),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c.input),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c.ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c.destructive, width: 2),
        ),
        hintStyle: TextStyle(color: c.mutedForeground),
        labelStyle: TextStyle(color: c.mutedForeground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.primaryForeground,
          elevation: 0,
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.foreground,
          side: BorderSide(color: c.border),
          minimumSize: const Size(64, 44),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.foreground),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.brandOrange.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? AppColors.brandOrange
                : c.mutedForeground,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.brandOrange
                : c.mutedForeground,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.foreground,
        unselectedLabelColor: c.mutedForeground,
        indicatorColor: AppColors.brandOrange,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.light
            ? c.foreground
            : c.popover,
        contentTextStyle: TextStyle(
          color: brightness == Brightness.light
              ? c.background
              : c.foreground,
        ),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.popover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.popover,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.secondary,
        labelStyle: TextStyle(color: c.secondaryForeground),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brandOrange,
        linearTrackColor: c.muted,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.mutedForeground,
        textColor: c.foreground,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primaryForeground
              : c.mutedForeground,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandOrange
              : c.muted,
        ),
      ),
    );
  }
}
