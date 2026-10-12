# 0005 — go_router pour la navigation et les deep links

- **Statut** : Accepté
- **Date** : 2026-10-12 (formalisation)
- **Tickets liés** : SEC-024, REL-014, AMEL-018, FEAT-040

## Contexte

L'app cible le Web (URL partageables) et doit gérer les liens d'authentification (`io.supabase.aeemg://login-callback/`)
et, demain, les liens de notifications push. `go_router` est déjà en place avec un `StatefulShellRoute` pour les onglets.

## Décision

- **go_router** est l'unique système de navigation ; pas de `Navigator.push` de nouvelles pages (dialogues exceptés).
- Toutes les routes sont déclarées dans `lib/core/router/` ; les chemins sont des constantes.
- Un `redirect` global gère l'authentification et les rôles ; un `errorBuilder` gère les 404.
- Les paramètres de route sont **validés** (`tryParse`, bornes) — jamais de `int.parse` ou de `!` non vérifié.

## Conséquences

- ✅ URL web propres, deep links unifiés, garde centralisée.
- ⚠️ Le fichier de routes grossit → découpage par feature (`features/x/x_routes.dart`) quand il dépasse 300 lignes.

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Navigator 1.0 | Pas d'URL web, pas de deep links déclaratifs |
| auto_route | Génération de code supplémentaire, migration sans bénéfice suffisant |

## Vérification

Tests de router (redirections, 404, paramètres invalides) exigés par REL-014 et SEC-024.
