# 0001 — Enregistrer les décisions d'architecture

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Décideurs** : Équipe projet (6 personnes)

## Contexte

Le projet a été développé par phases (0 → 9) sans trace écrite des choix techniques : les raisons de
Riverpod, de go_router, de la structure des migrations ou du modèle de rôles ne sont connues que de
leurs auteurs. Six personnes vont maintenant contribuer en parallèle ; sans référentiel commun, les
mêmes débats reviendront à chaque PR et des choix contradictoires apparaîtront (ex. rôle `staff`
ajouté en phase 9 en contradiction avec `is_staff()`).

## Décision

Nous consignons chaque décision structurante sous forme d'ADR (format Michael Nygard adapté) dans
`docs/adr/`, numérotés, en français, revus par PR selon le processus du [README](./README.md).
Les décisions déjà prises implicitement sont documentées rétroactivement (ADR 0002 à 0007, 0010, 0014, 0016, 0019, 0021).

## Conséquences

- ✅ Onboarding plus rapide, décisions explicites et contestables par PR.
- ⚠️ Coût d'écriture (~1 h par ADR) ; risque de documents obsolètes si on ne respecte pas la règle « remplacer, ne pas réécrire ».
- 🔧 Le modèle de PR contient une case « ADR nécessaire ? ».

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Wiki GitHub | Hors du dépôt, non versionné avec le code, pas de revue |
| Décisions dans les descriptions de PR | Introuvables après quelques mois |

## Vérification

Revue de PR : un changement listé dans « Quand écrire un ADR » sans ADR est bloqué par le Tech Lead.
