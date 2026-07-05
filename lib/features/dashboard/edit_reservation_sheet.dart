import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/dishes.dart';
import '../../data/models/daily_menu.dart';
import '../../data/models/reservation.dart';
import '../../data/providers.dart';
import '../../shared/widgets/async_states.dart';
import '../../shared/widgets/dish_option_card.dart';
import '../../shared/widgets/time_slot_tile.dart';
import 'edit_reservation_draft.dart';

/// Feuille d'édition d'une réservation (équivalent `EditReservationDialog`) :
/// recharge le menu complet, resynchronise l'état, PATCH partiel,
/// suppression avec confirmation. Renvoie `true` si la réservation a changé.
class EditReservationSheet extends ConsumerStatefulWidget {
  const EditReservationSheet({super.key, required this.reservation});

  final Reservation reservation;

  static Future<bool?> show(BuildContext context, Reservation reservation) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditReservationSheet(reservation: reservation),
    );
  }

  @override
  ConsumerState<EditReservationSheet> createState() =>
      _EditReservationSheetState();
}

class _EditReservationSheetState extends ConsumerState<EditReservationSheet> {
  EditReservationDraft? _draft;
  bool _isSubmitting = false;

  int? get _menuId =>
      widget.reservation.dailyMenu?.id ??
      widget.reservation.timeSlot?.dailyMenuId;

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null || !draft.hasChanges || !draft.isValid) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reservationsRepositoryProvider)
          .update(widget.reservation.id, draft.buildPatch());
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette réservation ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: context.appColors.destructive,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reservationsRepositoryProvider)
          .cancel(widget.reservation.id);
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
    final menuId = _menuId;
    if (menuId == null) {
      return const SizedBox(
        height: 200,
        child: ErrorState(message: 'Menu introuvable pour cette réservation'),
      );
    }
    final menuAsync = ref.watch(dailyMenuProvider(menuId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return menuAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(
            message:
                e is ApiException ? e.message : 'Impossible de charger le menu',
            onRetry: () => ref.invalidate(dailyMenuProvider(menuId)),
          ),
          data: (menu) {
            final draft = _draft ??=
                EditReservationDraft.fromReservation(widget.reservation, menu);
            return _buildContent(context, scrollController, menu, draft);
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScrollController scrollController,
    DailyMenu menu,
    EditReservationDraft draft,
  ) {
    final colors = context.appColors;
    final starters = getStarters(menu);
    final mains = getMainDishes(menu);
    final desserts = getDesserts(menu);
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
                      'Modifier ma réservation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      formatDayLong(menu.date),
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
              if (starters.isNotEmpty) ...[
                _sectionTitle(context, 'Entrée'),
                ...starters.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DishOptionCard(
                        dish: d,
                        selected: draft.starter?.id == d.id,
                        allowWhenSoldOut: draft.isCurrentDish(d),
                        onTap: () => setState(
                          () => _draft = draft.toggleStarter(d),
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              _sectionTitle(context, 'Plat'),
              ...mains.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DishOptionCard(
                      dish: d,
                      selected: draft.mainDish?.id == d.id,
                      allowWhenSoldOut: draft.isCurrentDish(d),
                      onTap: () => setState(
                        () => _draft = draft.toggleMainDish(d),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              if (desserts.isNotEmpty) ...[
                _sectionTitle(context, 'Dessert'),
                ...desserts.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DishOptionCard(
                        dish: d,
                        selected: draft.dessert?.id == d.id,
                        allowWhenSoldOut: draft.isCurrentDish(d),
                        onTap: () => setState(
                          () => _draft = draft.toggleDessert(d),
                        ),
                      ),
                    )),
                const SizedBox(height: 8),
              ],
              _sectionTitle(context, 'Créneau'),
              _EditSlotPicker(menu: menu, draft: draft, onChanged: (d) {
                setState(() => _draft = d);
              }),
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
                    onPressed: _isSubmitting ? null : _delete,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: const Text('Supprimer'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
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

class _EditSlotPicker extends ConsumerWidget {
  const _EditSlotPicker({
    required this.menu,
    required this.draft,
    required this.onChanged,
  });

  final DailyMenu menu;
  final EditReservationDraft draft;
  final void Function(EditReservationDraft) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(menuTimeSlotsProvider(menu.id));
    return slotsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(
        message: e is ApiException
            ? e.message
            : 'Impossible de charger les créneaux',
        onRetry: () => ref.invalidate(menuTimeSlotsProvider(menu.id)),
      ),
      data: (slots) => Column(
        children: slots
            .map((slot) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TimeSlotTile(
                    slot: slot,
                    selected: draft.timeSlot?.id == slot.id,
                    isPast: isTimeSlotPast(menu.date, slot.endTime),
                    onTap: () => onChanged(draft.withTimeSlot(slot)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
