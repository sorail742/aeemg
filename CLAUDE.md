# CLAUDE.md — guide pour les assistants IA (et les nouveaux arrivants)

Application de gestion de l'**AEEMG** : Flutter (Android, iOS, Web) + Supabase (PostgreSQL/RLS, Auth, Storage,
Edge Functions Deno). Langue : **français** pour la documentation, les tickets, les commits et l'UI ;
**anglais** pour les identifiants de code.

Ce fichier résume les règles. Les textes de référence sont :
- [docs/team/REGLES_EQUIPE.md](docs/team/REGLES_EQUIPE.md) et [CONTRIBUTING.md](CONTRIBUTING.md) ;
- les ADR ([docs/adr/](docs/adr/README.md)), à respecter ;
- le backlog ([docs/tickets/](docs/tickets/README.md)).

## Commandes

```bash
flutter pub get
dart format <fichiers modifiés>          # la CI vérifie chaque fichier modifié EN ENTIER
flutter analyze                          # échoue aussi sur les « info »
flutter test
tool/ci/check_repo_policies.sh           # politiques du dépôt (secrets, couleurs en dur…)
tool/ci/check_migrations.sh origin/develop  # si supabase/migrations/ change
supabase test db                         # pgTAP, si supabase/ change (Docker requis)
(cd supabase/functions && deno task check)   # si supabase/functions/ change
tool/install_hooks.sh                    # hooks Git : format, analyse, politiques, message de commit
```

Lancer l'application : `flutter run --dart-define-from-file=config/dev.json` (copie de `config/example.json`).

## Avant d'écrire du code

- **Un ticket par changement** (`SEC-`, `REL-`, `DEL-`, `AMEL-`, `FEAT-`, `OPS-` ou `#123`). Une découverte en cours
  de route devient un nouveau ticket, jamais un élargissement silencieux.
- **Branches (ADR-0025)** : `develop` = intégration, `main` = production. Partir de `origin/develop` et ouvrir
  la PR **vers `develop`**. Vers `main` : seulement la release `develop` → `main` (merge commit) et `hotfix/*`.
- **Une PR par ticket**, branche `<type>/<ID>-<description>` (ex. `sec/SEC-025-permissions`).
- Titre de PR = message du commit squashé : `type(portée): description (ID)`.
  Types : `feat fix sec perf refactor test docs ci build chore revert style`.
- Taille : ≤ 400 lignes visées ; **> 1000 lignes bloque la CI**, sauf label `taille-justifiee`.
  Seul le Tech Lead pose ce label : ne jamais le poser sans son accord explicite.
- Remplir le modèle `.github/pull_request_template.md` (ticket, quoi et pourquoi, comment tester, impacts).

## Architecture (ADR-0006, ADR-0004)

```
lib/core/       config (Env, dart-define), router (go_router + route_guard.dart), theme (tokens), utils
lib/shared/     modèles et widgets partagés ; design system dans shared/widgets/ds/
lib/features/<f>/data/          repositories Supabase, modèles
lib/features/<f>/presentation/  écrans, widgets, providers
supabase/migrations/  schéma (source de vérité)   supabase/tests/  pgTAP   supabase/functions/  Deno
```

- `presentation` → `data`, jamais l'inverse. Une feature n'importe pas le `presentation` d'une autre.
- **Riverpod** pour l'état et l'injection :
  - repositories via `Provider` ;
  - nouveaux états d'écran en `Notifier`/`AsyncNotifier`, pas de nouveau `StateNotifier`. Les anciens
    `StateProvider` viennent de `flutter_riverpod/legacy.dart`.
- **Aucun appel Supabase dans un widget** : passer par un repository.
- Fichier ≤ 400 lignes, méthode `build` ≤ 150 lignes (sinon extraire un widget).
- Navigation : `lib/core/router/route_guard.dart` décide des accès, et il est testé. Une route est **publique par
  défaut**. Toute route réservée aux membres ou au bureau doit être ajoutée à `_authenticatedPrefixes` ou à
  `_staffPrefixes`, avec son test dans `test/route_guard_test.dart`.

## Règles qui font échouer la CI (`policy-checks`)

- **Couleurs** : jamais `Colors.*` hors de `lib/core/theme/`. Utiliser `AppColors` ; la correspondance est dans
  [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md). Utiliser aussi les composants `Aeemg*` de `shared/widgets/ds/`
  et `AppSpacing`, `AppRadius`, `AppTypography`.
- **Secrets** : aucun secret dans `lib/`, `web/`, `assets/`, `config/`. Le client ne connaît que l'URL et la
  clé anon (ADR-0009). Jamais de `service_role` côté client ; `config/*.json` est ignoré, sauf `example.json`.
- Fichiers interdits : `.env`, keystores, `key.properties`, comptes de service.

## Base de données et sécurité (ADR-0007, ADR-0008, ADR-0010)

- **La RLS est la frontière de sécurité.** Un contrôle fait seulement dans l'UI n'est pas un contrôle.
  Toute politique RLS nouvelle ou modifiée a son test pgTAP dans `supabase/tests/` : cas autorisé **et** cas refusé.
- Nouvelle migration : `supabase migration new <description>`, fichier `AAAAMMJJHHMMSS_description.sql`, idempotente.
  **Jamais modifier une migration déjà sur `develop` ou `main`** (seule exception : `AMENDED.txt`, ADR-0022).
- Pas de données de démo dans les migrations. Changement destructif = en deux releases.
- **Actions à demander avant de les faire** :
  - appliquer une migration, supprimer des données, déployer une fonction, toucher la production ;
  - plus généralement, toute action destructive ou visible à l'extérieur.

  Ne jamais contourner une confirmation de sécurité (ex. instruction destructive refusée par Supabase).
- Edge Functions (ADR-0019) :
  - logique testable séparée de `index.ts`, qui ne fait que le câblage (modèle : `admin-delete-user/handler.ts`
    et `handler.test.ts`, dépendances injectées) ;
  - mode d'authentification explicite ;
  - entrées validées, erreurs génériques sans SQL brut ;
  - client `service_role` créé seulement **après** la vérification de l'appelant.

## Qualité du code

- Messages d'erreur utilisateur en français, via `friendlySupabaseError` (`lib/core/utils/supabase_errors.dart`).
  Jamais `Text('$e')` (règle REL-008).
- Pas de `print` ; pas de `// ignore:` sans justification ni ticket ; `TODO(ID-TICKET): …`.
- Tout bug corrigé a son test de non-régression. Tests Dart dans `test/`, démarrage sur émulateur dans
  `integration_test/`.
- Permissions Android/iOS : demandées au moment de l'usage. Toute permission ajoutée ou retirée est justifiée dans
  [docs/PERMISSIONS.md](docs/PERMISSIONS.md).
- Toute décision structurante → un ADR (`docs/adr/0000-template.md`).

## Pièges connus

- **Version de Flutter** : celle de `.fvmrc` (OPS-014). Avec une autre version, `flutter pub get` réécrit la section
  `sdks` de `pubspec.lock` : ne pas committer ce changement.
- **Format** : le job `format` vérifie chaque fichier modifié en entier. Toucher un ancien fichier non formaté oblige
  à le reformater. Mettre ce reformatage dans un **commit séparé** pour la relecture ; il peut faire dépasser la
  limite de taille.
- **PR empilées** : une PR basée sur une autre branche fusionne dans cette branche, pas dans `develop`. La recibler
  sur `develop` après la fusion de sa base.
- **CI instable connue** :
  - téléchargements Gradle/Maven, NDK ;
  - cache Swift Package Manager du runner macOS (le job iOS retente déjà une fois) ;
  - émulateur Android : API 24 tourne seulement la nuit.

  Une seule relance au plus ; un deuxième échec est un vrai problème. Ne jamais désactiver un test pour passer.
- **Git** : jamais de force-push sur `main`, `develop` ni sur la branche d'un autre ; pas de commit vide pour relancer la CI ;
  fusion en squash.
