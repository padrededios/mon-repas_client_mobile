# Spécifications — Mon-Repas Client Mobile (Flutter)

> Application mobile **Android + iOS** pour les clients de Mon-Repas.
> Reprend **l'intégralité des fonctionnalités** de la webapp client (`../mon-repas_client`) et consomme **le même backend** (`../mon-repas_api`, NestJS, port 3502).
> Architecture et conventions calquées sur **stepzy_mobile** (`/Users/cedric/Pro/Perso/gitlab/stepzy_mobile`).

---

## 1. Objectif

Permettre à un client (employé) de gérer ses repas depuis son téléphone :

- Consulter les menus de la semaine et **réserver un repas** (entrée + plat + dessert + créneau).
- Voir ses réservations de la semaine sur un **tableau de bord calendaire** et **modifier/annuler** un repas tant que la fenêtre n'est pas échue.
- Réserver des **DoggyBags** (plats du jour à emporter avant une heure limite).
- Découvrir et s'inscrire aux **événements spéciaux**.
- Suivre l'historique complet dans **Mes commandes** (repas / doggybags / événements).
- Recevoir des **notifications** (temps réel WebSocket + rappels du jour).

L'app est **cliente uniquement** : aucun écran admin ni restaurateur. Un compte `isAdmin` ou `isRestaurant` qui se connecte est informé que l'app est réservée aux clients (message + déconnexion).

---

## 2. Stack technique

| Rôle | Choix | Remarque |
|---|---|---|
| Framework | **Flutter** (Dart SDK ^3.x, Material 3) | même base que stepzy_mobile |
| État | **flutter_riverpod** ^2.x | providers manuels, pas de codegen |
| Navigation | **go_router** ^14.x | redirect piloté par l'état d'auth |
| HTTP | **dio** ^5.x | intercepteur Bearer token |
| Temps réel | **socket_io_client** ^2.x | l'API expose Socket.IO (namespace `/events`) — pas de SSE contrairement à stepzy |
| Stockage sécurisé | **flutter_secure_storage** | token JWT + user sérialisé |
| Stockage local | **shared_preferences** | thème choisi, notifications, préférences, clés de rappel |
| Dates/i18n | **intl** + `flutter_localizations` | locale unique **fr_FR**, semaine ISO |
| Icônes | Material Icons (équivalents lucide) | Home, Calendar, Package (inventory), Sparkles (auto_awesome), History |
| Tests | flutter_test + **mocktail** | modèles, repositories, widgets |
| Lints | flutter_lints | |

Identifiant d'application : `com.monrepas.client` (Android `applicationId`, iOS `PRODUCT_BUNDLE_IDENTIFIER`).
Nom affiché : **Mon Repas**.

### Configuration d'environnement

Comme stepzy_mobile, via `--dart-define` (pas de flavors) :

```dart
// lib/core/api/api_config.dart
static const baseUrl = String.fromEnvironment('MONREPAS_API_URL', defaultValue: 'http://localhost:3502');
```

- L'URL WebSocket est **dérivée** de `baseUrl` (`$baseUrl/events`) — on corrige au passage le défaut de la webapp où elle était codée en dur.
- Android émulateur : `http://10.0.2.2:3502` ; iOS simulateur : `http://localhost:3502` ; device réel : IP du Mac sur le LAN. Prévoir `run_device.sh` / `start_simu.sh` comme dans stepzy_mobile.
- Timeout HTTP 10 s ; `validateStatus < 500` ; erreurs encapsulées dans `ApiException { statusCode, message }` (le backend renvoie `{ statusCode, message: string|string[], error }`).

---

## 3. Architecture du code (calquée sur stepzy_mobile)

```
lib/
├── main.dart                    # bootstrap : ProviderContainer, hydratation auth, runApp
├── core/
│   ├── api/
│   │   ├── api_config.dart      # baseUrl (--dart-define), wsUrl dérivée
│   │   ├── api_client.dart      # wrapper Dio (get/post/patch), gestion 401 → logout
│   │   ├── api_exception.dart
│   │   └── auth_interceptor.dart# ajoute Authorization: Bearer <token>
│   ├── realtime/
│   │   └── socket_service.dart  # Socket.IO client : connexion, reconnexion, pause/resume lifecycle
│   └── theme/
│       ├── app_colors.dart      # tokens light + dark (voir §4)
│       ├── app_theme.dart       # ThemeData light & dark, radius, densités
│       └── app_typography.dart
├── data/
│   ├── models/                  # user, daily_menu, dish, time_slot, reservation,
│   │                            # doggybag_reservation, special_event, event_time_slot,
│   │                            # event_reservation, notification_item (fromJson/toJson purs)
│   ├── repositories/            # auth, daily_menus, reservations, time_slots,
│   │                            # doggybag, special_events (1 classe par domaine)
│   └── providers.dart           # TOUS les providers Riverpod centralisés
├── features/
│   ├── splash/                  # restauration de session
│   ├── auth/                    # login_screen, register_screen
│   ├── home/                    # home_shell (AppBar + BottomNavigationBar 5 onglets)
│   ├── dashboard/               # accueil : hero + calendrier hebdo + EditReservationSheet
│   ├── menus/                   # réservation repas + événements de la semaine
│   ├── doggybag/                # grille dispo hebdo + panier
│   ├── events/                  # liste + détail événement + inscription créneau
│   ├── orders/                  # mes commandes : 3 onglets repas/doggybag/événements
│   └── notifications/           # cloche, panneau, préférences
├── shared/widgets/              # app_header, status_badge, async_states (loading/empty/error),
│                                # dish_option, time_slot_tile, capacity_bar, confirm_dialog…
└── routing/app_router.dart      # GoRouter + redirect auth
```

**Câblage Riverpod** (pattern stepzy) :

- `apiClientProvider` → `xxxRepositoryProvider` → `FutureProvider.autoDispose(.family)` pour la lecture, `StateNotifierProvider` pour l'état mutable (auth, panier doggybag, sélection réservation, notifications).
- Tous les providers de données en `autoDispose` (refetch au remontage, pas d'état périmé après logout→login).
- Le service Socket.IO est démarré quand l'utilisateur est connecté (watch dans `HomeShell`), mis en pause/relancé via `AppLifecycleListener` ; chaque événement reçu fait un `ref.invalidate(...)` ciblé (équivalent de l'invalidation react-query de la webapp).

---

## 4. Thème & identité visuelle (⚠️ doit respecter la webapp client)

Le thème reprend **exactement** les tokens de `mon-repas_client/src/app/globals.css` (variables shadcn) et propose **clair + sombre** avec un sélecteur dans l'app (persisté ; défaut = thème système).

### Palette (conversion des variables HSL de la webapp)

| Token | Light | Dark |
|---|---|---|
| background | `#FFFFFF` (0 0% 100%) | `#181C25` (222 20% 12%) |
| foreground | `#020817` (222.2 84% 4.9%) | `#DCDFE5` (220 15% 88%) |
| card | `#FFFFFF` | `#212631` (222 20% 16%) |
| popover | `#FFFFFF` | `#1D212B` (222 20% 14%) |
| **primary** | `#0F172A` (222.2 47.4% 11.2%) | `#F97015` **orange** (24 95% 53%) |
| primary-foreground | `#F8FAFC` | `#FFFFFF` |
| secondary / muted / accent | `#F1F5F9` (210 40% 96.1%) | `#2E3442` (222 18% 22–24%) |
| muted-foreground | `#64748B` (215.4 16.3% 46.9%) | `#89909F` (220 10% 58%) |
| destructive | `#EF4444` (0 84.2% 60.2%) | `#C32222` (0 70% 45%) |
| border | `#E2E8F0` (214.3 31.8% 91.4%) | `#383E4D` (222 16% 26%) |
| input | `#E2E8F0` | `#2A2F3C` (222 18% 20%) |
| ring / focus | `#020817` | `#F97015` |

- **Accent de marque : orange** `hsl(24 95% 53%)` ≈ `#F97015` (onglet actif souligné orange dans la webapp) — à utiliser pour l'onglet actif de la bottom-nav, les CTA principaux et le ring de focus, dans les deux thèmes.
- **Couleurs de catégories** (calendrier + badges, identiques à la webapp) : repas = **bleu**, doggybag = **vert**, événement = **violet**, deadlines = **orange/rouge**, badge « Spécial » (offre du jour) = **violet**.
- Rayon des cartes/champs : `--radius = 0.5rem` → **8 px** (`cardRadius = 8`).
- Badges de statut : default, secondary, destructive, **success** (vert), **warning** (orange) — comme le composant `Badge` de la webapp.

### Typographie

- Corps de texte : police système (SF Pro / Roboto) — la webapp utilise la stack système Tailwind.
- **Titre de marque « Mon Repas »** : police **Luckiest Guy** (Google Fonts, importée dans la webapp) — à embarquer dans `assets/fonts/` et réserver au logo-texte / splash.

### Logo

- Fichiers sources : `mon-repas_client/public/logo.png` (fond clair) et `logo-white.png` (fond sombre) — **copiés dans `assets/images/`** de ce repo.
- Usage : splash screen, AppBar (comme le header web « Mon Repas / Espace Client »), écrans d'auth.
- **Icône d'application** (Android adaptive + iOS) générée depuis `logo.png` via `flutter_launcher_icons`.

---

## 5. Authentification

Même contrat que la webapp (JWT Bearer, pas de cookies) :

| Action | Endpoint | Détail |
|---|---|---|
| Login | `POST /auth/login` `{ email, password }` | → `{ access_token, user }` |
| Register | `POST /auth/register` `{ firstName, lastName, email, password }` | → message ; **pas de login auto** |
| Profil | `GET /auth/me` | → `User` (restauration de session) |
| Logout | `POST /auth/logout` | + purge locale |

- **Stockage** : `access_token` + `user` (JSON) dans **flutter_secure_storage** (équivalent mobile du `localStorage['auth-storage']`).
- **Intercepteur Dio** : `Authorization: Bearer <token>` sur chaque requête ; sur **401** → logout + retour à `/login` (équivalent de l'intercepteur axios web).
- **Splash / restauration** : au démarrage, si un token existe → `GET /auth/me` pour valider la session et rafraîchir `user` ; sinon → login.
- **Validation des formulaires** (mêmes règles zod que le web) : email valide ; mot de passe **min 8** ; prénom/nom **min 2** ; confirmation de mot de passe identique (« Les mots de passe ne correspondent pas »).
- **Inscription** : succès → snackbar « Compte créé avec succès ! En attente d'activation par un administrateur. » puis retour login (le compte est inactif tant qu'un admin ne l'a pas validé).
- **Rôles** : si `user.isAdmin || user.isRestaurant` → écran « Cette application est réservée aux clients » + déconnexion (pas d'équivalent mobile des espaces admin/restaurateur, ni de redirection vers la landing).
- **Redirects go_router** : `/splash` tant que la session n'est pas restaurée → `/login` si non authentifié → `/` (HomeShell) sinon. Pas d'onboarding.
- Le callback SSO web (`/auth/callback`) **n'est pas repris** (spécifique à la landing web).

### Comptes de test

`client@mon-repas.com` / `password123` (client), `cuisto@mon-repas.com`, `admin@mon-repas.com` (refusés par l'app).

---

## 6. Navigation générale

`HomeShell` = AppBar + **BottomNavigationBar 5 onglets** (transposition mobile de la nav horizontale web) :

| Onglet | Icône | Écran |
|---|---|---|
| **Accueil** | home | Dashboard |
| **Réserver** | calendar_month | Menus de la semaine |
| **DoggyBag** | inventory_2 | DoggyBag |
| **Événements** | auto_awesome | Événements |
| **Commandes** | history | Mes commandes |

AppBar commune : logo + « Mon Repas », **cloche de notifications** (badge non-lues), menu (profil : nom/email, bascule thème clair/sombre/système, déconnexion).
Les onglets sont des widgets internes au shell (pattern stepzy), pas des routes ; routes secondaires : `/events/:id` (détail), modales/bottom-sheets pour l'édition de réservation.

---

## 7. Écrans & fonctionnalités (parité webapp)

### 7.1 Accueil / Dashboard

- **Hero** : date du jour (format long fr), « Bonjour, {firstName} ! », compteur « X réservations actives à venir » (ou incitation si 0), raccourcis vers Réserver / DoggyBag / Événements.
- **Calendrier hebdomadaire Lundi→Vendredi** « Mes commandes de la semaine » :
  - Navigation ◀ / « Aujourd'hui » / ▶ (ancre date, `subWeeks/addWeeks`), n° de semaine ISO + plage de dates.
  - Sur mobile : liste verticale des 5 jours (colonne par jour en paysage/tablette).
  - Par jour, mini-cartes colorées : **repas** (bleu — plat + entrée + dessert + créneau), **doggybag** (vert — plat, quantité xN), **événement** (violet — nom, créneau). Jour courant mis en valeur, jours passés grisés.
  - **Carte repas tappable si le jour n'est pas passé** (`!isDayPast`) → ouvre la **feuille d'édition de réservation** (§7.6). Icône crayon visible.
  - Légende des couleurs + bouton « Voir l'historique complet » → onglet Commandes.
- Temps réel : `reservation:confirmed/updated/cancelled`, `doggybag:reservation-updated`, `event:reservation-confirmed` → invalidation des providers concernés.

### 7.2 Réserver un repas (Menus)

- En-tête « Menus de la semaine », navigation semaine ◀ / « Semaine actuelle » / ▶ (semaine/année **ISO**), indicateur discret de refetch.
- `GET /daily-menus/week?week=&year=` + `GET /special-events?active=true` : 5 jours Lun→Ven, chaque jour = carte **menu** ou carte **événement** (l'événement à la même date prend le pas sur le menu).
  - Carte menu : jour + date, aperçu Entrées(n)/Plats(n)/Desserts(n), « 4 créneaux disponibles ». Badge **Passé** si `isDayPast` ou `areAllSlotsPast` (non sélectionnable).
  - Carte événement : badge « Événement spécial », nom, aperçu menu ou description ; badges **Passé** / **Clôturé** / **Réservé**.
- **États** : skeleton de chargement ; **404 = « Menu de la semaine pas encore disponible »** (état normal, pas de retry, navigation semaine conservée) ; erreur ≠ 404 → message + bouton réessayer ; encart d'aide « Comment réserver ? » si rien de sélectionné.
- **Sélection d'un jour menu** → panneau de composition :
  - Sections **Entrée / Plat / Dessert** (affichées uniquement si le menu en contient). Cartes plat : description, badge « Épuisé » (non sélectionnable), « N restants » si ≤ 5, badge violet « Spécial » pour l'offre du jour, coche de sélection.
  - **Sélecteur de créneau** (affiché après choix du plat) : `GET /time-slots/menu/:menuId`, refetch 30 s ; par créneau : places restantes (`capacity - reservedCount`), barre de progression, badges **Passé / COMPLET / Bientôt complet (≥90%) / Disponible**.
  - Bouton **« Confirmer la réservation »** visible seulement quand la sélection est complète (plat obligatoire ; entrée obligatoire si des entrées existent ; dessert idem ; créneau obligatoire).
  - `POST /reservations` `{ timeSlotId, dishType: 'hot_dish_1'|'hot_dish_2'|'offre_jour', starterId?, dessertId? }` (mapping `dishMainType` : `daily_special → offre_jour`). Succès → snackbar + reset.
- **Sélection d'un jour événement** → menu de l'événement (« X ou Y ») + grille de créneaux + bouton violet « Confirmer la réservation » → `POST /event-reservations`.
- Temps réel : `reservation:new/cancelled`, `menu:created/updated/deleted`, `event:timeslot-updated`.

### 7.3 DoggyBag

- Grille hebdo Lun→Ven, navigation **bornée offset 0→2** (pas de passé, max 2 semaines à venir).
- Par jour : `GET /doggybag/available?date=YYYY-MM-DD` (requêtes parallèles, refetch 60 s) ; badge deadline « Avant HH:MM » (orange → rouge si dépassée) ; jours passés ou deadline dépassée verrouillés (« Passé » / « Délai dépassé »).
- Plats : nom + « N dispo » (vert, orange si ≤ 3), « Épuisé » si `availableForDoggyBag == 0`. Tap → ajout au **panier**.
- **Panier** (état local, StateNotifier) : groupé par date avec rappel de deadline ; quantité +/- **plafonnée à min(5, availableForDoggyBag)** ; retrait à 0 ; bouton « Confirmer la réservation » → **un `POST /doggybag-reservations` `{ dishId, quantity }` par item** (parallèle), `pickupDate` dérivé côté API. Succès → snackbar + panier vidé.
- Temps réel : `doggybag:availability-updated` → mise à jour du stock affiché en direct ; `doggybag:reservation-updated` → invalidation.

### 7.4 Événements

- **Liste** des événements actifs : carte avec image (`imageUrl`, placeholder sinon), nom, date (format long), « Inscriptions jusqu'au … » (orange) ou « Inscriptions clôturées » (rouge), description tronquée, badge « Réservé » si déjà inscrit.
- **Détail** (`/events/:id`) : grande image, nom, date + heure, description complète, **menu de l'événement** (Entrée / Plat principal / Dessert au format « X ou Y » depuis `starter1/2, mainDish1/2, dessert1/2`).
  - Créneaux : mêmes règles que §7.2 (places, barre de progression, badges) ; sélection puis carte violette « Confirmer la réservation » → `POST /event-reservations` `{ specialEventId, eventTimeSlotId }`.
  - **Clôture** : `registrationDeadline` → inscriptions closes après **fin de journée** de la deadline (23:59:59) ; encart rouge, créneaux masqués, vérification ré-appliquée avant l'envoi.
- Temps réel : `event:created`, `event:timeslot-updated` (maj capacité en direct), `event:reservation-confirmed`, `event:registration-reminder` → snackbar/notification « Inscrivez-vous maintenant ! ».

### 7.5 Mes commandes

- **Hero compteurs** : « X repas à venir », « X doggy-bags à récupérer », « X événements à venir ».
- **3 onglets** (TabBar) avec badges de total :
  - **Repas** : segments « En cours / Commandes passées / Annulés ». Carte repas : **plat + entrée + dessert** (icônes distinctes), date longue, créneau ; badges Réservé ✓ / Passé / Annulé. Actifs : bouton **crayon** (→ feuille d'édition §7.6) et **X** (annulation avec dialogue de confirmation « Supprimer cette réservation ? ») → `PATCH /reservations/:id/cancel`.
  - **DoggyBag** : segments « En cours / Récupérés / Annulés ». Carte : plat, quantité, date de retrait ; badges En attente ⏳ / Récupéré ✓ (`picked_up`) / Annulé ; annulation → `PATCH /doggybag-reservations/:id/cancel`.
  - **Événements** : « Événements inscrits » (annulables → `PATCH /event-reservations/:id/cancel`) et « Événements passés » ; badges Inscrit ✓ / Passé / Annulé.
- Tri : actifs par date croissante ; passés/annulés par date décroissante.

### 7.6 Édition de réservation (bottom-sheet / dialogue plein écran mobile)

Équivalent de `EditReservationDialog` web, accessible depuis le Dashboard et Mes commandes :

- Charge le menu complet `GET /daily-menus/:id` ; état local entrée/plat/dessert/créneau resynchronisé à l'ouverture.
- Règles : le plat **actuellement réservé reste sélectionnable même épuisé** ; « Enregistrer » désactivé sans changement ; **PATCH partiel** (`PATCH /reservations/:id`) n'envoyant que les champs modifiés (`dishType` recalculé, `starterId`/`dessertId` `null` = suppression, `timeSlotId`).
- Bouton « Supprimer » → confirmation « Supprimer cette réservation ? Cette action est définitive. » → cancel.
- Fenêtre de modification : côté client `!isDayPast(dailyMenu.date)` ; le backend re-vérifie (fin de journée du menu) et renvoie « La fenêtre de modification est échue » sinon.
- Après succès : invalidation réservations + créneaux + menus.

### 7.7 Notifications

- **Cloche** dans l'AppBar, badge non-lues (« 99+ » max), panneau : liste (icône + couleur par type, horodatage relatif fr), actions **Tout lire**, **Tout supprimer**, suppression/lecture unitaire, empty state.
- **Types** : `doggybag_reminder`, `event_new`, `meal_reminder`, `system` — **préférences par type** (4 interrupteurs, tous actifs par défaut), persistées.
- **Sources** :
  - WebSocket : `reservation:confirmed` → meal_reminder « Réservation confirmée » ; `doggybag:reservation-updated` (confirmé) → doggybag_reminder ; `event:created` → event_new « Nouvel événement disponible » ; `system:notification` → system.
  - **Rappels au démarrage** : au premier lancement authentifié du jour, rappels des repas réservés **aujourd'hui** et des doggybags à récupérer **aujourd'hui** (déduplication par clé datée, purge quotidienne).
- Persistance locale (shared_preferences) : **max 50 notifications**, filtrées par préférence à l'ajout.
- **V1 : notifications locales/in-app uniquement** (parité web). Push FCM/APNs = évolution ultérieure (§11), nécessitant un endpoint d'enregistrement de device côté API.

---

## 8. Contrat API (rappel complet)

Base : `MONREPAS_API_URL` (défaut `http://localhost:3502`), JSON, Bearer token.

| Domaine | Endpoints utilisés |
|---|---|
| Auth | `POST /auth/login`, `POST /auth/register`, `GET /auth/me`, `POST /auth/logout` |
| Menus | `GET /daily-menus/week?week=&year=`, `GET /daily-menus/:id`, (`GET /daily-menus/today`, `/date/:date` dispo) |
| Créneaux | `GET /time-slots/menu/:menuId` |
| Réservations | `GET /reservations/me`, `POST /reservations`, `PATCH /reservations/:id`, `PATCH /reservations/:id/cancel` |
| DoggyBag | `GET /doggybag/available?date=`, `GET /doggybag-reservations/me`, `POST /doggybag-reservations`, `PATCH /doggybag-reservations/:id/cancel` |
| Événements | `GET /special-events?active=true`, `GET /special-events/:id`, `GET /event-reservations/me`, `POST /event-reservations`, `PATCH /event-reservations/:id/cancel` |

**WebSocket** : Socket.IO namespace **`/events`**, `auth: { token }`, transports websocket+polling, reconnexion auto. Événements consommés : `menu:created|updated|deleted`, `reservation:new|confirmed|updated|cancelled`, `doggybag:availability-updated`, `doggybag:reservation-updated`, `event:created`, `event:timeslot-updated`, `event:reservation-confirmed`, `event:registration-reminder`, `system:notification`, `connected`.

---

## 9. Modèles de données (lib/data/models/)

- **User** : `id, email, firstName, lastName, isAdmin, isRestaurant, isActive`.
- **Dish** : `id, name, description?, type (DishType), isDoggyBagEligible, availableForDoggyBag, reservedForDoggyBag, availableQuantity (int? — null = illimité), reservedQuantity, dailyMenuId`.
- **DishType** (enum) : `starter_1|2|3, starter_daily, hot_dish_1|2, daily_special, dessert_1|2|3, dessert_daily`.
  - Helpers (portage de `utils/dishes.ts`, testés unitairement) : `getStarters/getMainDishes/getDesserts`, `isDailySpecialType`, `getDishTypeLabel` (Entrée/Plat/Dessert/Offre du jour), `dishMainType` (→ `hot_dish_1|hot_dish_2|offre_jour`), `getDishAvailability`.
- **DailyMenu** : `id, date, timeSlotCapacity, isActive, doggyBagDeadline?, dishes[], timeSlots?`.
- **TimeSlot** : `id, dailyMenuId, startTime, endTime, capacity, reservedCount`.
- **Reservation** : `id, userId, timeSlotId, dishId, starterId?, dessertId?, status ('confirmed'|'cancelled'), createdAt` + relations `dish, starter, dessert, timeSlot, dailyMenu`.
- **DoggyBagReservation** : `id, dishId, quantity, pickupDate, status ('confirmed'|'cancelled'|'picked_up'), dish?`.
- **SpecialEvent** : `id, name, description, imageUrl?, eventDate, isActive, registrationDeadline?, starter1/2, mainDish1/2, dessert1/2 (String?), timeSlots?`.
- **EventTimeSlot** : `id, specialEventId, startTime, endTime, capacity, reservedCount`.
- **EventReservation** : `id, specialEventId, eventTimeSlotId, status, specialEvent?, eventTimeSlot?`.
- **NotificationItem** : `id, type, title, message, read, createdAt, data?`.

---

## 10. Règles métier transverses (portage de `utils/date.ts` — à tester unitairement)

- **`isDayPast(date)`** : strictement avant aujourd'hui → verrouille édition/annulation et grise les jours.
- **`isTimeSlotPast(date, endTime)`** : jour antérieur = passé ; aujourd'hui = compare l'heure de fin à maintenant.
- **`areAllSlotsPast(date, latestEnd='14:00')`** : un menu du jour est « passé » après 14:00 (service midi 12:00–14:00).
- **Semaine ISO** (`getISOWeek/getISOWeekYear` équivalents Dart) — synchro avec l'app restaurateur ; semaine affichée **Lundi→Vendredi**.
- **Capacités** : places créneau = `capacity - reservedCount` ; COMPLET si 0 ; « Bientôt complet » si remplissage ≥ 90 %.
- **Disponibilité plat** : `availableQuantity == null` → illimité ; sinon `remaining = availableQuantity - reservedQuantity` (épuisé si ≤ 0, « N restants » si ≤ 5).
- **DoggyBag** : deadline quotidienne `doggyBagDeadline` (HH:MM) ; quantité max par plat = min(5, dispo) ; navigation limitée à S+2.
- **Événements** : clôture des inscriptions après fin de journée de `registrationDeadline`.
- **Toutes ces règles sont re-validées côté API** — l'app doit afficher proprement les erreurs 400/403 renvoyées (ex. « La fenêtre de modification est échue »).

---

## 11. Hors périmètre V1 (évolutions possibles)

- Push notifications FCM/APNs (nécessite un endpoint device-token côté API).
- Mode hors-ligne / cache persistant des menus.
- Callback SSO depuis la landing, deep links.
- Écrans admin/restaurateur, paiement, QR code de retrait.
- i18n autre que français, thème dynamique Material You.

---

## 12. Qualité & tests

- **Tests unitaires** : modèles (`fromJson`), helpers plats/dates (mêmes cas que `dishes.test.ts` web), repositories (Dio mocké via mocktail).
- **Tests widget** : login (validation), carte menu, feuille d'édition (bouton désactivé sans changement, plat réservé sélectionnable même épuisé).
- **Lint** : `flutter analyze` sans warning ; CI GitHub Actions (analyze + tests) comme stepzy_mobile.
- **Vérification manuelle** : parcours complet contre l'API locale (comptes de test §5) sur émulateur Android + simulateur iOS.

---

## 13. Roadmap de développement

| Phase | Contenu | Livrable |
|---|---|---|
| **0 — Fondations** | scaffold Flutter, thème light/dark + logo + icônes, ApiClient/ApiConfig, modèles + tests, go_router + splash | app qui compile, thème validé |
| **1 — Auth** | login, register, secure storage, restauration session, garde rôles | connexion réelle API |
| **2 — Menus & réservation** | semaine ISO, cartes jour, composition entrée/plat/dessert, créneaux, POST réservation | réservation de bout en bout |
| **3 — Dashboard** | hero, calendrier hebdo, cartes colorées | accueil complet |
| **4 — Édition/annulation** | bottom-sheet d'édition, PATCH partiel, annulation | parité gestion repas |
| **5 — Mes commandes** | 3 onglets + segments + annulations | historique complet |
| **6 — DoggyBag** | grille dispo, deadlines, panier, réservation | doggybag complet |
| **7 — Événements** | liste, détail, créneaux, inscription, clôture | événements complets |
| **8 — Temps réel & notifications** | Socket.IO, invalidations, cloche, préférences, rappels du jour | parité totale webapp |
| **9 — Polish & stores** | icônes/splash définitifs, perfs, builds signés Android/iOS | candidats stores |

---

## 14. Références

- Webapp client (source de vérité fonctionnelle) : `../mon-repas_client`
- API backend (contrat réel) : `../mon-repas_api` (Swagger : `http://localhost:3502/api`)
- Modèle d'architecture Flutter : `/Users/cedric/Pro/Perso/gitlab/stepzy_mobile`
- Thème : `../mon-repas_client/src/app/globals.css`, `tailwind.config.ts` ; logos : `../mon-repas_client/public/logo*.png`
