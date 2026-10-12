# 0022 — Rendre rejouables les migrations historiques

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Décideurs** : Mainteneur du dépôt (demande de résolution complète du job `supabase / db`)
- **Amende** : [ADR-0010](./0010-migrations-versionnees.md) (règle 3)
- **Tickets liés** : REL-002, REL-003

## Contexte

Le job CI `supabase / db` rejoue toutes les migrations sur une base vierge (`supabase db reset`). Trois
migrations historiques échouaient : `fix_policies` (policies recréées), `phase7` (`uuid_generate_v4`),
`phase9` (valeur d'enum `staff` utilisée dans la transaction qui la crée). La production a été construite
autrement (`APPLY_ALL.sql`, Dashboard), si bien que l'historique n'avait jamais été rejoué.

Deux options : (a) corriger les migrations en place pour les rendre rejouables ; (b) remplacer
l'historique par une migration de base issue d'un `supabase db dump` de production.

## Décision

Option **(a)**. Une migration déjà appliquée peut être modifiée **uniquement** pour la rendre rejouable,
**sans changer le schéma final** (ajout de `drop ... if exists`, `on conflict do nothing`, fonction native
équivalente, cast pour éviter l'usage d'une valeur d'enum non validée). Chaque fichier ainsi modifié est
déclaré dans `supabase/migrations/AMENDED.txt` avec son ticket ; le job `migrations-lint` refuse toute
autre modification.

## Conséquences

- ✅ `supabase db reset` fonctionne : environnements locaux, staging et tests pgTAP possibles.
- ✅ Aucun impact sur les bases déjà migrées : elles ne rejouent pas les fichiers modifiés.
- ⚠️ L'historique ne reflète plus à l'octet près ce qui a été exécuté en production ; l'écart est limité
  et tracé dans `AMENDED.txt`.
- 🔧 L'option (b) reste possible plus tard (OPS-005) si la dérive entre production et migrations
  s'avère plus importante (à vérifier avec `supabase db diff --linked`).

## Vérification

Job `supabase / migrations-lint` (exceptions limitées à `AMENDED.txt`) et job `supabase / db`
(deux `db reset` successifs, lint, pgTAP).
