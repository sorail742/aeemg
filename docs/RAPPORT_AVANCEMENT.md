# Rapport d'avancement — AEEMG

**Date** : 12 octobre 2026 · **Périmètre** : audit du dépôt, outillage d'équipe, CI, premiers correctifs bloquants.

---

## 1. Synthèse

| Indicateur | Avant | Aujourd'hui |
|---|---|---|
| L'application compile (`flutter analyze`, `flutter test`, build web/Android) | ❌ CI de `main` rouge depuis le premier commit | ✅ vert (PR #137 fusionnée) |
| Les migrations se rejouent sur une base vierge (`supabase db reset`) | ❌ 4 migrations en échec (version dupliquée, policy recréée, `uuid_generate_v4`, enum `staff`) | ✅ vert ×2 (PR #138 fusionnée, PR #139 en attente) |
| Tests de sécurité de la base (pgTAP) | aucun | 4 tests dont 3 failles connues documentées (`todo`) |
| Contrôles CI automatisés | 1 workflow (analyse, tests, build web) | 8 workflows, 21 jobs : tous verts sur la PR #2 |
| Backlog | inexistant | 135 tickets dont 5 livrés ; 134 issues GitHub |
| Décisions d'architecture | non écrites | 22 ADR |
| Règles d'équipe (6 personnes) | aucune | `docs/team/REGLES_EQUIPE.md`, `CONTRIBUTING.md`, `SECURITY.md`, CODEOWNERS, modèles PR/issues |

**Point d'attention majeur** : le test pgTAP SEC-001 a confirmé sur une vraie base Supabase qu'**un membre
peut se promouvoir `super_admin`** (« have: super_admin, want: member »). Tant que SEC-001 et les autres
tickets P0 de sécurité ne sont pas livrés, l'application ne doit pas être ouverte à de vrais membres.

---

## 2. Ce qui a été fait

### 2.1 Pull requests

| PR | Contenu | État |
|---|---|---|
| #2 | Backlog, ADR, règles d'équipe, CI complète, scripts, premier test pgTAP, ce rapport | Ouverte, CI verte, en attente de revue |
| #137 | REL-016 : l'application compile à nouveau (`admin_screen.dart`, onglet Hizb masqué, `AdhanService` tolérant sur Web, 33 avertissements d'analyse corrigés, test d'accueil remis en état) | ✅ Fusionnée |
| #138 | REL-001 : version unique pour la migration phase 9 + procédure `migration repair` | ✅ Fusionnée |
| #139 | REL-003 / REL-002 : migrations historiques rendues rejouables (ADR-0022) | Ouverte, en attente de revue (son contenu est déjà reporté dans #2) |

### 2.2 Documentation produite (`docs/`)

| Dossier / fichier | Contenu |
|---|---|
| `tickets/` | 135 tickets (SEC 26, REL 16, DEL 12, AMEL 25, FEAT 43, OPS 14) avec critères d'acceptation, priorités, DoR/DoD, ordre de traitement |
| `adr/` | 22 ADR (Flutter, Supabase, Riverpod, go_router, architecture, RLS, rôles, configuration, migrations, environnements, push, i18n, tests, paiements, versions, observabilité, médias privés, Edge Functions, hors ligne, workflow Git, migrations rejouables) |
| `team/REGLES_EQUIPE.md` | Rôles des 6 membres et suppléants, rituels, Git, revue de code, sécurité, incidents, onboarding |
| `CI.md` | Description de chaque job, état attendu, variables de dépôt pour relever les exigences |
| `SUPABASE_SETUP.md` | Procédure de réparation de l'historique des migrations |

### 2.3 Intégration continue

Tous les jobs suivants sont **verts** sur la PR #2 (commit `86ce8e6`) :

| Workflow | Jobs |
|---|---|
| `flutter` | format, analyze, test (+ couverture), build-web (+ taille), policy-checks |
| `compatibility` | android stable, android beta (informatif), web Wasm ; iOS et émulateur hors PR |
| `security` | gitleaks, osv-scanner ; dependency-review désactivé tant que le *Dependency graph* n'est pas activé |
| `codeql` | TypeScript (Edge Functions), GitHub Actions |
| `supabase` | migrations-lint, db (reset ×2, lint, pgTAP) |
| `edge-functions` | fmt, lint, typecheck, tests Deno |
| `pr-quality` | titre Conventional Commit, branche, ticket, taille |
| `release` | build signé AAB/APK + web + SBOM sur tag `vX.Y.Z` (non encore exécuté) |

### 2.4 Problèmes résolus en cours de route

| Problème | Résolution |
|---|---|
| Le code de `main` ne compilait pas | #137 (REL-016) |
| Le widget des heures de prière plantait sur le Web (notifications locales absentes) | #137 |
| Version de migration `20260614000000` dupliquée | #138 (REL-001) |
| `fix_policies`, `phase7`, `phase9` non rejouables | #139 (REL-003, REL-002) + ADR-0022 |
| Faux positif gitleaks dans la doc | `.gitleaks.toml` (placeholders `VOTRE_…`) |
| PR #2 > 1000 lignes, « Dependency graph » inactif | label `taille-justifiee`, job conditionné par variable |

### 2.5 Tickets livrés

REL-001, REL-002, REL-003, REL-016, DEL-002 (marqués « ✅ Livré » dans `docs/tickets/`). DEL-008 (README)
était déjà livré avec #2.

---

## 3. Ce qui reste à faire

### 3.1 Actions immédiates du mainteneur (sans code)

| # | Action | Ticket |
|---|---|---|
| 1 | Relire et fusionner **#139**, puis **#2** | — |
| 2 | Après fusion de #138/#139 : sur chaque base déjà migrée, `supabase migration list --linked` puis `migration repair` si nécessaire (`docs/SUPABASE_SETUP.md`) | REL-001 |
| 3 | Protéger `main` (PR obligatoire, 2 approbations, checks requis listés dans OPS-001) | OPS-001 (#122) |
| 4 | Remplacer `@sorail742` dans `.github/CODEOWNERS` par les comptes des 6 membres | OPS-002 (#123) |
| 5 | Activer Dependency graph, Dependabot, secret scanning + push protection ; puis variable `DEPENDENCY_REVIEW=true` | OPS-004 (#125) |
| 6 | Fermer l'issue DEL-002 (#44), livrée par #137 sans mot-clé de fermeture | DEL-002 |
| 7 | Créer le GitHub Project (colonnes Backlog → Done) | OPS-013 (#134) |

### 3.2 Décisions en attente

| Décision | Options | Tickets |
|---|---|---|
| Onglet Hizb du Coran | table des 60 débuts de hizb validée par le référent, ou masquage définitif | REL-016 (suivi) |
| Rôle `staff` | le garder ou le fusionner avec `moderator` / `section_lead` (proposé par ADR-0008) | SEC-021, DEL-007 |
| ADR « Proposé » | 0008 rôles, 0009 configuration, 0011 environnements, 0012 push, 0013 i18n, 0015 paiements, 0017 observabilité, 0018 médias, 0020 hors ligne | — |
| Identifiant Android définitif et keystore | `org.aeemg` (décidé, ADR-0023) | SEC-020 (#21) |

### 3.3 Tickets P0 restants (bloquants avant toute mise en production)

| Ticket | Issue | Sujet |
|---|---|---|
| SEC-001 | #1 | Un membre peut se donner le rôle `super_admin` (**confirmé par pgTAP**) |
| SEC-003 | #4 | Auto-ajout dans n'importe quel groupe ou conversation privée |
| SEC-004 | #5 | `group_invitations` lisible et modifiable par des anonymes (**confirmé par pgTAP**) |
| SEC-006 | #7 | Médias de messagerie dans des buckets publics |
| SEC-008 | #9 | Statut des dons et paiements falsifiable |
| SEC-010 | #11 | Edge Function `event-reminders` sans authentification |
| SEC-020 | #21 | Signature release Android et identifiant définitifs |
| AMEL-008 | #61 | Tests pgTAP pour chaque policy |
| FEAT-038 | #81 | Suppression de compte par l'utilisateur (exigence stores) |
| OPS-001 / OPS-002 | #122 / #123 | Protection de branche, CODEOWNERS |

Ordre recommandé : SEC-001 → SEC-003/004 → SEC-008 → SEC-010 → SEC-006 (avec AMEL-008 au fil de l'eau),
puis la conformité stores (SEC-020, FEAT-038, FEAT-037, FEAT-043). Chaque correctif de sécurité doit
retirer le `todo()` correspondant dans `supabase/tests/000_security_baseline.test.sql`.

### 3.4 Dette suivie par la CI (avertissements de `policy-checks`)

| Règle | Avertissements | Ticket qui la rendra bloquante |
|---|---|---|
| `raw-error` (exceptions brutes affichées) | ~23 | REL-008 |
| `file-size` (> 400 lignes) | 5 | AMEL-001 |
| `dart-io` (casse le Web) | 4 | AMEL-011 |
| `presentation-supabase` | 4 | AMEL-002 |
| `android-release` | 2 | SEC-020 |
| `env-asset` | 1 | SEC-019 |
| `todo-ticket` | 3 | — |

Le formatage `dart format` n'est vérifié que sur les fichiers modifiés : reformater tout le dépôt en un
commit (AMEL-024) puis passer la variable `FORMAT_SCOPE=all`.

### 3.5 Reste du backlog

130 tickets ouverts (5 livrés sur 135) : 26 SEC, 12 REL, 11 DEL, 25 AMEL, 43 FEAT, 14 OPS. Détail et
priorités dans `docs/tickets/`, suivi dans les issues GitHub.

---

## 4. Limites des vérifications

- Le build iOS n'a pas encore été exécuté (job réservé à `main`, aux builds de nuit et au déclenchement manuel).
- Les migrations ont été validées par la CI sur l'image Supabase ; en local, seulement sur PostgreSQL 16 avec
  les schémas Supabase simulés (registres d'images Docker inaccessibles depuis l'environnement de travail).
- La base de production n'a pas été consultée : l'écart éventuel entre la production et les migrations
  reste à mesurer (`supabase db diff --linked`, OPS-005).
- Le workflow `release` n'a jamais tourné : il exige les secrets de signature (OPS-003, SEC-020).
