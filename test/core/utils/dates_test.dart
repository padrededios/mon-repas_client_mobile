import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/utils/dates.dart';

void main() {
  // Un vendredi à 13h00 — semaine ISO 28 de 2026.
  final now = DateTime(2026, 7, 10, 13, 0);

  group('parseDay', () {
    test('parse une date simple YYYY-MM-DD', () {
      expect(parseDay('2026-07-10'), DateTime(2026, 7, 10));
    });

    test('ignore la partie horaire (y compris UTC) pour ne garder que le jour',
        () {
      expect(parseDay('2026-07-10T00:00:00.000Z'), DateTime(2026, 7, 10));
      expect(parseDay('2026-07-10T22:30:00+02:00'), DateTime(2026, 7, 10));
    });
  });

  group('toIsoDateString', () {
    test('formate en YYYY-MM-DD avec zéros', () {
      expect(toIsoDateString(DateTime(2026, 7, 4)), '2026-07-04');
      expect(toIsoDateString(DateTime(2026, 11, 23)), '2026-11-23');
    });
  });

  group('formatTimeHm', () {
    test('tronque les secondes', () {
      expect(formatTimeHm('12:00:00'), '12:00');
      expect(formatTimeHm('09:30'), '09:30');
    });
  });

  group('isDayPast', () {
    test('hier est passé', () {
      expect(isDayPast(DateTime(2026, 7, 9), now: now), isTrue);
    });

    test("aujourd'hui n'est pas passé", () {
      expect(isDayPast(DateTime(2026, 7, 10), now: now), isFalse);
    });

    test("demain n'est pas passé", () {
      expect(isDayPast(DateTime(2026, 7, 11), now: now), isFalse);
    });
  });

  group('isTimeSlotPast', () {
    test('jour antérieur → passé quel que soit le créneau', () {
      expect(isTimeSlotPast(DateTime(2026, 7, 9), '23:59', now: now), isTrue);
    });

    test('jour futur → jamais passé', () {
      expect(isTimeSlotPast(DateTime(2026, 7, 11), '12:00', now: now), isFalse);
    });

    test("aujourd'hui : créneau fini (12:30 < 13:00) → passé", () {
      expect(isTimeSlotPast(DateTime(2026, 7, 10), '12:30', now: now), isTrue);
    });

    test("aujourd'hui : créneau pas fini (13:30 > 13:00) → pas passé", () {
      expect(isTimeSlotPast(DateTime(2026, 7, 10), '13:30', now: now), isFalse);
    });

    test('gère le format HH:MM:SS', () {
      expect(
        isTimeSlotPast(DateTime(2026, 7, 10), '12:30:00', now: now),
        isTrue,
      );
    });
  });

  group('areAllSlotsPast', () {
    test("aujourd'hui à 13h00 : service pas fini (14:00) → false", () {
      expect(areAllSlotsPast(DateTime(2026, 7, 10), now: now), isFalse);
    });

    test("aujourd'hui à 14h30 : service fini → true", () {
      final after = DateTime(2026, 7, 10, 14, 30);
      expect(areAllSlotsPast(DateTime(2026, 7, 10), now: after), isTrue);
    });

    test('jour passé → true', () {
      expect(areAllSlotsPast(DateTime(2026, 7, 9), now: now), isTrue);
    });
  });

  group('semaine ISO', () {
    test('numéro de semaine standard', () {
      expect(isoWeekNumber(DateTime(2026, 7, 10)), 28);
      expect(isoWeekNumber(DateTime(2026, 7, 4)), 27);
    });

    test('1er janvier 2026 (jeudi) → semaine 1 de 2026', () {
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekYear(DateTime(2026, 1, 1)), 2026);
    });

    test('30 décembre 2024 (lundi) → semaine 1 de 2025', () {
      expect(isoWeekNumber(DateTime(2024, 12, 30)), 1);
      expect(isoWeekYear(DateTime(2024, 12, 30)), 2025);
    });

    test('1er janvier 2021 (vendredi) → semaine 53 de 2020', () {
      expect(isoWeekNumber(DateTime(2021, 1, 1)), 53);
      expect(isoWeekYear(DateTime(2021, 1, 1)), 2020);
    });
  });

  group('weekDays', () {
    test('retourne lundi → vendredi de la semaine du jour donné', () {
      final days = weekDays(DateTime(2026, 7, 10)); // vendredi
      expect(days.length, 5);
      expect(days.first, DateTime(2026, 7, 6)); // lundi
      expect(days.last, DateTime(2026, 7, 10)); // vendredi
    });

    test('un lundi retourne sa propre semaine', () {
      final days = weekDays(DateTime(2026, 7, 6));
      expect(days.first, DateTime(2026, 7, 6));
    });

    test('un dimanche appartient à la semaine commencée le lundi précédent',
        () {
      final days = weekDays(DateTime(2026, 7, 12));
      expect(days.first, DateTime(2026, 7, 6));
    });

    test('gère le passage de mois', () {
      final days = weekDays(DateTime(2026, 7, 1)); // mercredi
      expect(days.first, DateTime(2026, 6, 29));
      expect(days.last, DateTime(2026, 7, 3));
    });
  });

  group('addWeeks', () {
    test('avance et recule de N semaines', () {
      expect(addWeeks(DateTime(2026, 7, 10), 1), DateTime(2026, 7, 17));
      expect(addWeeks(DateTime(2026, 7, 10), -2), DateTime(2026, 6, 26));
    });
  });

  group('isSameDay', () {
    test('compare uniquement le jour', () {
      expect(
        isSameDay(DateTime(2026, 7, 10, 8), DateTime(2026, 7, 10, 22)),
        isTrue,
      );
      expect(isSameDay(DateTime(2026, 7, 10), DateTime(2026, 7, 11)), isFalse);
    });
  });
}
