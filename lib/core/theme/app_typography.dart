import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  /// Police du logo-texte « Mon Repas » (comme le header de la webapp).
  /// Réservée à la marque — le corps de texte reste en police système.
  static const String brandFontFamily = 'LuckiestGuy';

  static const TextStyle brandTitle = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: 22,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle brandTitleLarge = TextStyle(
    fontFamily: brandFontFamily,
    fontSize: 34,
    height: 1.2,
    letterSpacing: 0.5,
  );
}
