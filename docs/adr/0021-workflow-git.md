# 0021 — Workflow Git : trunk-based, branches courtes, squash merge

- **Statut** : Accepté — amendé par [0025](./0025-branches-develop-et-main.md) (`develop` pour l'intégration, `main` pour la production)
- **Date** : 2026-10-12
- **Tickets liés** : OPS-001, OPS-002

## Contexte

Six développeurs, un seul commit initial, aucune protection de branche. Les longues branches de fonctionnalité
provoqueraient des conflits massifs sur des fichiers comme `app_router.dart` ou les écrans géants.

## Décision

- `main` est toujours déployable (en staging) et protégée (ruleset OPS-001).
- Branches courtes (≤ 3 jours de vie) nommées `<type>/<ID-ticket>-<description-courte>` :
  `feat/FEAT-002-saisie-transactions`, `fix/REL-014-params-route`, `sec/SEC-001-role-escalation`,
  `refactor/…`, `docs/…`, `ci/…`, `chore/…`, `hotfix/…`.
- Une PR = un ticket (ou un sous-ticket) ; taille cible ≤ 400 lignes modifiées hors fichiers générés.
- Fonctionnalités incomplètes livrées derrière un **feature flag** plutôt que sur une branche longue.
- Merge par **squash** uniquement ; le titre de la PR (Conventional Commit) devient le message de commit.
- Rebase/merge de `main` dans sa branche avant revue si elle a divergé ; pas de force-push sur une branche
  où quelqu'un d'autre a poussé.

## Conséquences

- ✅ Intégration continue réelle, conflits petits et fréquents plutôt que rares et énormes.
- ⚠️ Besoin de feature flags pour les gros chantiers.

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| GitFlow (`develop`, `release/*`) | Lourd pour une équipe de 6 et un déploiement continu |
| Merge commits | Historique illisible ; squash + Conventional Commits = changelog propre |

## Vérification

Ruleset GitHub + job `pr-quality` (nom de branche, titre, taille).
