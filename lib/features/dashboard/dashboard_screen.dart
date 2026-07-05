import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/doggybag_reservation.dart';
import '../../data/models/event_reservation.dart';
import '../../data/models/reservation.dart';
import '../../data/providers.dart';
import 'edit_reservation_sheet.dart';

/// Accueil : hero de bienvenue + calendrier hebdomadaire des commandes
/// (repas bleu / doggybag vert / événement violet), navigation semaine.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _anchor = DateTime.now();

  Future<void> _refresh() async {
    ref.invalidate(myReservationsProvider);
    ref.invalidate(myDoggyBagReservationsProvider);
    ref.invalidate(myEventReservationsProvider);
  }

  Future<void> _openEdit(Reservation reservation) async {
    final changed = await EditReservationSheet.show(context, reservation);
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Réservation mise à jour'),
          backgroundColor: context.appColors.success,
        ),
      );
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = ref.watch(authProvider.select((s) => s.user));
    final reservations = ref.watch(myReservationsProvider);
    final doggyBags = ref.watch(myDoggyBagReservationsProvider);
    final events = ref.watch(myEventReservationsProvider);
    final days = weekDays(_anchor);
    final today = DateTime.now();

    final meals = (reservations.valueOrNull ?? [])
        .where((r) => !r.isCancelled)
        .toList();
    final bags = (doggyBags.valueOrNull ?? [])
        .where((r) => r.status == DoggyBagStatus.confirmed)
        .toList();
    final eventRes = (events.valueOrNull ?? [])
        .where((r) => !r.isCancelled)
        .toList();

    final upcomingCount = meals
        .where((r) =>
            r.dailyMenu != null && !isDayPast(r.dailyMenu!.date))
        .length;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // --- Hero ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toBeginningOfSentenceCase(formatDayLong(today)),
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bonjour ${user?.firstName ?? ''} !',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    upcomingCount > 0
                        ? '$upcomingCount réservation${upcomingCount > 1 ? 's' : ''} active${upcomingCount > 1 ? 's' : ''} à venir'
                        : 'Aucune réservation à venir — réservez votre prochain repas !',
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ShortcutChip(
                        icon: Icons.calendar_month,
                        label: 'Réserver',
                        onTap: () => ref
                            .read(homeTabIndexProvider.notifier)
                            .state = 1,
                      ),
                      _ShortcutChip(
                        icon: Icons.inventory_2,
                        label: 'DoggyBag',
                        onTap: () => ref
                            .read(homeTabIndexProvider.notifier)
                            .state = 2,
                      ),
                      _ShortcutChip(
                        icon: Icons.auto_awesome,
                        label: 'Événements',
                        onTap: () => ref
                            .read(homeTabIndexProvider.notifier)
                            .state = 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Navigation semaine ---
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mes commandes de la semaine',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    setState(() => _anchor = addWeeks(_anchor, -1)),
              ),
              TextButton(
                onPressed: () => setState(() => _anchor = DateTime.now()),
                child: const Text("Aujourd'hui"),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    setState(() => _anchor = addWeeks(_anchor, 1)),
              ),
            ],
          ),
          Text(
            'Semaine ${isoWeekNumber(_anchor)} • '
            '${DateFormat('d MMM', 'fr_FR').format(days.first)} – '
            '${DateFormat('d MMM', 'fr_FR').format(days.last)}',
            style: TextStyle(color: colors.mutedForeground, fontSize: 13),
          ),
          const SizedBox(height: 12),

          // --- Jours ---
          ...days.map((day) {
            final dayMeals = meals
                .where((r) =>
                    r.dailyMenu != null && isSameDay(r.dailyMenu!.date, day))
                .toList();
            final dayBags =
                bags.where((b) => isSameDay(b.pickupDate, day)).toList();
            final dayEvents = eventRes
                .where((e) =>
                    e.specialEvent != null &&
                    isSameDay(e.specialEvent!.eventDate, day))
                .toList();
            return _DaySection(
              day: day,
              isToday: isSameDay(day, today),
              isPast: isDayPast(day),
              meals: dayMeals,
              doggyBags: dayBags,
              events: dayEvents,
              onEditMeal: _openEdit,
            );
          }),

          const SizedBox(height: 8),
          // --- Légende ---
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: const [
              _LegendDot(color: AppColors.categoryMeal, label: 'Repas'),
              _LegendDot(color: AppColors.categoryDoggyBag, label: 'DoggyBag'),
              _LegendDot(color: AppColors.categoryEvent, label: 'Événement'),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(homeTabIndexProvider.notifier).state = 4,
              icon: const Icon(Icons.history, size: 18),
              label: const Text("Voir l'historique complet"),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.brandOrange),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.isToday,
    required this.isPast,
    required this.meals,
    required this.doggyBags,
    required this.events,
    required this.onEditMeal,
  });

  final DateTime day;
  final bool isToday;
  final bool isPast;
  final List<Reservation> meals;
  final List<DoggyBagReservation> doggyBags;
  final List<EventReservation> events;
  final void Function(Reservation) onEditMeal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEmpty = meals.isEmpty && doggyBags.isEmpty && events.isEmpty;
    final label = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'fr_FR').format(day),
    );

    return Opacity(
      opacity: isPast ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isToday)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.brandOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                    color: isToday ? colors.foreground : colors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  'Rien de prévu',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              ...meals.map((r) => _MiniCard(
                    color: AppColors.categoryMeal,
                    icon: Icons.restaurant,
                    title: r.dish?.name ?? 'Repas',
                    subtitle: [
                      if (r.starter != null) 'Entrée : ${r.starter!.name}',
                      if (r.dessert != null) 'Dessert : ${r.dessert!.name}',
                      if (r.timeSlot != null)
                        '${formatTimeHm(r.timeSlot!.startTime)} – ${formatTimeHm(r.timeSlot!.endTime)}',
                    ].join(' • '),
                    trailing: isPast ? null : Icons.edit_outlined,
                    onTap: isPast ? null : () => onEditMeal(r),
                  )),
              ...doggyBags.map((b) => _MiniCard(
                    color: AppColors.categoryDoggyBag,
                    icon: Icons.inventory_2,
                    title: b.dish?.name ?? 'DoggyBag',
                    subtitle: 'Quantité ×${b.quantity}',
                  )),
              ...events.map((e) => _MiniCard(
                    color: AppColors.categoryEvent,
                    icon: Icons.auto_awesome,
                    title: e.specialEvent?.name ?? 'Événement',
                    subtitle: e.eventTimeSlot != null
                        ? '${formatTimeHm(e.eventTimeSlot!.startTime)} – ${formatTimeHm(e.eventTimeSlot!.endTime)}'
                        : '',
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: color, width: 4)),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: colors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  Icon(trailing, size: 18, color: colors.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: context.appColors.mutedForeground,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
