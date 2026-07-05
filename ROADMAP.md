# Roadmap — Mon-Repas Client Mobile

> Découpage du développement et suivi d'avancement.
> Le produit cible (fonctionnalités, thème, contrat API, règles métier) est décrit dans **[SPECIFICATIONS.md](./SPECIFICATIONS.md)** — source de vérité fonctionnelle.

## Objectif

Atteindre la **parité fonctionnelle complète** avec la webapp client (`../mon-repas_client`), puis publier sur les stores Android et iOS.

## État actuel

- [x] Repo créé, spécifications rédigées, logos importés
- [x] **Phases 0 → 2 terminées** (jalon **M1**) — fondations, auth, réservation de repas
- [x] **Phases 3 → 5 terminées** (jalon **M2**) — dashboard, édition/annulation, mes commandes
- [x] **Phases 6 → 8 terminées** (jalon **M3**) — doggybag, événements, temps réel + notifications
- [ ] À valider sur iPhone : `./run_device.sh` (API locale démarrée)

Suite : Phase 9 (polish + publication stores, jalon M4) après validation sur device.

---

## Phase 0 — Fondations

**Livrable : app qui compile sur Android + iOS, thème validé visuellement.**

- [x] `flutter create` (org `com.monrepas`, id `com.monrepas.client`, nom affiché « Mon Repas »), Material 3
- [x] Structure `lib/` : `core/ data/ features/ shared/ routing/` (spec §3)
- [x] Dépendances : flutter_riverpod, go_router, dio, socket_io_client, flutter_secure_storage, shared_preferences, intl, flutter_localizations, mocktail, flutter_lints
- [x] `core/theme/` : `AppColors` light + dark depuis les tokens de la spec §4 (ThemeExtension), `AppTheme`, `AppTypography` (police Luckiest Guy embarquée pour le logo-texte)
- [x] `core/api/` : `ApiConfig` (`--dart-define=MONREPAS_API_URL`), `ApiClient` Dio + `ApiException`, `AuthInterceptor`
- [x] Modèles `data/models/` (spec §9) avec `fromJson` + tests unitaires
- [x] Helpers plats + dates (spec §9-§10) + tests unitaires (mêmes cas que la webapp)
- [x] `routing/app_router.dart` : `/splash`, `/login`, `/register`, `/` (HomeShell)
- [x] Icône d'app générée depuis `assets/images/logo.png` (flutter_launcher_icons) — splash natif : Phase 9
- [x] Script `run_device.sh` (iPhone via IP LAN) — pas de `start_simu.sh` : on ne teste pas sur simulateur (Mac trop juste), device réel uniquement
- [x] CI GitHub Actions : `flutter analyze` + `flutter test`

## Phase 1 — Authentification

**Livrable : connexion réelle contre l'API locale.**

- [x] `AuthRepository` : login / register / me / logout
- [x] `AuthNotifier` (StateNotifier) : état `{ user, isLoading, error, isInitialized }`, hydratation au démarrage (token en secure storage → `GET /auth/me`, mode dégradé hors-ligne)
- [x] Écran **Login** : validation (email, mdp min 8), erreurs serveur en snackbar
- [x] Écran **Register** : prénom/nom min 2, confirmation mdp, message « En attente d'activation par un administrateur », retour login sans auto-login
- [x] Garde rôles : compte `isAdmin`/`isRestaurant` refusé au login avant toute persistance (« Cette application est réservée aux clients »)
- [x] Redirects go_router pilotés par l'auth (splash → login → home)
- [x] Gestion 401 globale : logout + retour login
- [x] Tests : validation des formulaires, AuthNotifier, AuthRepository, écrans login/register (repo mocké)

## Phase 2 — Menus & réservation

**Livrable : réserver un repas de bout en bout.**

- [x] `DailyMenusRepository` (`/daily-menus/week`, `/daily-menus/:id`) + `TimeSlotsRepository` + `ReservationsRepository` (POST/PATCH/cancel)
- [x] Navigation semaine ISO ◀ / « Semaine actuelle » / ▶ (Lun→Ven)
- [x] Cartes jour menu : aperçu entrées/plats/desserts, badge Passé via `isDayPast`/`areAllSlotsPast`
- [x] Cartes jour **événement** dans la semaine (badges Passé/Clôturé/Réservé) — livré avec la Phase 7
- [x] 404 semaine = « Menu pas encore disponible » (état normal, pas d'erreur)
- [x] Panneau de composition : sections Entrée/Plat/Dessert conditionnelles, badges Épuisé / « N restants » / « Spécial »
- [x] Sélecteur de créneaux : places, barre de progression, badges Passé/COMPLET/Bientôt complet/Disponible, refetch 30 s
- [x] Bouton « Confirmer la réservation » (sélection complète uniquement) → `POST /reservations` avec `dishMainType`
- [x] Tests widget : règles de complétude de sélection, plat épuisé non sélectionnable

## Phase 3 — Dashboard (Accueil)

**Livrable : accueil complet avec calendrier hebdomadaire.**

- [x] Hero : date du jour, « Bonjour {firstName} ! », compteur de réservations actives, raccourcis
- [x] Calendrier hebdo Lun→Ven (liste verticale mobile) : cartes repas (bleu), doggybag (vert), événement (violet), jour courant en valeur, jours passés grisés
- [x] Navigation ◀ / « Aujourd'hui » / ▶ + n° de semaine ISO
- [x] Légende + lien « Voir l'historique complet »

## Phase 4 — Édition / annulation de réservation

**Livrable : parité de gestion des repas.**

- [x] Bottom-sheet d'édition (spec §7.6) : chargement `GET /daily-menus/:id`, resynchro état à l'ouverture
- [x] Plat réservé sélectionnable même épuisé ; « Enregistrer » désactivé sans changement
- [x] `PATCH /reservations/:id` partiel (champs modifiés uniquement) ; affichage des erreurs de fenêtre échue
- [x] Suppression avec confirmation → `PATCH /reservations/:id/cancel`
- [x] Ouverture depuis le Dashboard (carte repas tappable si `!isDayPast`)
- [x] Tests widget : hasChanges, plat courant épuisé sélectionnable

## Phase 5 — Mes commandes

**Livrable : historique complet.**

- [x] Hero compteurs (repas / doggybags / événements à venir)
- [x] Onglet **Repas** : segments En cours / Passées / Annulés ; carte plat+entrée+dessert+créneau ; boutons modifier (Phase 4) et annuler
- [x] Onglet **DoggyBag** : segments En cours / Récupérés / Annulés ; annulation
- [x] Onglet **Événements** : inscrits (annulables) / passés
- [x] Tris : actifs date croissante, passés/annulés date décroissante

## Phase 6 — DoggyBag

**Livrable : réservation doggybag complète.**

- [x] `DoggyBagRepository` (`/doggybag/available`, `/doggybag-reservations`)
- [x] Grille hebdo bornée S0→S+2, requêtes par jour en parallèle, refetch 60 s
- [x] Deadlines « Avant HH:MM » (orange/rouge), verrouillage jours passés / délai dépassé
- [x] Panier (StateNotifier) : quantités min(5, dispo), groupement par date, retrait à 0
- [x] Confirmation : un POST par item en parallèle, snackbar, panier vidé

## Phase 7 — Événements

**Livrable : inscription aux événements complète.**

- [x] `SpecialEventsRepository` (liste active, détail, event-reservations)
- [x] Liste : cartes avec image (placeholder sinon), deadline d'inscription, badge « Réservé »
- [x] Détail `/events/:id` : image, menu « X ou Y », créneaux avec capacités, confirmation violette
- [x] Clôture des inscriptions (fin de journée de `registrationDeadline`), re-vérifiée avant envoi

## Phase 8 — Temps réel & notifications

**Livrable : parité totale avec la webapp.**

- [x] `SocketService` : Socket.IO `/events` avec `auth.token`, reconnexion auto, pause/resume au lifecycle
- [x] Mapping événements → `ref.invalidate(...)` (tableau spec §8) ; maj en direct des stocks doggybag et capacités de créneaux
- [x] Cloche + panneau notifications : badge non-lues, tout lire / tout supprimer, max 50, persistance locale
- [x] Préférences par type (4 interrupteurs) persistées
- [x] Rappels au démarrage (repas/doggybags du jour, déduplication quotidienne)
- [x] Toast `event:registration-reminder`

## Phase 9 — Polish & publication stores

**Livrable : builds candidats aux stores.**

- [ ] Passe UX/UI : états vides, erreurs, pull-to-refresh, tailles d'écran
- [ ] Performances (listes, images d'événements en cache)
- [ ] Icônes/splash définitifs, écrans de stores (captures, descriptions)
- [ ] Android : signing config, build AAB, Play Console (piste interne)
- [ ] iOS : certificats/profils, build TestFlight
- [ ] Politique de confidentialité + fiche store

---

## Hors périmètre V1

Voir SPECIFICATIONS.md §11 : push FCM/APNs, mode hors-ligne, SSO/deep links, écrans admin/restaurateur, i18n non-fr.

## Jalons proposés

1. **M1 — Base utilisable** : Phases 0 → 2 (se connecter et réserver un repas)
2. **M2 — Parité gestion** : Phases 3 → 5 (dashboard, édition, commandes)
3. **M3 — Parité totale** : Phases 6 → 8 (doggybag, événements, temps réel)
4. **M4 — Stores** : Phase 9

## Références

- Spécifications produit : [SPECIFICATIONS.md](./SPECIFICATIONS.md)
- Webapp client (comportement de référence) : `../mon-repas_client`
- API : `../mon-repas_api` (Swagger `http://localhost:3502/api`)
- Modèle d'architecture : `/Users/cedric/Pro/Perso/gitlab/stepzy_mobile`
