import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thèmes proposés dans la page profil : clair, sombre, système et « BD »
/// (style bande dessinée : papier crème, gros contours noirs, couleurs pop).
enum AppThemeChoice {
  system,
  light,
  dark,
  comic;

  /// Valeur persistée (clé 'theme', compatible avec les anciens 'light'/'dark').
  String get storageValue => switch (this) {
        AppThemeChoice.system => 'system',
        AppThemeChoice.light => 'light',
        AppThemeChoice.dark => 'dark',
        AppThemeChoice.comic => 'bd',
      };

  static AppThemeChoice fromStorage(String? value) => switch (value) {
        'light' => AppThemeChoice.light,
        'dark' => AppThemeChoice.dark,
        'bd' => AppThemeChoice.comic,
        _ => AppThemeChoice.system,
      };

  /// ThemeMode Material correspondant ; le thème BD est un thème clair.
  ThemeMode get themeMode => switch (this) {
        AppThemeChoice.system => ThemeMode.system,
        AppThemeChoice.dark => ThemeMode.dark,
        AppThemeChoice.light || AppThemeChoice.comic => ThemeMode.light,
      };
}

/// Choix de thème persisté (clé 'theme', comme le localStorage de la webapp).
/// Défaut : thème système.
class ThemeChoiceNotifier extends StateNotifier<AppThemeChoice> {
  ThemeChoiceNotifier() : super(AppThemeChoice.system);

  static const _key = 'theme';

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppThemeChoice.fromStorage(prefs.getString(_key));
  }

  Future<void> setChoice(AppThemeChoice choice) async {
    state = choice;
    final prefs = await SharedPreferences.getInstance();
    if (choice == AppThemeChoice.system) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, choice.storageValue);
    }
  }
}
