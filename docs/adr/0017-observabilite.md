# 0017 — Observabilité : Sentry + logs structurés

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : OPS-008, OPS-009, REL-008, REL-010

## Contexte

Aucune remontée d'erreur : un crash chez un membre est invisible pour l'équipe ; les Edge Functions loggent de manière ad hoc.

## Décision

- **Sentry** (offre gratuite / sponsoring open source) pour Flutter et les Edge Functions, un projet par environnement.
- Données personnelles **interdites** dans les événements : `sendDefaultPii = false`, filtrage email/téléphone, identifiant utilisateur = UUID uniquement.
- Edge Functions : logs JSON (`{level, fn, request_id, msg, ...}`), jamais de token, numéro complet ou montant associé à une identité.
- Taux d'échantillonnage des traces : 10 % en prod.

## Conséquences

- ✅ Détection proactive, symbolication des crashs, alertes.
- ⚠️ Tiers supplémentaire ; quotas de l'offre gratuite.

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Firebase Crashlytics | Mobile uniquement (pas de Web ni Deno) |
| Logs Supabase seuls | Pas de crashs client |

## Vérification

Test de crash volontaire en staging à chaque release ; revue du scrubbing PII.
