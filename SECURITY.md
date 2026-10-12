# Politique de sécurité

## Signaler une vulnérabilité

**N'ouvrez pas d'issue publique.** Utilisez le
[signalement privé de vulnérabilité GitHub](../../security/advisories/new) (onglet *Security* du dépôt)
ou contactez directement le Tech Lead.

Merci d'indiquer : composant concerné, étapes de reproduction, impact estimé. Ne testez jamais sur des données
réelles de membres et n'exfiltrez aucune donnée.

## Engagements

| Étape | Délai |
|---|---|
| Accusé de réception | 3 jours ouvrés |
| Évaluation et priorisation | 7 jours |
| Correctif d'une faille critique | 14 jours (en priorité absolue, ticket P0) |

## Périmètre

Application Flutter (Android, iOS, Web), schéma et policies Supabase, Edge Functions, workflows CI.

## Bonnes pratiques internes

- Aucun secret dans le dépôt ; la clé anon/publishable est la seule clé autorisée côté client.
- Toute policy RLS est testée (pgTAP) — voir [ADR-0007](docs/adr/0007-rls-frontiere-de-securite.md).
- Revue du référent sécurité obligatoire pour `supabase/**`, l'authentification, les paiements et les données personnelles.
