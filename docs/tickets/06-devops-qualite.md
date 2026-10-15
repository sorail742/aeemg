# Tickets — DevOps, CI/CD & qualité (`OPS`)

La CI livrée avec ce backlog est décrite dans [docs/CI.md](../CI.md). Ces tickets couvrent son
activation, ce qui reste à brancher et l'exploitation.

---

### OPS-001 — Protéger la branche `main` et rendre les checks obligatoires
**Type** : DevOps · **Priorité** : P0 · **Estimation** : XS · **Composant** : github

**Critères d'acceptation**
- [ ] Ruleset `main` : PR obligatoire, 2 approbations (dont 1 CODEOWNER), dismiss des approbations sur nouveau push, conversation résolue, historique linéaire (squash merge uniquement), pas de force-push ni suppression
- [ ] Checks requis : `flutter / format`, `flutter / analyze`, `flutter / test`, `flutter / build-web`, `policy-checks`, `pr-quality / title`, `security / secrets`, `security / dependencies`, `edge-functions / check` ; `supabase / db` dès que REL-001/002 sont livrés
- [ ] Capture de la configuration jointe au ticket

### OPS-002 — Créer les équipes GitHub et compléter `CODEOWNERS`
**Type** : DevOps · **Priorité** : P0 · **Estimation** : XS · **Composant** : github

**Contexte** — `.github/CODEOWNERS` référence des équipes (`@sorail742/...`) à créer, ou à remplacer par des logins.

**Critères d'acceptation**
- [ ] Équipes `aeemg-leads`, `aeemg-flutter`, `aeemg-backend`, `aeemg-qa` créées (ou logins nominatifs)
- [ ] Chaque chemin du dépôt a au moins 2 propriétaires (pas de point unique de défaillance)

### OPS-003 — Secrets et variables CI
**Type** : DevOps · **Priorité** : P1 · **Estimation** : S · **Composant** : github, ci
**Dépendances** : AMEL-013, SEC-020

**Critères d'acceptation**
- [ ] Environnements GitHub `staging` et `production` (prod : approbation manuelle d'un lead)
- [ ] Secrets : `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `SUPABASE_PROJECT_REF`, `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEY_PROPERTIES`, (iOS ultérieurement) — jamais en clair dans les workflows
- [ ] Rotation documentée (qui, quand, comment)

### OPS-004 — Activer Dependabot, CodeQL, secret scanning et push protection
**Type** : DevOps / Sécurité · **Priorité** : P1 · **Estimation** : XS · **Composant** : github

**Critères d'acceptation**
- [ ] Paramètres du dépôt : Dependency graph, Dependabot alerts & security updates, Secret scanning + push protection, Private vulnerability reporting activés
- [ ] Première vague de PR Dependabot triée

### OPS-005 — Déploiement continu des migrations et Edge Functions
**Type** : DevOps · **Priorité** : P1 · **Estimation** : M · **Composant** : ci, supabase
**Dépendances** : REL-001, REL-002, OPS-003

**Critères d'acceptation**
- [ ] Merge sur `main` → `supabase db push` + `supabase functions deploy` vers **staging**
- [ ] Tag `v*` → même déploiement vers **production** après approbation manuelle
- [ ] `supabase db diff` en dry-run publié en commentaire de PR quand `supabase/migrations/` change
- [ ] Procédure de rollback (migration corrective + PITR) documentée

### OPS-006 — Distribution beta automatisée
**Type** : DevOps · **Priorité** : P2 · **Estimation** : M · **Composant** : ci, android, ios
**Dépendances** : SEC-020

**Critères d'acceptation**
- [ ] Tag `v*-beta.*` → AAB vers Google Play « test interne » (ou Firebase App Distribution) ; IPA vers TestFlight quand le compte Apple est disponible
- [ ] Web staging déployé à chaque merge (Vercel/Netlify/Firebase Hosting) avec URL de prévisualisation par PR

### OPS-007 — Sauvegardes et plan de reprise
**Type** : DevOps / Fiabilité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase

**Critères d'acceptation**
- [ ] PITR ou sauvegarde quotidienne activée en prod ; export hebdomadaire `pg_dump` chiffré hors Supabase
- [ ] Test de restauration réalisé une fois par trimestre (compte rendu dans `docs/runbooks/`)
- [ ] RPO ≤ 24 h, RTO ≤ 4 h documentés

### OPS-008 — Crash reporting et journalisation
**Type** : DevOps / Fiabilité · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter, edge-functions
**Dépendances** : REL-010, [ADR-0017](../adr/0017-observabilite.md)

**Critères d'acceptation**
- [ ] Sentry (ou équivalent) intégré : Flutter (erreurs Dart + natives) et Edge Functions ; DSN par environnement
- [ ] Aucune donnée personnelle envoyée (scrubbing email/téléphone, `sendDefaultPii = false`)
- [ ] Symboles/source maps uploadés par le workflow de release
- [ ] Alerte sur pic d'erreurs vers le canal de l'équipe

### OPS-009 — Supervision et alertes de production
**Type** : DevOps · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase

**Critères d'acceptation**
- [ ] Alertes : taux d'erreur Edge Functions, échecs `event-reminders`, sessions de paiement bloquées, quota SMS, espace disque DB
- [ ] Runbook par alerte dans `docs/runbooks/`

### OPS-010 — Tests d'intégration sur émulateur en CI
**Type** : Qualité · **Priorité** : P2 · **Estimation** : M · **Composant** : ci
**Dépendances** : AMEL-007

**Critères d'acceptation**
- [ ] Dossier `integration_test/` ; job `compatibility / android-integration` (émulateur API 24 et 34) exécuté sur `main` et chaque nuit
- [ ] Backend : Supabase local démarré dans le job avec `seed.sql`

### OPS-011 — Matrice de compatibilité appareils
**Type** : Compatibilité · **Priorité** : P2 · **Estimation** : S · **Composant** : android, ios

**Contexte** — Le CDC vise Android 6+ et iOS 12+, mais les versions minimales réelles dépendent de Flutter et
des plugins (Flutter récent : Android 7 / API 24 minimum, iOS 13+).

**Critères d'acceptation**
- [ ] `minSdk` et `IPHONEOS_DEPLOYMENT_TARGET` fixés explicitement et documentés (ADR-0002 mis à jour) ; écart avec le CDC validé par le PO
- [ ] Liste d'appareils de test physiques (dont un Android d'entrée de gamme 2 Go RAM) et checklist de recette

### OPS-012 — Hooks Git locaux
**Type** : Qualité · **Priorité** : P3 · **Estimation** : XS · **Composant** : outillage

**Critères d'acceptation**
- [ ] Hook `pre-commit` (format + analyse des fichiers indexés) et `commit-msg` (Conventional Commits) installables via `tool/install_hooks.sh`
- [ ] Documenté dans CONTRIBUTING.md

### OPS-013 — Labels et tableau de projet GitHub
**Type** : DevOps · **Priorité** : P1 · **Estimation** : XS · **Composant** : github

**Critères d'acceptation**
- [ ] Tickets de `docs/tickets/` importés via `tool/create_github_issues.py`
- [ ] GitHub Project avec colonnes `Backlog → Ready → In progress → In review → Done` et champs Priorité, Estimation, Sprint

### OPS-014 — Fixer la version de Flutter utilisée par l'équipe et la CI
**Type** : Fiabilité · **Priorité** : P1 · **Estimation** : XS · **Composant** : ci, outillage

**Contexte** — La CI utilise `channel: stable` (version flottante) : un nouveau Flutter peut casser la CI sans
changement de code, et chaque développeur peut avoir une version différente.

**Critères d'acceptation**
- [x] Fichier `.fvmrc` (ou `.tool-versions`) avec la version exacte ; la CI lit cette version
- [x] Montée de version Flutter = PR dédiée, testée sur la matrice de compatibilité (procédure dans CONTRIBUTING.md)
