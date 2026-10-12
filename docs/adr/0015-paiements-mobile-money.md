# 0015 — Paiements mobile money pilotés par webhooks idempotents

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : SEC-008, SEC-009, SEC-011, FEAT-004, FEAT-005, FEAT-006

## Contexte

En Guinée, Orange Money et MTN MoMo dominent. L'Edge Function actuelle crée une session sans appeler l'API et
le client peut écrire lui-même le statut d'un don. Il s'agit d'argent : intégrité et traçabilité sont impératives.

## Décision

1. Le client ne fait que **demander** un paiement (Edge Function `payments-init`) ; il ne peut jamais écrire un statut.
2. Le statut d'un don ne change que par : le **webhook** du fournisseur (signature vérifiée), le job de
   **réconciliation** (interrogation de l'API), ou le **trésorier** (dons en espèces), via une RPC tracée.
3. **Idempotence** : `external_ref` unique (UUID), traitement du webhook dans une transaction qui ignore les doublons ;
   machine à états stricte (`initiated → pending → completed|failed|cancelled`, aucune transition depuis un état final).
4. Interface `PaymentProvider` (init, verifyWebhook, fetchStatus) avec une implémentation par fournisseur.
5. Montants en **GNF entiers** (`bigint`), jamais en `double` côté Dart ni `numeric` à décimales pour la monnaie.
6. Secrets d'API uniquement en secrets d'Edge Functions ; environnement sandbox en staging.

## Conséquences

- ✅ Impossible de falsifier un don depuis le client ; reprise automatique en cas de webhook perdu.
- ⚠️ Contrat marchand Orange/MTN à obtenir par le bureau (délai administratif).
- 🔧 Migration `numeric(12,2)` → `bigint` pour les montants (à planifier).

## Vérification

Tests Deno des transitions et des doublons ; tests pgTAP : aucun rôle client ne peut modifier `donations.status`.
