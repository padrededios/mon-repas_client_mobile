import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/realtime/socket_service.dart';
import '../core/storage/session_storage.dart';
import '../features/auth/auth_notifier.dart';
import '../features/doggybag/doggybag_cart.dart';
import '../features/notifications/notifications_notifier.dart';
import 'models/daily_menu.dart';
import 'models/dish.dart';
import 'models/doggybag_reservation.dart';
import 'models/event_reservation.dart';
import 'models/reservation.dart';
import 'models/special_event.dart';
import 'models/time_slot.dart';
import 'repositories/auth_repository.dart';
import 'repositories/daily_menus_repository.dart';
import 'repositories/doggybag_repository.dart';
import 'repositories/reservations_repository.dart';
import 'repositories/special_events_repository.dart';
import 'repositories/time_slots_repository.dart';

/// Tous les providers Riverpod de l'app, centralisés (pattern stepzy_mobile).

// Types explicites : apiClientProvider et authProvider se référencent
// mutuellement (handler 401), l'inférence seule serait circulaire.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  // Session expirée (401) → purge locale + retour login via le redirect.
  client.onUnauthorized = () {
    ref.read(authProvider.notifier).forceLogout();
  };
  return client;
});

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(sessionStorageProvider),
  );
});

final StateNotifierProvider<AuthNotifier, AuthState> authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});


// --- Menus & réservations -------------------------------------------------

final dailyMenusRepositoryProvider = Provider<DailyMenusRepository>((ref) {
  return DailyMenusRepository(ref.watch(apiClientProvider));
});

final timeSlotsRepositoryProvider = Provider<TimeSlotsRepository>((ref) {
  return TimeSlotsRepository(ref.watch(apiClientProvider));
});

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(apiClientProvider));
});

/// Menus d'une semaine ISO. 404 = menu pas encore publié (géré par l'UI).
final weekMenusProvider = FutureProvider.autoDispose
    .family<List<DailyMenu>, ({int week, int year})>((ref, key) {
  return ref
      .watch(dailyMenusRepositoryProvider)
      .getWeek(key.week, key.year);
});

/// Menu complet par id (feuille de composition / édition).
final dailyMenuProvider =
    FutureProvider.autoDispose.family<DailyMenu, int>((ref, id) {
  return ref.watch(dailyMenusRepositoryProvider).getById(id);
});

/// Créneaux d'un menu — invalidé toutes les 30 s par l'UI qui l'affiche.
final menuTimeSlotsProvider =
    FutureProvider.autoDispose.family<List<TimeSlot>, int>((ref, menuId) {
  return ref.watch(timeSlotsRepositoryProvider).getByMenuId(menuId);
});

final myReservationsProvider =
    FutureProvider.autoDispose<List<Reservation>>((ref) {
  return ref.watch(reservationsRepositoryProvider).getMine();
});

// --- DoggyBag & événements --------------------------------------------------

final doggyBagRepositoryProvider = Provider<DoggyBagRepository>((ref) {
  return DoggyBagRepository(ref.watch(apiClientProvider));
});

final specialEventsRepositoryProvider =
    Provider<SpecialEventsRepository>((ref) {
  return SpecialEventsRepository(ref.watch(apiClientProvider));
});

final myDoggyBagReservationsProvider =
    FutureProvider.autoDispose<List<DoggyBagReservation>>((ref) {
  return ref.watch(doggyBagRepositoryProvider).getMine();
});

final myEventReservationsProvider =
    FutureProvider.autoDispose<List<EventReservation>>((ref) {
  return ref.watch(specialEventsRepositoryProvider).getMyReservations();
});

final activeEventsProvider =
    FutureProvider.autoDispose<List<SpecialEvent>>((ref) {
  return ref.watch(specialEventsRepositoryProvider).getActive();
});

final specialEventProvider =
    FutureProvider.autoDispose.family<SpecialEvent, int>((ref, id) {
  return ref.watch(specialEventsRepositoryProvider).getById(id);
});

/// Plats doggybag disponibles pour un jour (clé = date à minuit).
final doggyBagAvailableProvider =
    FutureProvider.autoDispose.family<List<Dish>, DateTime>((ref, date) {
  return ref.watch(doggyBagRepositoryProvider).getAvailableDishes(date);
});

/// Panier doggybag (local à la session).
final doggyBagCartProvider = StateNotifierProvider<DoggyBagCartNotifier,
    List<DoggyBagCartItem>>((ref) {
  return DoggyBagCartNotifier();
});

// --- Temps réel & notifications ---------------------------------------------

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
});

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

// --- Navigation interne -----------------------------------------------------

/// Onglet actif du HomeShell (piloté aussi par les raccourcis du dashboard).
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
