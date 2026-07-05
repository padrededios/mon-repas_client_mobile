import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/dates.dart';
import '../../data/models/doggybag_reservation.dart';
import '../../data/models/notification_item.dart';
import '../../data/models/notification_preferences.dart';
import '../../data/models/reservation.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.preferences = const NotificationPreferences(),
  });

  final List<NotificationItem> items;
  final NotificationPreferences preferences;

  NotificationsState copyWith({
    List<NotificationItem>? items,
    NotificationPreferences? preferences,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      preferences: preferences ?? this.preferences,
    );
  }
}

/// Centre de notifications in-app : persistance locale (max 50), préférences
/// par type, rappels du jour au démarrage avec déduplication quotidienne.
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(const NotificationsState());

  static const _itemsKey = 'notifications';
  static const _prefsKey = 'notification-preferences';
  static const _reminderKeyPrefix = 'daily-reminders-';
  static const _maxItems = 50;

  int _idCounter = 0;

  int get unreadCount => state.items.where((n) => !n.read).length;

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getString(_itemsKey);
    final rawPrefs = prefs.getString(_prefsKey);
    state = NotificationsState(
      items: rawItems != null
          ? (jsonDecode(rawItems) as List<dynamic>)
              .map((e) =>
                  NotificationItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      preferences: rawPrefs != null
          ? NotificationPreferences.fromJson(
              jsonDecode(rawPrefs) as Map<String, dynamic>)
          : const NotificationPreferences(),
    );
  }

  Future<void> add({
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    // Filtrage par préférence à l'ajout (comme la webapp).
    if (!state.preferences.isEnabled(type)) return;
    final now = DateTime.now();
    final item = NotificationItem(
      id: '${now.microsecondsSinceEpoch}-${_idCounter++}',
      type: type,
      title: title,
      message: message,
      read: false,
      createdAt: now,
      data: data,
    );
    final items = [item, ...state.items];
    state = state.copyWith(
      items: items.length > _maxItems ? items.sublist(0, _maxItems) : items,
    );
    await _persistItems();
  }

  Future<void> markRead(String id) async {
    state = state.copyWith(
      items: [
        for (final n in state.items)
          if (n.id == id) n.copyWith(read: true) else n,
      ],
    );
    await _persistItems();
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      items: [for (final n in state.items) n.copyWith(read: true)],
    );
    await _persistItems();
  }

  Future<void> remove(String id) async {
    state = state.copyWith(
      items: state.items.where((n) => n.id != id).toList(),
    );
    await _persistItems();
  }

  Future<void> clearAll() async {
    state = state.copyWith(items: const []);
    await _persistItems();
  }

  Future<void> setPreference(NotificationType type, bool enabled) async {
    state = state.copyWith(
      preferences: state.preferences.withType(type, enabled),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.preferences.toJson()));
  }

  /// Rappels du jour au premier lancement authentifié (déduplication par clé
  /// datée, purge des clés des jours précédents).
  Future<void> emitStartupReminders({
    required List<Reservation> meals,
    required List<DoggyBagReservation> doggyBags,
    DateTime? now,
  }) async {
    final ref = now ?? DateTime.now();
    final key = '$_reminderKeyPrefix${toIsoDateString(ref)}';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;

    // Purge des clés de rappel des jours précédents.
    for (final k in prefs.getKeys().toList()) {
      if (k.startsWith(_reminderKeyPrefix) && k != key) {
        await prefs.remove(k);
      }
    }
    await prefs.setBool(key, true);

    final todaysMeals = meals.where((r) =>
        !r.isCancelled &&
        r.dailyMenu != null &&
        isSameDay(r.dailyMenu!.date, ref));
    for (final meal in todaysMeals) {
      final slot = meal.timeSlot;
      await add(
        type: NotificationType.mealReminder,
        title: 'Repas réservé aujourd\'hui',
        message: [
          if (meal.dish != null) meal.dish!.name,
          if (slot != null)
            '${formatTimeHm(slot.startTime)} – ${formatTimeHm(slot.endTime)}',
        ].join(' • '),
      );
    }

    final todaysBags = doggyBags.where((b) =>
        b.status == DoggyBagStatus.confirmed && isSameDay(b.pickupDate, ref));
    for (final bag in todaysBags) {
      await add(
        type: NotificationType.doggybagReminder,
        title: 'DoggyBag à récupérer aujourd\'hui',
        message:
            '${bag.dish?.name ?? 'Votre plat'} ×${bag.quantity} — pensez à passer avant la limite !',
      );
    }
  }

  Future<void> _persistItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _itemsKey,
      jsonEncode(state.items.map((n) => n.toJson()).toList()),
    );
  }
}
