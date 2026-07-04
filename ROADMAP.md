# Roadmap — Mon-Repas Client Mobile

> Découpage du développement et suivi d'avancement.
> Le produit cible (fonctionnalités, thème, contrat API, règles métier) est décrit dans **[SPECIFICATIONS.md](./SPECIFICATIONS.md)** — source de vérité fonctionnelle.

## Objectif

Atteindre la **parité fonctionnelle complète** avec la webapp client (`../mon-repas_client`), puis publier sur les stores Android et iOS.

## État actuel

- [x] Repo créé, spécifications rédigées, logos importés
- [ ] Scaffold Flutter (Phase 0)

---

## Phase 0 — Fondations

**Livrable : app qui compile sur Android + iOS, thème validé visuellement.**

- [ ] `flutter create` (org `com.monrepas`, nom `mon_repas_client_mobile`), Material 3
- [ ] Structure `lib/` : `core/ data/ features/ shared/ routing/` (spec §3)
- [ ] Dépendances : flutter_riverpod, go_router, dio, socket_io_client, flutter_secure_storage, shared_preferences, intl, flutter_localizations, mocktail, flutter_lints
- [ ] `core/theme/` : `AppColors` light + dark depuis les tokens de la spec §4, `AppTheme`, `AppTypography` (police Luckiest Guy embarquée pour le logo-texte)
- [ ] `core/api/` : `ApiConfig` (`--dart-define=MONREPAS_API_URL`), `ApiClient` Dio + `ApiException`, `AuthInterceptor`
- [ ] Modèles `data/models/` (spec §9) avec `fromJson` + tests unitaires
- [ ] Helpers plats + dates (spec §9-§10) + tests unitaires (mêmes cas que la webapp)
- [ ] `routing/app_router.dart` : `/splash`, `/login`, `/register`, `/` (HomeShell squelette)
- [ ] Icône d'app générée depuis `assets/images/logo.png` (flutter_launcher_icons) + splash
- [ ] Scripts `run_device.sh` / `start_simu.sh` (comme stepzy_mobile)
- [ ] CI GitHub Actions : `flutter analyze` + `flutter test`

## Phase 1 — Authentification

**Livrable : connexion réelle contre l'API locale.**

- [ ] `AuthRepository` : login / register / me / logout
- [ ] `AuthNotifier` (StateNotifier) : état `{ user, isLoading, error, isInitialized }`, hydratation au démarrage (token en secure storage → `GET /auth/me`)
- [ ] Écran **Login** : validation (email, mdp min 8), erreurs serveur en snackbar
- [ ] Écran **Register** : prénom/nom min 2, confirmation mdp, message « En attente d'activation par un administrateur », retour login sans auto-login
- [ ] Garde rôles : compte `isAdmin`/`isRestaurant` → écran « application réservée aux clients » + déconnexion
- [ ] Redirects go_router pilotés par l'auth (splash → login → home)
- [ ] Gestion 401 globale : logout + retour login
- [ ] Tests : validation des formulaires, AuthNotifier (repo mocké)

## Phase 2 — Menus & réservation

**Livrable : réserver un repas de bout en bout.**

- [ ] `DailyMenusRepository` (`/daily-menus/week`, `/daily-menus/:id`) + `TimeSlotsRepository` + `ReservationsRepository` (POST)
- [ ] Navigation semaine ISO ◀ / « Semaine actuelle » / ▶ (Lun→Ven)
- [ ] Cartes jour : menu (aperçu entrées/plats/desserts, badge Passé via `isDayPast`/`areAllSlotsPast`) et événement (badges Passé/Clôturé/Réservé)
- [ ] 404 semaine = « Menu pas encore disponible » (état normal, pas d'erreur)
- [ ] Panneau de composition : sections Entrée/Plat/Dessert conditionnelles, badges Épuisé / « N restants » / « Spécial »
- [ ] Sélecteur de créneaux : places, barre de progression, badges Passé/COMPLET/Bientôt complet/Disponible, refetch 30 s
- [ ] Bouton « Confirmer la réservation » (sélection complète uniquement) → `POST /reservations` avec `dishMainType`
- [ ] Tests widget : règles de complétude de sélection, plat épuisé non sélectionnable

## Phase 3 — Dashboard (Accueil)

**Livrable : accueil complet avec calendrier hebdomadaire.**

- [ ] Hero : date du jour, « Bonjour {firstName} ! », compteur de réservations actives, raccourcis
- [ ] Calendrier hebdo Lun→Ven (liste verticale mobile) : cartes repas (bleu), doggybag (vert), événement (violet), jour courant en valeur, jours passés grisés
- [ ] Navigation ◀ / « Aujourd'hui » / ▶ + n° de semaine ISO
- [ ] Légende + lien « Voir l'historique complet »

## Phase 4 — Édition / annulation de réservation

**Livrable : parité de gestion des repas.**

- [ ] Bottom-sheet d'édition (spec §7.6) : chargement `GET /daily-menus/:id`, resynchro état à l'ouverture
- [ ] Plat réservé sélectionnable même épuisé ; « Enregistrer » désactivé sans changement
- [ ] `PATCH /reservations/:id` partiel (champs modifiés uniquement) ; affichage des erreurs de fenêtre échue
- [ ] Suppression avec confirmation → `PATCH /reservations/:id/cancel`
- [ ] Ouverture depuis le Dashboard (carte repas tappable si `!isDayPast`)
- [ ] Tests widget : hasChanges, plat courant épuisé sélectionnable

## Phase 5 — Mes commandes

**Livrable : historique complet.**

- [ ] Hero compteurs (repas / doggybags / événements à venir)
- [ ] Onglet **Repas** : segments En cours / Passées / Annulés ; carte plat+entrée+dessert+créneau ; boutons modifier (Phase 4) et annuler
- [ ] Onglet **DoggyBag** : segments En cours / Récupérés / Annulés ; annulation
- [ ] Onglet **Événements** : inscrits (annulables) / passés
- [ ] Tris : actifs date croissante, passés/annulés date décroissante

## Phase 6 — DoggyBag

**Livrable : réservation doggybag complète.**

- [ ] `DoggyBagRepository` (`/doggybag/available`, `/doggybag-reservations`)
- [ ] Grille hebdo bornée S0→S+2, requêtes par jour en parallèle, refetch 60 s
- [ ] Deadlines « Avant HH:MM » (orange/rouge), verrouillage jours passés / délai dépassé
- [ ] Panier (StateNotifier) : quantités min(5, dispo), groupement par date, retrait à 0
- [ ] Confirmation : un POST par item en parallèle, snackbar, panier vidé

## Phase 7 — Événements

**Livrable : inscription aux événements complète.**

- [ ] `SpecialEventsRepository` (liste active, détail, event-reservations)
- [ ] Liste : cartes avec image (placeholder sinon), deadline d'inscription, badge « Réservé »
- [ ] Détail `/events/:id` : image, menu « X ou Y », créneaux avec capacités, confirmation violette
- [ ] Clôture des inscriptions (fin de journée de `registrationDeadline`), re-vérifiée avant envoi

## Phase 8 — Temps réel & notifications

**Livrable : parité totale avec la webapp.**

- [ ] `SocketService` : Socket.IO `/events` avec `auth.token`, reconnexion auto, pause/resume au lifecycle
- [ ] Mapping événements → `ref.invalidate(...)` (tableau spec §8) ; maj en direct des stocks doggybag et capacités de créneaux
- [ ] Cloche + panneau notifications : badge non-lues, tout lire / tout supprimer, max 50, persistance locale
- [ ] Préférences par type (4 interrupteurs) persistées
- [ ] Rappels au démarrage (repas/doggybags du jour, déduplication quotidienne)
- [ ] Toast `event:registration-reminder`

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
