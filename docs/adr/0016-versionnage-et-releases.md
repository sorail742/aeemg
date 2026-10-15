# 0016 — SemVer, Conventional Commits et releases par tag

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Tickets liés** : AMEL-020, OPS-005, OPS-006

## Contexte

Version actuelle `1.1.0+2`, incrémentée à la main, sans changelog. Les stores exigent un `versionCode` strictement croissant.

## Décision

- **SemVer** `MAJEUR.MINEUR.CORRECTIF+BUILD` dans `pubspec.yaml` (source unique). MAJEUR : rupture de compatibilité
  avec les anciennes versions installées (API/schéma) ; MINEUR : fonctionnalité ; CORRECTIF : correction.
- **Conventional Commits** pour les titres de PR (squash) : `feat(events): …`, `fix(auth): …`, `sec(rls): …`,
  `refactor`, `perf`, `test`, `docs`, `ci`, `build`, `chore`, `revert`. `!` ou `BREAKING CHANGE:` pour une rupture.
- Release = PR `develop` → `main` (merge commit, ADR-0025) puis tag annoté `vX.Y.Z` sur `main` → workflow `release` (build, artefacts, CHANGELOG, déploiement prod après approbation).
- Pré-releases : `vX.Y.Z-beta.N` → distribution testeurs uniquement.
- Correctif urgent : branche `hotfix/…` depuis `main`, PR accélérée (1 approbation lead), tag CORRECTIF.

## Conséquences

- ✅ Changelog généré, historique lisible, releases reproductibles.
- ⚠️ Discipline sur les titres de PR (vérifiée en CI).

## Vérification

Job `pr-quality / title` (Conventional Commits) ; workflow `release` déclenché uniquement par tag.
