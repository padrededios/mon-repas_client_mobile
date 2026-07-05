import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../data/models/event_reservation.dart';
import '../../data/models/special_event.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/time_slot_tile.dart';
import '../events/event_dish_card.dart';
import 'edit_event_reservation_draft.dart';

/// Feuille d'édition d'une réservation d'événement : recharge l'événement
/// complet (plats + créneaux), PATCH partiel, annulation avec confirmation.
/// Renvoie `true` si la réservation a changé.
class EditEventReservationSheet extends ConsumerStatefulWidget {
  const EditEventReservationSheet({super.key, required this.reservation});

  final EventReservation reservation;

  static Future<bool?> show(
    BuildContext context,
    EventReservation reservation,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditEventReservationSheet(reservation: reservation),
    );
  }

  @override
  ConsumerState<EditEventReservationSheet> createState() =>
      _EditEventReservationSheetState();
}

class _EditEventReservationSheetState
    extends ConsumerState<EditEventReservationSheet> {
  EditEventReservationDraft? _draft;
  bool _isSubmitting = false;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !draft.hasChanges || !draft.isValid) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(specialEventsRepositoryProvider)
          .updateReservation(widget.reservation.id, draft.buildPatch());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Typiquement : « La fenêtre de modification est échue ».
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.appColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelReservation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler cette inscription ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Retour'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.destructive,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Annuler l\'inscription'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(specialEventsRepositoryProvider)
          .cancelReservation(widget.reservation.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.appColors.destructive,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync =
        ref.watch(specialEventProvider(widget.reservation.specialEventId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return eventAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            message: e is ApiException
                ? e.message
                : 'Impossible de charger l\'événement',
            onRetry: () => ref.invalidate(
              specialEventProvider(widget.reservation.specialEventId),
            ),
          ),
          data: (event) {
            final draft = _draft ??= EditEventReservationDraft.fromReservation(
              widget.reservation,
              event,
            );
            return _buildContent(context, scrollController, event, draft);
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    SpecialEvent event,
    EditEventReservationDraft draft,
  ) {
    final colors = context.appColors;
    final slots = event.timeSlots ?? [];
    final canSave = draft.hasChanges && draft.isValid && !_isSubmitting;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modifier mon inscription',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${event.name} • ${formatDateMedium(event.eventDate)}',
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (event.starters.isNotEmpty) ...[
                _sectionTitle(context, 'Entrée'),
                ...event.starters.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventDishOptionCard(
                        dish: d,
                        selected: draft.starter?.id == d.id,
                        onTap: () => setState(
                          () => _draft = draft.toggleStarter(d),
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              if (event.mainDishes.isNotEmpty) ...[
                _sectionTitle(context, 'Plat principal'),
                ...event.mainDishes.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventDishOptionCard(
                        dish: d,
                        selected: draft.mainDish?.id == d.id,
                        onTap: () => setState(
                          () => _draft = draft.toggleMainDish(d),
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              if (event.desserts.isNotEmpty) ...[
                _sectionTitle(context, 'Dessert'),
                ...event.desserts.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventDishOptionCard(
                        dish: d,
                        selected: draft.dessert?.id == d.id,
                        onTap: () => setState(
                          () => _draft = draft.toggleDessert(d),
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              if (slots.isNotEmpty) ...[
                _sectionTitle(context, 'Créneau'),
                ...slots.map((slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TimeSlotTile(
                        startTime: slot.startTime,
                        endTime: slot.endTime,
                        capacity: slot.capacity,
                        reservedCount: slot.reservedCount,
                        selected: draft.timeSlot?.id == slot.id,
                        isPast:
                            isTimeSlotPast(event.eventDate, slot.endTime),
                        accentColor: AppColors.categoryEvent,
                        onTap: () => setState(
                          () => _draft = draft.withTimeSlot(slot),
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.destructive,
                      side: BorderSide(color: colors.destructive),
                    ),
                    onPressed: _isSubmitting ? null : _cancelReservation,
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.categoryEvent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: canSave ? _save : null,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
