# 0003 — Supabase comme backend unique

- **Statut** : Accepté
- **Date** : 2026-10-12 (formalisation)

## Contexte

Besoins : authentification, base relationnelle (finances, dons, membres), temps réel (messagerie),
stockage de fichiers, logique serveur (SMS, paiements, rappels), sans équipe d'exploitation ni budget
serveur. Projet Supabase existant (`project_id = fuumkjatgczkbxdpjduo`).

## Décision

Nous utilisons **Supabase** pour : Auth (email/mot de passe, OTP), PostgreSQL + RLS, Realtime, Storage,
Edge Functions (Deno). Le client Flutter parle **directement** à PostgREST pour les opérations simples
protégées par RLS ; toute opération qui implique un secret, un tiers (paiement, SMS, push) ou une règle
métier multi-tables passe par une **RPC SQL `SECURITY DEFINER`** ou une **Edge Function**.

## Conséquences

- ✅ Pas de serveur à maintenir ; offre gratuite suffisante pour la beta ; PostgreSQL standard (réversible, auto-hébergeable).
- ⚠️ La sécurité repose entièrement sur la RLS (ADR-0007) : une policy oubliée = fuite de données.
- ⚠️ Dépendance au fournisseur (hébergement hors Guinée, latence) ; quotas de l'offre gratuite (emails, Edge Functions).
- 🔧 Tests pgTAP obligatoires (ADR-0014), environnements séparés (ADR-0011).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| Firebase | NoSQL mal adapté aux finances/rapports ; règles de sécurité moins expressives que SQL ; verrouillage plus fort |
| Backend custom (NestJS/Django) + PostgreSQL | Coût d'hébergement et d'exploitation, équipe réduite |
| Appwrite / PocketBase auto-hébergé | Exploitation à notre charge |

## Vérification

Revue : aucune clé `service_role` côté client (contrôle `policy-checks`) ; tout accès tiers passe par `supabase/functions/`.
