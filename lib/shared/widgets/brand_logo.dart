import 'package:flutter/material.dart';

/// Logo Mon-Repas : version claire ou blanche selon le thème actif.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 48});

  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? 'assets/images/logo-white.png' : 'assets/images/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
