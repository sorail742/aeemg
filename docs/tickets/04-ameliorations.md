# Tickets — Améliorations (`AMEL`)

Architecture, maintenabilité, performance, compatibilité, accessibilité, i18n, tests.

---

### AMEL-001 — Découper les écrans géants (`admin_screen.dart`, `chat_screen.dart`)
**Type** : Maintenabilité · **Priorité** : P1 · **Estimation** : L · **Composant** : flutter
**Dépendances** : AMEL-002

**Contexte** — `admin_screen.dart` = 1728 lignes, `chat_screen.dart` = 1208 lignes : UI, logique métier,
accès Storage et dialogues mélangés. Conflits de merge garantis à 6 développeurs.

**Critères d'acceptation**
- [ ] Aucun fichier de `lib/` > 400 lignes (contrôle CI `maintainability`)
- [ ] Un fichier par onglet admin (`admin/presentation/tabs/…`), un widget par élément de chat (bulle, barre de saisie, lecteur audio, dialogue d'invitation)
- [ ] Aucun changement fonctionnel (tests widget avant/après)

---

### AMEL-002 — Sortir la logique des widgets vers des contrôleurs Riverpod
**Type** : Maintenabilité · **Priorité** : P1 · **Estimation** : L · **Composant** : flutter
**Dépendances** : [ADR-0004](../adr/0004-riverpod-gestion-etat.md), [ADR-0006](../adr/0006-architecture-feature-first.md)

**Contexte** — Plusieurs widgets appellent directement `client.storage` / `client.from(...)`
(ex. `chat_screen.dart:375`, `feedback_screen.dart:50`), ce qui empêche les tests et duplique la logique.

**Critères d'acceptation**
- [ ] Aucun import `supabase_flutter` dans `lib/features/*/presentation/` (règle vérifiée en CI)
- [ ] Chaque écran avec actions a un `Notifier`/`AsyncNotifier` testé unitairement
- [ ] Couverture ≥ 70 % des contrôleurs

---

### AMEL-003 — Modèles typés et immuables
**Type** : Maintenabilité · **Priorité** : P2 · **Estimation** : L · **Composant** : flutter

**Contexte** — L'admin et plusieurs repositories manipulent des `Map<String, dynamic>` et des casts
(`profile.roleLabel as String`), sources d'erreurs à l'exécution.

**Critères d'acceptation**
- [ ] Modèles `freezed` + `json_serializable` (ou équivalent décidé en ADR) pour toutes les entités
- [ ] Plus aucun `Map<String, dynamic>` exposé hors de la couche `data`
- [ ] Fichiers générés exclus de l'analyse et vérifiés à jour en CI (`build_runner` + `git diff --exit-code`)

---

### AMEL-004 — Supprimer le client Supabase nullable
**Type** : Maintenabilité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter
**Dépendances** : REL-010

**Contexte** — `supabaseClientProvider` renvoie `SupabaseClient?` ; tous les repositories font `_client?.` et
renvoient silencieusement des listes vides/`null` quand le client est absent → bugs invisibles.

**Critères d'acceptation**
- [ ] Client non nullable ; le mode « non configuré » est géré une seule fois au démarrage
- [ ] Repositories derrière une interface abstraite + fakes pour les tests

---

### AMEL-005 — Internationalisation avec `gen-l10n` (FR, Peul, Arabe)
**Type** : Amélioration · **Priorité** : P2 · **Estimation** : L · **Composant** : flutter
**Dépendances** : [ADR-0013](../adr/0013-internationalisation.md)

**Contexte** — `lib/core/l10n/app_strings.dart` ne couvre que la navigation ; les centaines de textes des
écrans sont en dur en français. Le CDC (§4.3) prévoit Peul et Arabe (RTL).

**Critères d'acceptation**
- [ ] Fichiers `lib/l10n/app_fr.arb`, `app_ff.arb`, `app_ar.arb` ; `flutter gen-l10n` en CI
- [ ] 0 chaîne utilisateur en dur dans `presentation/` (lint/grep CI)
- [ ] Test widget d'un écran en arabe : mise en page RTL correcte
- [ ] Processus de relecture des traductions peules documenté

---

### AMEL-006 — Durcir les règles d'analyse statique
**Type** : Maintenabilité · **Priorité** : P1 · **Estimation** : S · **Composant** : flutter, ci

**Contexte** — `analysis_options.yaml` = `flutter_lints` sans règle additionnelle.

**Critères d'acceptation**
- [ ] Ajout de : `strict-casts`, `strict-raw-types`, `always_declare_return_types`, `avoid_dynamic_calls`, `prefer_final_locals`, `unawaited_futures`, `discarded_futures`, `use_build_context_synchronously`, `avoid_print`, `require_trailing_commas`
- [ ] Code existant corrigé (ou exclusions temporaires listées avec ticket) ; `flutter analyze` vert

---

### AMEL-007 — Stratégie et couverture de tests Flutter
**Type** : Qualité · **Priorité** : P1 · **Estimation** : L (découpable par feature) · **Composant** : flutter
**Dépendances** : AMEL-004, [ADR-0014](../adr/0014-strategie-de-tests.md)

**Contexte** — 6 fichiers de test pour ~16 700 lignes ; aucun test de repository avec Supabase simulé,
aucun test des écrans critiques (connexion, don, chat, admin).

**Critères d'acceptation**
- [ ] Couverture globale ≥ 60 % (seuil vérifié en CI, relevé de 10 points par trimestre jusqu'à 80 %)
- [ ] Tests widget : connexion, inscription, RSVP, don, envoi de message, changement de rôle admin
- [ ] Golden tests des composants du design system
- [ ] Tests d'intégration (`integration_test/`) du parcours « inscription → rejoindre Général → message »

---

### AMEL-008 — Tests de sécurité RLS automatisés (pgTAP)
**Type** : Qualité / Sécurité · **Priorité** : P0 · **Estimation** : M · **Composant** : supabase/db
**Dépendances** : REL-001, REL-002

**Contexte** — Aucune policy n'est testée ; plusieurs failles critiques (SEC-001, 003, 004, 006, 008) l'auraient
été. Le dossier `supabase/tests/` contient un premier test garde-fou (RLS activé sur toutes les tables).

**Critères d'acceptation**
- [ ] Helpers de test (`tests.create_user(role)`, `tests.authenticate_as(uuid)`) dans `supabase/tests/`
- [ ] Au moins un test par policy (lecture autorisée/refusée, écriture autorisée/refusée)
- [ ] Job CI `supabase / db-tests` bloquant

---

### AMEL-009 — Accessibilité (a11y)
**Type** : Amélioration · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter

**Contexte** — CDC §7.1 : « police lisible, contraste élevé ». Thème sombre avec texte gris `#BEBABC` sur
`#325859` à vérifier ; icônes sans `Semantics` ; tailles de police fixes.

**Critères d'acceptation**
- [ ] Tests `meetsGuideline(textContrastGuideline)`, `androidTapTargetGuideline`, `labeledTapTargetGuideline` sur les écrans principaux
- [ ] L'app reste utilisable avec une taille de texte système à 200 %
- [ ] Parcours principal testé avec TalkBack et VoiceOver (checklist dans la PR)

---

### AMEL-010 — Performance basse bande passante
**Type** : Performance · **Priorité** : P1 · **Estimation** : L · **Composant** : flutter

**Contexte** — Cible CDC : < 3 s en 3G. `google_fonts` télécharge les polices à l'exécution ; images réseau
sans cache disque ; pas de miniatures ; bundle web non mesuré.

**Critères d'acceptation**
- [ ] Polices Rethink Sans / Manrope embarquées en assets (`GoogleFonts.config.allowRuntimeFetching = false`)
- [ ] Cache disque des images réseau + miniatures servies par Supabase image transformation
- [ ] Budget CI : `main.dart.js` ≤ 4 Mo (gzip), APK arm64 ≤ 35 Mo — job `size-budget`
- [ ] Mesure Lighthouse (web, profil 3G) ≥ 60 en performance, documentée

---

### AMEL-011 — Compatibilité Web : ne plus utiliser `dart:io` pour les uploads
**Type** : Compatibilité · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter

**Contexte** — `chat_screen.dart`, `create_post_screen.dart`, `social_repository.dart`,
`social_providers.dart` importent `dart:io` et utilisent `File` : envoi d'image, de vocal et de post avec
photo **plantent sur le Web** (cible officielle du CDC). L'enregistrement audio en `.m4a` dans un dossier
temporaire n'est pas supporté non plus sur Web.

**Critères d'acceptation**
- [ ] Uploads via `XFile.readAsBytes()` + `uploadBinary` (aucun `dart:io` dans `lib/` hors fichiers conditionnels `*_io.dart`)
- [ ] Message vocal sur Web : enregistrement en `opus/webm` ou fonctionnalité masquée proprement
- [ ] Test manuel sur Chrome, Firefox, Safari documenté dans la PR ; job CI `build web` vert

---

### AMEL-012 — CORS et module partagé pour les Edge Functions
**Type** : Compatibilité · **Priorité** : P1 · **Estimation** : S · **Composant** : edge-functions

**Contexte** — Aucune fonction ne répond aux requêtes `OPTIONS` ni n'envoie d'en-têtes CORS : l'appel
`functions.invoke('orange-money-init')` échoue depuis l'app Web. Code d'auth et de réponse dupliqué ;
imports `https://esm.sh/@supabase/supabase-js@2` non figés.

**Critères d'acceptation**
- [ ] `supabase/functions/_shared/{cors,auth,http}.ts` utilisés par toutes les fonctions
- [ ] Origines autorisées configurables par environnement (pas de `*` en prod)
- [ ] Dépendances figées dans `supabase/functions/deno.json` (`imports` + version exacte) et `deno.lock`
- [ ] Test Deno : `OPTIONS` → 204 avec les bons en-têtes

---

### AMEL-013 — Environnements dev / staging / prod
**Type** : Amélioration · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter, supabase, ci
**Dépendances** : SEC-019, [ADR-0011](../adr/0011-environnements.md)

**Critères d'acceptation**
- [ ] 3 projets Supabase (ou branches Supabase) ; `config/dev.json`, `config/staging.json` (non secrets) ; prod injecté par la CI
- [ ] Flavors Android / schemes iOS : nom et icône distincts pour dev/staging
- [ ] Migrations déployées automatiquement en staging à chaque merge sur `main`, en prod sur tag (OPS-005)

---

### AMEL-014 — README et documentation d'onboarding
**Type** : Documentation · **Priorité** : P1 · **Estimation** : S · **Composant** : docs

**Critères d'acceptation**
- [ ] README : présentation, architecture (schéma), prérequis (versions Flutter/Supabase CLI/Deno), lancement local en < 30 min, commandes de test, liens vers ADR, tickets, règles d'équipe
- [ ] Un nouveau développeur suit le README sans aide et lance l'app + Supabase local (validé par un membre de l'équipe)

---

### AMEL-015 — Vues et RPC SQL pour les tableaux de bord
**Type** : Performance · **Priorité** : P2 · **Estimation** : M · **Composant** : supabase/db

**Contexte** — Statistiques calculées côté client par requêtes successives (admin, finances).

**Critères d'acceptation**
- [ ] RPC `admin_dashboard_stats()`, `finance_summary(year, month)` avec contrôle de rôle interne
- [ ] Un seul aller-retour réseau par tableau de bord ; tests pgTAP

---

### AMEL-016 — Index de base de données
**Type** : Performance · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/db

**Contexte** — Aucun index secondaire n'est créé. Les policies RLS font des `exists` sur
`chat_group_members(group_id, user_id)` à chaque ligne.

**Critères d'acceptation**
- [ ] Index : `messages(group_id, created_at desc)`, `notifications(user_id, is_read, created_at desc)`, `event_rsvps(user_id)`, `posts(created_at desc)`, `post_comments(post_id, created_at)`, `donations(user_id)`, `chat_group_members(user_id)`, `message_receipts(user_id)`, `events(starts_at)`
- [ ] Toutes les FK indexées (requête de contrôle en CI)
- [ ] `EXPLAIN ANALYZE` avant/après joint à la PR pour la requête de messages

---

### AMEL-017 — Types et constantes de base de données générés
**Type** : Maintenabilité · **Priorité** : P3 · **Estimation** : S · **Composant** : flutter, edge-functions

**Critères d'acceptation**
- [ ] Noms de tables/colonnes centralisés (`lib/core/db/tables.dart`) ; aucune chaîne `'profiles'` dispersée
- [ ] Types TypeScript générés (`supabase gen types typescript`) pour les Edge Functions, vérifiés à jour en CI

---

### AMEL-018 — Routage : garde d'authentification, 404, deep links
**Type** : Amélioration · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter
**Dépendances** : REL-014

**Critères d'acceptation**
- [ ] `redirect` basé sur l'état d'auth (`refreshListenable`) ; `errorBuilder` 404
- [ ] Deep link `io.supabase.aeemg://login-callback/` configuré Android (`intent-filter`) et iOS (`CFBundleURLTypes`) pour reset mot de passe / confirmation email
- [ ] Liens web partageables vers un événement/post (`/events/:id`)

---

### AMEL-019 — Détection de connectivité et stratégie de retry
**Type** : Robustesse · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter

**Critères d'acceptation**
- [ ] Bannière « Hors ligne » globale ; rafraîchissement automatique au retour du réseau
- [ ] Retry exponentiel (3 essais) sur les lectures idempotentes
- [ ] Contenu en cache affiché avec la date de dernière mise à jour

---

### AMEL-020 — Versionnage sémantique et CHANGELOG automatique
**Type** : Maintenabilité · **Priorité** : P2 · **Estimation** : S · **Composant** : ci
**Dépendances** : [ADR-0016](../adr/0016-versionnage-et-releases.md)

**Critères d'acceptation**
- [ ] `version:` du `pubspec.yaml` = source unique ; `versionCode` croissant à chaque release
- [ ] `CHANGELOG.md` généré depuis les Conventional Commits à chaque tag

---

### AMEL-021 — Un seul paquet audio
**Type** : Maintenabilité · **Priorité** : P3 · **Estimation** : S · **Composant** : flutter
**Dépendances** : DEL-010

**Critères d'acceptation**
- [ ] Les messages vocaux utilisent `just_audio` via un service partagé avec le Coran (un seul lecteur actif à la fois)

---

### AMEL-022 — Respect du design system (couleurs/espacements en dur)
**Type** : Maintenabilité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter

**Contexte** — Usages directs de `Colors.white70`, `BorderRadius.circular(12)`, `EdgeInsets` numériques
au lieu des tokens `AppColors`/`AppRadius`/`AppSpacing`.

**Critères d'acceptation**
- [ ] 0 `Colors.` hors `lib/core/theme/` (contrôle grep CI)
- [ ] Composants manquants ajoutés à `shared/widgets/ds/` et documentés dans `docs/DESIGN_SYSTEM.md`

---

### AMEL-023 — Notifications in-app générées côté serveur
**Type** : Amélioration · **Priorité** : P2 · **Estimation** : M · **Composant** : supabase/db
**Dépendances** : FEAT-001

**Contexte** — Les notifications ne sont créées que par `event-reminders` ou à la main en SQL
(`docs/ADMIN_GUIDE.md`). Nouvelle annonce, nouvel événement approuvé, mention, réponse → aucune notification.

**Critères d'acceptation**
- [ ] Triggers/fonctions qui créent les notifications (respect des préférences par catégorie)
- [ ] Aucune notification à l'auteur de l'action ; regroupement des messages d'un même groupe

---

### AMEL-024 — Reformater tout le code Dart en une fois
**Type** : Maintenabilité · **Priorité** : P1 · **Estimation** : XS · **Composant** : flutter, ci

**Contexte** — 83 fichiers Dart sur 107 ne respectent pas `dart format`. La CI ne vérifie pour l'instant
que les fichiers modifiés par la PR.

**Critères d'acceptation**
- [ ] Un commit unique `style: dart format` sans autre changement, ajouté à `.git-blame-ignore-revs`
- [ ] Le job CI `format` passe en mode « tout le dépôt »
- [ ] Planifié un jour sans PR ouverte (ou PR rebasées ensuite)

---

### AMEL-025 — Résilience du cache hors ligne
**Type** : Robustesse · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter

**Contexte** — `OfflineCache` stocke du JSON dans `SharedPreferences` (limité, non chiffré, pas de version de schéma).

**Critères d'acceptation**
- [ ] Clé de version de schéma ; cache invalidé proprement si le format change
- [ ] Données personnelles non stockées en clair (ou stockage chiffré)
- [ ] Taille maximale et politique d'expiration testées

### AMEL-026 — Guide de contribution pour les assistants IA (`CLAUDE.md`)
**Type** : Maintenabilité · **Priorité** : P3 · **Estimation** : XS · **Composant** : documentation

**Contexte** — Les assistants IA (Claude Code) contribuent au dépôt. Sans guide, ils redécouvrent à chaque session les
conventions, les commandes et les pièges du projet, et les relecteurs corrigent les mêmes écarts.

**Critères d'acceptation**
- [x] `CLAUDE.md` à la racine : commandes, conventions de PR, architecture, règles bloquantes de la CI, sécurité,
      pièges connus ; renvoie vers les documents de référence sans les dupliquer
- [x] Mis à jour dans la même PR que tout changement de convention qu'il décrit

### AMEL-027 — Refonte visuelle complète (design system v3)
**Type** : UX · **Priorité** : P2 · **Estimation** : L (découpé en lots) · **Composant** : flutter, design

**Contexte** — Le design system v2 (AMEL-022) a posé des tokens cohérents, mais seuls quelques écrans ont été
retravaillés et l'ensemble reste statique. Objectif : une interface remarquable, cohérente sur tous les écrans,
sans alourdir l'application (téléphones d'entrée de gamme, 3G).

**Critères d'acceptation**
- [x] Lot 1 — Fondations v3 : mouvement (`AppMotion`, transitions de page), dégradés, halo et motif étoilé,
      navigation flottante, bandeau `AeemgHero`, squelettes de chargement, retour tactile
- [x] Lot 1b — Accueil (bandeau, raccourcis, apparitions, chargements)
- [ ] Lot 2 — Social (fil, publication, détail, création) ; l'écran ne plante plus sans Supabase
- [ ] Lot 3 — Messagerie (liste et conversation)
- [ ] Lot 4 — Coran (accueil, lecteurs, test de récitation)
- [ ] Lot 5 — Hadiths, bibliothèque, quiz, suivi spirituel
- [ ] Lot 6 — Événements, notifications, paramètres, membres, profil, retours
- [ ] Lot 7 — Dons et finances
- [ ] Lot 8 — Splash et connexion
- [ ] Lot 9 — Administration
- [ ] Toutes les animations respectent « réduire les animations » ; aucun `BackdropFilter`
- [ ] Captures avant/après dans chaque PR
