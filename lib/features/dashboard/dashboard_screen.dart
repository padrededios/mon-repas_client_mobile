import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/reservation.dart';
import '../../data/providers.dart';
import '../../shared/widgets/week_nav_header.dart';
import 'edit_reservation_sheet.dart';
import 'week_agenda.dart';

/// Accueil : vue hebdomadaire des commandes. Par défaut repas (bleu) et
/// événements (violet) ; le bouton bascule affiche les doggybags (vert).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime _anchor = DateTime.now();
  DashboardMode _mode = DashboardMode.mealsAndEvents;

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
    // Revenir sur l'onglet Accueil ramène toujours à la semaine en cours.
    ref.listen<int>(homeTabIndexProvider, (previous, next) {
      if (next == 0 && previous != 0) {
        setState(() => _anchor = DateTime.now());
      }
    });

    final colors = context.appColors;
    final user = ref.watch(authProvider.select((s) => s.user));
    final reservations = ref.watch(myReservationsProvider);
    final doggyBags = ref.watch(myDoggyBagReservationsProvider);
    final events = ref.watch(myEventReservationsProvider);
    final days = weekDays(_anchor);
    final today = DateTime.now();

    final meals = reservations.valueOrNull ?? [];
    final bags = doggyBags.valueOrNull ?? [];
    final eventRes = events.valueOrNull ?? [];

    final upcomingCount = meals
        .where((r) =>
            !r.isCancelled &&
            r.dailyMenu != null &&
            !isDayPast(r.dailyMenu!.date))
        .length;

    final showDoggyBags = _mode == DashboardMode.doggyBags;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // --- Bienvenue + raccourcis ---
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickLink(
                          icon: Icons.restaurant_menu,
                          label: 'Réserver',
                          color: AppColors.categoryMeal,
                          onTap: () => ref
                              .read(homeTabIndexProvider.notifier)
                              .state = 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickLink(
                          icon: Icons.inventory_2,
                          label: 'DoggyBag',
                          color: AppColors.categoryDoggyBag,
                          onTap: () => ref
                              .read(homeTabIndexProvider.notifier)
                              .state = 2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickLink(
                          icon: Icons.auto_awesome,
                          label: 'Événements',
                          color: AppColors.categoryEvent,
                          onTap: () => ref
                              .read(homeTabIndexProvider.notifier)
                              .state = 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Navigation semaine ---
          WeekNavHeader(
            anchor: _anchor,
            onPrevious: () => setState(() => _anchor = addWeeks(_anchor, -1)),
            onNext: () => setState(() => _anchor = addWeeks(_anchor, 1)),
          ),
          const SizedBox(height: 8),

          // --- Bascule repas & événements / doggybags ---
          SegmentedButton<DashboardMode>(
            segments: const [
              ButtonSegment(
                value: DashboardMode.mealsAndEvents,
                icon: Icon(Icons.restaurant_menu, size: 18),
                label: Text('Repas & événements'),
              ),
              ButtonSegment(
                value: DashboardMode.doggyBags,
                icon: Icon(Icons.inventory_2, size: 18),
                label: Text('DoggyBags'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            style: ButtonStyle(
              // Le segment actif prend la couleur de sa catégorie.
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (!states.contains(WidgetState.selected)) return null;
                final accent = showDoggyBags
                    ? AppColors.categoryDoggyBag
                    : AppColors.categoryMeal;
                return accent.withValues(alpha: 0.16);
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (!states.contains(WidgetState.selected)) {
                  return colors.mutedForeground;
                }
                return showDoggyBags
                    ? AppColors.categoryDoggyBag
                    : AppColors.categoryMeal;
              }),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 10),
              ),
              visualDensity: VisualDensity.compact,
            ),
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 12),

          // --- Jours ---
          ...days.map((day) {
            final agenda = agendaForDay(
              day: day,
              mode: _mode,
              meals: meals,
              doggyBags: bags,
              events: eventRes,
            );
            return _DaySection(
              day: day,
              isToday: isSameDay(day, today),
              isPast: isDayPast(day),
              mode: _mode,
              agenda: agenda,
              onEditMeal: _openEdit,
            );
          }),

          const SizedBox(height: 8),
          // --- Légende ---
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: showDoggyBags
                ? const [
                    _LegendDot(
                      color: AppColors.categoryDoggyBag,
                      label: 'DoggyBag',
                    ),
                  ]
                : const [
                    _LegendDot(color: AppColors.categoryMeal, label: 'Repas'),
                    _LegendDot(
                      color: AppColors.categoryEvent,
                      label: 'Événement',
                    ),
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

/// Tuile de lien rapide : icône dans une pastille de la couleur de la
/// catégorie (repas bleu / doggybag vert / événement violet), libellé dessous.
class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.isToday,
    required this.isPast,
    required this.mode,
    required this.agenda,
    required this.onEditMeal,
  });

  final DateTime day;
  final bool isToday;
  final bool isPast;
  final DashboardMode mode;
  final DayAgenda agenda;
  final void Function(Reservation) onEditMeal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
            if (agenda.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  mode == DashboardMode.doggyBags
                      ? 'Aucun doggybag'
                      : 'Rien de prévu',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              )
            else ...[
              ...agenda.meals.map((r) => _MiniCard(
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
              ...agenda.events.map((e) => _MiniCard(
                    color: AppColors.categoryEvent,
                    icon: Icons.auto_awesome,
                    title: e.specialEvent?.name ?? 'Événement',
                    subtitle: e.eventTimeSlot != null
                        ? '${formatTimeHm(e.eventTimeSlot!.startTime)} – ${formatTimeHm(e.eventTimeSlot!.endTime)}'
                        : '',
                  )),
              ...agenda.doggyBags.map((b) => _MiniCard(
                    color: AppColors.categoryDoggyBag,
                    icon: Icons.inventory_2,
                    title: b.dish?.name ?? 'DoggyBag',
                    subtitle: 'Quantité ×${b.quantity}',
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
