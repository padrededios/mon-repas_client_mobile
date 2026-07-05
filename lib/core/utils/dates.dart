import 'package:intl/intl.dart';

/// Portage de `mon-repas_client/src/lib/utils/date.ts`.
///
/// Toutes les fonctions dépendantes de l'horloge acceptent un `now` injectable
/// pour être testables ; par défaut `DateTime.now()`.

/// Extrait le jour (année/mois/jour, heure locale) d'une date API.
///
/// L'API renvoie tantôt `YYYY-MM-DD`, tantôt un ISO complet avec fuseau ;
/// on ne garde que les 10 premiers caractères pour éviter tout décalage
/// de jour lié à la conversion UTC → local.
DateTime parseDay(String value) {
  final day = value.length > 10 ? value.substring(0, 10) : value;
  final parts = day.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

String toIsoDateString(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

/// "12:00:00" → "12:00"
String formatTimeHm(String time) => time.length > 5 ? time.substring(0, 5) : time;

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Strictement avant aujourd'hui.
bool isDayPast(DateTime date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  return _startOfDay(date).isBefore(_startOfDay(ref));
}

/// Jour antérieur = passé ; aujourd'hui = compare l'heure de fin à maintenant.
bool isTimeSlotPast(DateTime date, String endTime, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  if (isDayPast(date, now: ref)) return true;
  if (!isSameDay(date, ref)) return false;
  final parts = endTime.split(':');
  final end = DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
  return end.isBefore(ref);
}

/// Un menu du jour est « passé » après la fin du dernier créneau (14:00).
bool areAllSlotsPast(DateTime date, {String latestEndTime = '14:00', DateTime? now}) {
  return isTimeSlotPast(date, latestEndTime, now: now);
}

/// Numéro de semaine ISO 8601 (semaine du jeudi).
///
/// Calculé en UTC : en heure locale, `difference().inDays` perdrait une
/// heure entre une date en heure d'hiver et une en heure d'été.
int isoWeekNumber(DateTime date) {
  final thursday =
      DateTime.utc(date.year, date.month, date.day + (4 - date.weekday));
  final firstDayOfYear = DateTime.utc(thursday.year, 1, 1);
  return thursday.difference(firstDayOfYear).inDays ~/ 7 + 1;
}

/// Année ISO de la semaine (celle de son jeudi).
int isoWeekYear(DateTime date) {
  return DateTime(date.year, date.month, date.day + (4 - date.weekday)).year;
}

/// Lundi → vendredi de la semaine contenant [anchor].
List<DateTime> weekDays(DateTime anchor) {
  final monday = DateTime(anchor.year, anchor.month, anchor.day - (anchor.weekday - 1));
  return List.generate(
    5,
    (i) => DateTime(monday.year, monday.month, monday.day + i),
  );
}

DateTime addWeeks(DateTime date, int weeks) =>
    DateTime(date.year, date.month, date.day + 7 * weeks);

/// « vendredi 10 juillet 2026 » — nécessite initializeDateFormatting('fr_FR').
String formatDayLong(DateTime date) =>
    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);

/// « ven. 10 juil. »
String formatDayShort(DateTime date) =>
    DateFormat('EEE d MMM', 'fr_FR').format(date);

/// « 10 juillet 2026 »
String formatDateMedium(DateTime date) =>
    DateFormat('d MMMM yyyy', 'fr_FR').format(date);

/// Horodatage relatif fr : « à l'instant », « il y a 5 min », « il y a 3 h »,
/// « hier », sinon la date.
String relativeTime(DateTime date, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(date);
  if (diff.inSeconds < 60) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24 && isSameDay(date, ref)) {
    return 'il y a ${diff.inHours} h';
  }
  final yesterday = DateTime(ref.year, ref.month, ref.day - 1);
  if (isSameDay(date, yesterday)) return 'hier';
  return formatDateMedium(date);
}
