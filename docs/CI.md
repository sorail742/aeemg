# Intégration continue — AEEMG Connect

Tous les workflows sont dans `.github/workflows/`. Chaque job couvre un ou plusieurs attributs qualité.

## Vue d'ensemble

| Workflow | Job | Déclencheur | Attribut qualité | Bloquant sur `main` |
|---|---|---|---|---|
| `flutter` | `format` | PR, push | Maintenabilité | ✅ |
| | `analyze` | PR, push | Maintenabilité, fiabilité | ✅ |
| | `test` (+ couverture, ordre aléatoire) | PR, push | Fiabilité, robustesse | ✅ |
| | `build-web` (+ budget de taille) | PR, push | Compatibilité, performance | ✅ |
| | `policy-checks` | PR, push | Sécurité, maintenabilité | ✅ |
| `compatibility` | `android (stable)` | PR (code/plateformes), push, nuit | Compatibilité | ✅ |
| | `android (beta)` | idem | Compatibilité future | ❌ informatif |
| | `web (wasm)` | idem | Compatibilité, performance | ❌ jusqu'à AMEL-011 |
| | `ios (no codesign)` | push `main`, nuit | Compatibilité | ❌ (hors PR, coût macOS) |
| | `android integration (API 24, 34)` | push `main`, nuit (si `integration_test/` existe) | Fiabilité, compatibilité | ❌ jusqu'à OPS-010 |
| `security` | `secrets (gitleaks)` | PR, push, hebdo | Sécurité | ✅ |
| | `dependencies (osv-scanner)` | PR, push, hebdo | Sécurité | ✅ |
| | `dependency-review` | PR | Sécurité, conformité licences | ✅ |
| `codeql` | `javascript-typescript`, `actions` | PR (functions/workflows), push, hebdo | Sécurité (SAST) | ✅ |
| `supabase` | `migrations-lint` | PR/push sur `supabase/**`, hebdo | Fiabilité, maintenabilité | ✅ après REL-001 |
| | `db (reset ×2 + lint + pgTAP)` | idem | Sécurité (RLS), fiabilité, robustesse | ✅ après REL-001/002 |
| `edge-functions` | `check` (fmt, lint, typecheck, test) | PR/push sur `supabase/functions/**` | Sécurité, maintenabilité, fiabilité | ✅ |
| `pr-quality` | `title` | PR | Maintenabilité (historique) | ✅ |
| | `conventions` (branche, ticket, taille) | PR | Maintenabilité, travail d'équipe | ✅ |
| `release` | `verify`, `android`, `web`, `publish` | tag `vX.Y.Z` | Fiabilité, sécurité (signature, SBOM) | — |
| Dependabot | — | hebdomadaire | Sécurité, maintenabilité | — |

## État initial attendu (honnêteté)

Les nouveaux contrôles révèlent des problèmes **existants** ; c'est voulu. À la mise en place :

- **`flutter / analyze`, `flutter / test`, `compatibility / android`, `web (wasm)` échouent** : le code de `main`
  ne compile pas (déjà rouge avant cette CI) — ticket P0 REL-016.

- `supabase / migrations-lint` et `supabase / db` **échouent** tant que REL-001 (versions de migration dupliquées)
  et REL-002 (enum `staff` utilisé dans la même transaction) ne sont pas corrigés → ce sont des tickets P0.
- `policy-checks` passe mais émet ~40 **avertissements** (fichiers > 400 lignes, `dart:io`, `.env` en asset,
  signature debug, exceptions brutes affichées, TODO sans ticket). Chaque avertissement pointe vers son ticket.
- `security / dependencies` peut échouer si des dépendances du `pubspec.lock` ont des vulnérabilités connues :
  mettre à jour la dépendance (PR Dependabot) ou documenter l'exception.
- Les tests pgTAP marqués `todo()` (SEC-001, SEC-004, SEC-013) documentent des failles connues sans bloquer la suite.

## Faire monter le niveau d'exigence

Les seuils sont pilotés par des **variables de dépôt** (Settings → Secrets and variables → Actions → Variables),
sans modifier les workflows :

| Variable | Défaut | Rôle | Quand la changer |
|---|---|---|---|
| `COVERAGE_MIN` | `0` | Couverture minimale (%) | +10 points par trimestre (AMEL-007) |
| `WEB_BUDGET_KB` | `0` (rapport) | Budget gzip de `main.dart.js` | Après mesure initiale (AMEL-010) |
| `FORMAT_SCOPE` | `changed` | `all` = tout le dépôt | Après AMEL-024 |
| `POLICY_ERROR_RULES` | `secrets forbidden-files service-role` | Règles de `policy-checks` bloquantes | Ajouter `env-asset` (SEC-019), `dart-io` (AMEL-011), `file-size` (AMEL-001), `presentation-supabase` (AMEL-002), `raw-error` (REL-008), `todo-ticket`, `no-print` |
| `PR_MAX_LINES` | `1000` | Taille max d'une PR (contournable par le label `taille-justifiee`) | Réduire à 600 quand l'équipe est rodée |
| `DEPENDENCY_REVIEW` | absent | `true` active le job `dependency-review` | Dès que « Dependency graph » est activé (OPS-004) |

Pour un test pgTAP `todo()` : retirer le `todo()` dans la PR qui corrige la faille.

## Exécuter les contrôles en local

```bash
dart format lib test && flutter analyze && flutter test --coverage
tool/ci/check_repo_policies.sh
tool/ci/check_migrations.sh origin/main
supabase start && supabase db reset && supabase db lint && supabase test db
(cd supabase/functions && deno task check)
```

## Secrets nécessaires (OPS-003)

| Secret | Environnement GitHub | Utilisé par |
|---|---|---|
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PROPERTIES` | `production` | `release / android` |
| `APP_ENV_FILE` (contenu de configuration prod, valeurs publiques uniquement) | `production` | `release` |
| `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `SUPABASE_PROJECT_REF` | `staging`, `production` | déploiement (OPS-005, à venir) |

## Bonnes pratiques appliquées

- `permissions: contents: read` par défaut, élargies job par job ; `concurrency` pour annuler les exécutions obsolètes.
- Aucune action tierce ne reçoit de secret sauf la release ; secrets effacés du runner après usage.
- Versions des actions mises à jour par Dependabot (épinglage par SHA recommandé une fois l'équipe GitHub en place).
- Les outils (gitleaks, osv-scanner) sont installés en version figée.
