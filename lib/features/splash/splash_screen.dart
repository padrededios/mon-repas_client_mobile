import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';

/// Splash animé : reprend l'animation du logo de la landing page —
/// entrée avec rebond (logoEntrance) puis halo orange pulsant
/// (logoGlowDrop) sur fond sombre à dégradé radial.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static const logoKey = Key('splash-logo');

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _background = Color(0xFF0A0705);

  /// Intro : 1 s d'entrée du logo (0 → 56 %) puis révélation du titre.
  /// À la fin, le splash est marqué terminé et le router peut rediriger.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  /// Pulsation du halo : 3,5 s aller-retour, en boucle.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1750),
  );

  late final Animation<double> _logoPhase = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.56),
  );

  // Keyframes logoEntrance de la landing (globals.css) :
  // 0 %  → y -80, échelle 0.2, rotation -20°, opacité 0
  // 55 % → y +10, échelle 1.12, rotation +6°
  // 75 % → y -4,  échelle 0.93, rotation -3°
  // 90 % → y +2,  échelle 1.02, rotation +1°
  late final Animation<double> _logoY = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: -80, end: 10), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 10, end: -4), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -4, end: 2), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 10),
  ]).animate(_logoPhase);

  late final Animation<double> _logoScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.12), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.93), weight: 20),
    TweenSequenceItem(tween: Tween(begin: 0.93, end: 1.02), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 1.02, end: 1), weight: 10),
  ]).animate(_logoPhase);

  late final Animation<double> _logoAngle = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: -20, end: 6), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -3, end: 1), weight: 15),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 10),
  ]).animate(_logoPhase);

  late final Animation<double> _logoOpacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 55),
    TweenSequenceItem(tween: ConstantTween(1), weight: 45),
  ]).animate(_logoPhase);

  /// Titre + indicateur : fondu montant après l'atterrissage du logo.
  late final Animation<double> _titleReveal = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.5, 0.95, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        ref.read(splashCompletedProvider.notifier).state = true;
      }
    });
    _intro.forward();
    _glow.repeat(reverse: true);
  }

  @override
  void dispose() {
    _intro.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF45260F), Color(0xFF1C120A), _background],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_intro, _glow]),
                    builder: (context, _) {
                      final glow = Curves.easeInOut.transform(_glow.value);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo pulsant, atténué tant que le logo entre.
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.scale(
                              scale: 1 + 0.12 * glow,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.brandOrange.withValues(
                                        alpha: 0.28 + 0.30 * glow,
                                      ),
                                      AppColors.brandOrange.withValues(
                                        alpha: 0,
                                      ),
                                    ],
                                  ),
                                ),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: _logoOpacity.value,
                            child: Transform.translate(
                              offset: Offset(0, _logoY.value),
                              child: Transform.rotate(
                                angle: _logoAngle.value * math.pi / 180,
                                child: Transform.scale(
                                  scale: _logoScale.value,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    key: SplashScreen.logoKey,
                                    width: 210,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _titleReveal,
                  builder: (context, child) => Opacity(
                    opacity: _titleReveal.value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - _titleReveal.value)),
                      child: child,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Mon Repas',
                        style: AppTypography.brandTitleLarge
                            .copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
