import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/event_time_slot.dart';
import '../../data/models/special_event.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/time_slot_tile.dart';

/// Détail d'un événement spécial : image, menu « X ou Y », créneaux,
/// inscription (clôturée après la fin de journée de la deadline).
class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  EventTimeSlot? _selectedSlot;
  bool _isSubmitting = false;

  Future<void> _confirm(SpecialEvent event) async {
    final slot = _selectedSlot;
    if (slot == null) return;
    // La clôture est re-vérifiée juste avant l'envoi (parité webapp).
    if (event.isRegistrationClosed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Les inscriptions sont clôturées.'),
          backgroundColor: context.appColors.destructive,
        ),
      );
      setState(() => _selectedSlot = null);
      ref.invalidate(specialEventProvider(widget.eventId));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(specialEventsRepositoryProvider).createReservation(
            specialEventId: event.id,
            eventTimeSlotId: slot.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inscription confirmée !'),
          backgroundColor: context.appColors.success,
        ),
      );
      ref.invalidate(myEventReservationsProvider);
      ref.invalidate(specialEventProvider(widget.eventId));
      setState(() => _selectedSlot = null);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.appColors.destructive,
        ),
      );
      ref.invalidate(specialEventProvider(widget.eventId));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final eventAsync = ref.watch(specialEventProvider(widget.eventId));
    final myReservations =
        ref.watch(myEventReservationsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Événement')),
      body: eventAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e is ApiException ? e.message : 'Erreur de chargement',
          onRetry: () => ref.invalidate(specialEventProvider(widget.eventId)),
        ),
        data: (event) {
          final isReserved = myReservations
              .any((r) => !r.isCancelled && r.specialEventId == event.id);
          final past = isDayPast(event.eventDate);
          final closed = event.isRegistrationClosed();
          final canRegister = !past && !closed && !isReserved;
          final slots = event.timeSlots ?? [];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (event.imageUrl != null)
                Image.network(
                  event.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholder(),
                )
              else
                _placeholder(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        const StatusBadge(
                          'Événement spécial',
                          variant: BadgeVariant.special,
                        ),
                        if (past)
                          const StatusBadge(
                            'Passé',
                            variant: BadgeVariant.secondary,
                          )
                        else if (closed)
                          const StatusBadge(
                            'Clôturé',
                            variant: BadgeVariant.destructive,
                          ),
                        if (isReserved)
                          const StatusBadge(
                            'Réservé ✓',
                            variant: BadgeVariant.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      toBeginningOfSentenceCase(
                        formatDayLong(event.eventDate),
                      ),
                      style: TextStyle(color: colors.mutedForeground),
                    ),
                    if (event.registrationDeadline != null && !past) ...[
                      const SizedBox(height: 4),
                      Text(
                        closed
                            ? 'Inscriptions clôturées'
                            : 'Inscriptions jusqu\'au ${formatDateMedium(event.registrationDeadline!)}',
                        style: TextStyle(
                          color:
                              closed ? colors.destructive : colors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (event.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(event.description),
                    ],
                    const SizedBox(height: 20),
                    _MenuSection(event: event),
                    const SizedBox(height: 20),
                    if (closed && !past)
                      Card(
                        color: colors.destructive.withValues(alpha: 0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock,
                                  color: colors.destructive),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Les inscriptions sont clôturées pour cet événement.',
                                  style:
                                      TextStyle(color: colors.destructive),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (!past && slots.isNotEmpty) ...[
                      Text(
                        'Créneaux',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      ...slots.map((slot) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TimeSlotTile(
                              startTime: slot.startTime,
                              endTime: slot.endTime,
                              capacity: slot.capacity,
                              reservedCount: slot.reservedCount,
                              selected: _selectedSlot?.id == slot.id,
                              isPast: isTimeSlotPast(
                                event.eventDate,
                                slot.endTime,
                              ),
                              accentColor: AppColors.categoryEvent,
                              onTap: canRegister
                                  ? () => setState(() => _selectedSlot =
                                      _selectedSlot?.id == slot.id
                                          ? null
                                          : slot)
                                  : () {},
                            ),
                          )),
                      if (canRegister && _selectedSlot != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.categoryEvent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed:
                                _isSubmitting ? null : () => _confirm(event),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Confirmer la réservation'),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppColors.categoryEvent.withValues(alpha: 0.15),
      child: const Icon(
        Icons.auto_awesome,
        size: 48,
        color: AppColors.categoryEvent,
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.event});

  final SpecialEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    String? pair(String? a, String? b) {
      if (a != null && b != null) return '$a ou $b';
      return a ?? b;
    }

    final starter = pair(event.starter1, event.starter2);
    final main = pair(event.mainDish1, event.mainDish2);
    final dessert = pair(event.dessert1, event.dessert2);
    if (starter == null && main == null && dessert == null) {
      return const SizedBox.shrink();
    }

    Widget line(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: colors.mutedForeground),
              const SizedBox(width: 8),
              Text(
                '$label : ',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 13,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu de l\'événement',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (starter != null) line(Icons.local_dining, 'Entrée', starter),
            if (main != null) line(Icons.restaurant, 'Plat principal', main),
            if (dessert != null)
              line(Icons.icecream_outlined, 'Dessert', dessert),
          ],
        ),
      ),
    );
  }
}
