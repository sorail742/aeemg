# 0025 — Branches `develop` (intégration) et `main` (production) — amende 0021

- **Statut** : Accepté
- **Date** : 2026-10-15
- **Décideurs** : Tech Lead
- **Tickets liés** : OPS-015, OPS-001, OPS-005

## Contexte

Avec l'[ADR-0021](./0021-workflow-git.md), toutes les PR allaient directement dans `main`, qui servait à la fois
d'intégration et de référence pour la production. Le Tech Lead veut séparer les deux : ce qui est fusionné
pendant le sprint ne doit pas être, de fait, ce qui part en production.

## Décision

- **`develop`** est la branche d'intégration et la branche par défaut des PR.
  - Les branches de travail partent de `develop` et y reviennent par PR, en **squash** (règles inchangées de
    l'ADR-0021 : nom, taille, un ticket par PR).
  - `develop` alimente l'environnement **staging** ([ADR-0011](./0011-environnements.md)).
- **`main`** est la branche de **production**. Elle ne reçoit que deux sortes de PR :
  - **Release** : une PR `develop` → `main`, titre `chore(release): vX.Y.Z`, fusionnée en **merge commit**,
    jamais en squash. Un squash créerait sur `main` un commit absent de `develop`, et chaque release suivante
    afficherait un diff faux ou des conflits. Le tag `vX.Y.Z` est ensuite posé sur `main` ([ADR-0016](./0016-versionnage-et-releases.md)).
  - **Correctif urgent** : `hotfix/<ID>-…` depuis `main`, PR vers `main`, puis `main` fusionné dans `develop`
    le jour même pour que le correctif n'y manque pas.
- Les deux branches sont protégées (OPS-001) : PR obligatoire, CI verte, pas de force-push ni de suppression.
- Dependabot vise `develop`.

## Conséquences

- ✅ La production ne change qu'au moment d'une release choisie ; `develop` peut accueillir plusieurs PR
  par jour sans risque pour les utilisateurs.
- ✅ Les contrôles CI tournent sur les PR vers les deux branches et sur chaque push sur l'une ou l'autre.
- ⚠️ Deux modes de fusion à connaître : squash vers `develop`, merge commit pour les releases. Il faut
  autoriser les deux dans les réglages du dépôt.
- ⚠️ Un hotfix doit être reporté dans `develop` (fusion de `main` dans `develop`).
- 🔧 Réglages GitHub (Tech Lead) : branche par défaut `develop`, ruleset sur `develop` et `main`, merge commits
  autorisés (OPS-001).

## Alternatives considérées

| Option | Pour | Contre | Raison du rejet |
|---|---|---|---|
| Trunk-based seul (ADR-0021) | Simple | Production = dernier merge | Décision du Tech Lead de séparer intégration et production |
| GitFlow complet (`release/*`, `feature/*`) | Très encadré | Lourd pour 6 personnes | `develop` + `hotfix/*` suffisent |

## Vérification

- Job `pr-quality / conventions` : une PR vers `main` qui ne vient ni de `develop` ni de `hotfix/*` est refusée.
  Une PR de release `develop` → `main` n'est soumise ni au contrôle du nom de branche, ni au ticket, ni à la taille.
- Workflow `release` : le tag doit pointer sur un commit présent dans `main`.
