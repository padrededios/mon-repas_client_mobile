import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/theme/theme_choice_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hydrate lit les valeurs persistées (dont le thème BD)', () async {
    SharedPreferences.setMockInitialValues({'theme': 'bd'});
    final notifier = ThemeChoiceNotifier();
    await notifier.hydrate();
    expect(notifier.state, AppThemeChoice.comic);
  });

  test("hydrate reste compatible avec l'ancien stockage light/dark", () async {
    SharedPreferences.setMockInitialValues({'theme': 'dark'});
    final notifier = ThemeChoiceNotifier();
    await notifier.hydrate();
    expect(notifier.state, AppThemeChoice.dark);
  });

  test('hydrate sans valeur → thème système', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = ThemeChoiceNotifier();
    await notifier.hydrate();
    expect(notifier.state, AppThemeChoice.system);
  });

  test('setChoice persiste le choix, system supprime la clé', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = ThemeChoiceNotifier();

    await notifier.setChoice(AppThemeChoice.comic);
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme'), 'bd');
    expect(notifier.state, AppThemeChoice.comic);

    await notifier.setChoice(AppThemeChoice.system);
    prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme'), isNull);
  });

  test('le thème BD est un thème clair au sens Material', () {
    expect(AppThemeChoice.comic.themeMode, ThemeMode.light);
    expect(AppThemeChoice.dark.themeMode, ThemeMode.dark);
    expect(AppThemeChoice.system.themeMode, ThemeMode.system);
  });
}
