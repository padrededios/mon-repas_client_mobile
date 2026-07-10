import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers.dart';
import '../../shared/widgets/brand_logo.dart';
import '../dashboard/dashboard_screen.dart';
import '../doggybag/doggybag_screen.dart';
import '../events/events_screen.dart';
import '../menus/menus_screen.dart';
import '../notifications/notifications_panel.dart';
import '../notifications/realtime_mapping.dart';
import '../orders/orders_screen.dart';

/// Coquille principale : AppBar commune + 5 onglets (transposition mobile
/// de la navigation horizontale de la webapp).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  AppLifecycleListener? _lifecycleListener;
  late final _socket = ref.read(socketServiceProvider);

  @override
  void initState() {
    super.initState();
    // Temps réel : connecté tant que l'utilisateur est authentifié,
    // mis en pause quand l'app passe en arrière-plan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRealtime();
      _emitStartupReminders();
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        _socket.resume();
        // Les données ont pu bouger pendant la pause.
        ref.invalidate(myReservationsProvider);
        ref.invalidate(myDoggyBagReservationsProvider);
        ref.invalidate(myEventReservationsProvider);
      },
      onPause: _socket.pause,
    );
  }

  @override
  void dispose() {
    // Déconnexion au démontage (logout → retour au login).
    _socket.disconnect();
    _lifecycleListener?.dispose();
    super.dispose();
  }

  void _startRealtime() {
    final token = ref.read(apiClientProvider).auth.token;
    if (token == null || token.isEmpty) return;
    _socket.connect(token: token, onEvent: _handleRealtimeEvent);
  }

  void _handleRealtimeEvent(String event, dynamic data) {
    if (!mounted) return;
    switch (event) {
      case 'menu:created' ||
            'menu:updated' ||
            'menu:deleted' ||
            'menu:status-changed' ||
            'menu:quantity-updated':
        ref.invalidate(weekMenusProvider);
        ref.invalidate(dailyMenuProvider);
      case 'reservation:new' ||
            'reservation:confirmed' ||
            'reservation:updated' ||
            'reservation:cancelled':
        ref.invalidate(myReservationsProvider);
        ref.invalidate(menuTimeSlotsProvider);
      case 'doggybag:availability-updated':
        ref.invalidate(doggyBagAvailableProvider);
      case 'doggybag:reservation-updated':
        ref.invalidate(myDoggyBagReservationsProvider);
        ref.invalidate(doggyBagAvailableProvider);
      case 'event:created' || 'event:timeslot-updated':
        ref.invalidate(activeEventsProvider);
        ref.invalidate(specialEventProvider);
      case 'event:reservation-confirmed':
        ref.invalidate(myEventReservationsProvider);
        ref.invalidate(specialEventProvider);
    }
    final notification = notificationForEvent(event, data);
    if (notification != null) {
      ref.read(notificationsProvider.notifier).add(
            type: notification.type,
            title: notification.title,
            message: notification.message,
          );
    }
  }

  Future<void> _emitStartupReminders() async {
    try {
      final meals = await ref.read(reservationsRepositoryProvider).getMine();
      final bags = await ref.read(doggyBagRepositoryProvider).getMine();
      await ref.read(notificationsProvider.notifier).emitStartupReminders(
            meals: meals,
            doggyBags: bags,
          );
    } catch (_) {
      // Les rappels sont best-effort : pas d'erreur bloquante au démarrage.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const BrandLogo(height: 32),
            const SizedBox(width: 8),
            Text(
              'Mon Repas',
              style:
                  AppTypography.brandTitle.copyWith(color: colors.foreground),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(
                notificationsProvider.select(
                  (s) => s.items.where((n) => !n.read).length,
                ),
              );
              return IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Text(unread > 99 ? '99+' : '$unread'),
                  backgroundColor: AppColors.brandOrange,
                  child: const Icon(Icons.notifications_outlined),
                ),
                tooltip: 'Notifications',
                onPressed: () => NotificationsPanel.show(context),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profil',
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: index,
        children: const [
          DashboardScreen(),
          MenusScreen(),
          DoggyBagScreen(),
          EventsScreen(),
          OrdersScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        // Liseré haut identique à celui de l'AppBar, pour encadrer l'app.
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              ref.read(homeTabIndexProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Réserver',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'DoggyBag',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Événements',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Commandes',
            ),
          ],
        ),
      ),
    );
  }

}
