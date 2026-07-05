import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mon_repas_client_mobile/core/utils/dates.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  final now = DateTime(2026, 7, 10, 14, 0);

  test("moins d'une minute → à l'instant", () {
    expect(
      relativeTime(DateTime(2026, 7, 10, 13, 59, 30), now: now),
      "à l'instant",
    );
  });

  test('minutes', () {
    expect(
      relativeTime(DateTime(2026, 7, 10, 13, 45), now: now),
      'il y a 15 min',
    );
  });

  test('heures (même jour)', () {
    expect(
      relativeTime(DateTime(2026, 7, 10, 9, 0), now: now),
      'il y a 5 h',
    );
  });

  test('hier', () {
    expect(relativeTime(DateTime(2026, 7, 9, 20, 0), now: now), 'hier');
  });

  test('plus ancien → date complète', () {
    expect(
      relativeTime(DateTime(2026, 7, 1, 10, 0), now: now),
      '1 juillet 2026',
    );
  });
}
