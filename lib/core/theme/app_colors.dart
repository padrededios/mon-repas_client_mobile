import 'package:flutter/material.dart';

/// Tokens de couleur portés de `mon-repas_client/src/app/globals.css`
/// (variables shadcn), exposés comme ThemeExtension pour suivre le mode
/// clair/sombre via `context.appColors`.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.popover,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.input,
    required this.ring,
    required this.success,
    required this.warning,
  });

  final Color background;
  final Color foreground;
  final Color card;
  final Color popover;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color input;
  final Color ring;
  final Color success;
  final Color warning;

  /// Accent de marque (onglet actif, CTA, focus) — identique aux deux thèmes.
  static const Color brandOrange = Color(0xFFF97015);

  /// Couleurs de catégories du calendrier (identiques à la webapp).
  static const Color categoryMeal = Color(0xFF3B82F6); // bleu
  static const Color categoryDoggyBag = Color(0xFF22C55E); // vert
  static const Color categoryEvent = Color(0xFF8B5CF6); // violet

  static const light = AppColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF020817),
    card: Color(0xFFFFFFFF),
    popover: Color(0xFFFFFFFF),
    primary: Color(0xFF0F172A),
    primaryForeground: Color(0xFFF8FAFC),
    secondary: Color(0xFFF1F5F9),
    secondaryForeground: Color(0xFF0F172A),
    muted: Color(0xFFF1F5F9),
    mutedForeground: Color(0xFF64748B),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFF8FAFC),
    border: Color(0xFFE2E8F0),
    input: Color(0xFFE2E8F0),
    ring: Color(0xFF020817),
    success: Color(0xFF16A34A),
    warning: Color(0xFFF97316),
  );

  static const dark = AppColors(
    background: Color(0xFF181C25),
    foreground: Color(0xFFDCDFE5),
    card: Color(0xFF212631),
    popover: Color(0xFF1D212B),
    primary: brandOrange,
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF2E3442),
    secondaryForeground: Color(0xFFDCDFE5),
    muted: Color(0xFF2E3442),
    mutedForeground: Color(0xFF89909F),
    destructive: Color(0xFFC32222),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF383E4D),
    input: Color(0xFF2A2F3C),
    ring: brandOrange,
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFB923C),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? foreground,
    Color? card,
    Color? popover,
    Color? primary,
    Color? primaryForeground,
    Color? secondary,
    Color? secondaryForeground,
    Color? muted,
    Color? mutedForeground,
    Color? destructive,
    Color? destructiveForeground,
    Color? border,
    Color? input,
    Color? ring,
    Color? success,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      card: card ?? this.card,
      popover: popover ?? this.popover,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      secondary: secondary ?? this.secondary,
      secondaryForeground: secondaryForeground ?? this.secondaryForeground,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      destructive: destructive ?? this.destructive,
      destructiveForeground:
          destructiveForeground ?? this.destructiveForeground,
      border: border ?? this.border,
      input: input ?? this.input,
      ring: ring ?? this.ring,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      foreground: Color.lerp(foreground, other.foreground, t)!,
      card: Color.lerp(card, other.card, t)!,
      popover: Color.lerp(popover, other.popover, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryForeground:
          Color.lerp(secondaryForeground, other.secondaryForeground, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground: Color.lerp(mutedForeground, other.mutedForeground, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      destructiveForeground:
          Color.lerp(destructiveForeground, other.destructiveForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      input: Color.lerp(input, other.input, t)!,
      ring: Color.lerp(ring, other.ring, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
}
