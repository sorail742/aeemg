# 0019 — Conventions des Edge Functions (Deno)

- **Statut** : Accepté
- **Date** : 2026-10-12
- **Tickets liés** : SEC-010, SEC-011, SEC-012, AMEL-012

## Contexte

Trois fonctions existantes, chacune avec sa propre gestion d'auth, d'erreurs et de réponses ; pas de CORS, imports
non figés, aucune validation d'entrée, aucun test.

## Décision

1. Structure : `supabase/functions/<nom-kebab>/index.ts` + `<nom>_test.ts` ; code commun dans `supabase/functions/_shared/`.
2. Dépendances figées dans `supabase/functions/deno.json` (`imports` avec versions exactes) + `deno.lock` versionné.
3. Chaque fonction déclare explicitement son **mode d'authentification** : `user` (JWT utilisateur vérifié via `auth.getUser`),
   `service` (secret dédié comparé en temps constant), ou `webhook` (signature du fournisseur).
4. Entrées validées par schéma (ex. `zod`) ; JSON invalide → 400 ; réponses d'erreur génériques (aucun message SQL brut).
5. CORS géré par `_shared/cors.ts` (origines par environnement) ; `OPTIONS` → 204.
6. Le client service role n'est créé qu'**après** vérification de l'appelant et n'est jamais utilisé pour des données fournies sans validation.
7. Logs structurés (ADR-0017) ; idempotence pour toute fonction déclenchée par cron ou webhook.

## Vérification

Job CI `edge-functions` : `deno fmt --check`, `deno lint`, `deno check`, `deno test`.
