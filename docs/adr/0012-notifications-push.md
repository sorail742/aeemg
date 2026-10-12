# 0012 — Notifications push via FCM HTTP v1 depuis une Edge Function

- **Statut** : Proposé
- **Date** : 2026-10-12
- **Tickets liés** : FEAT-001, FEAT-029, AMEL-023, FEAT-008

## Contexte

Objectif n°1 du CDC : informer instantanément (62,5 % reçoivent l'info en retard). Seules des notifications
in-app (Realtime, app ouverte) existent. La table `push_device_tokens` est prête.

## Décision

- **Firebase Cloud Messaging** pour Android, iOS (via APNs) et Web, avec l'API **HTTP v1** (compte de service
  stocké en secret d'Edge Function).
- La table `notifications` reste la source de vérité. Un **Database Webhook** sur `INSERT` appelle l'Edge
  Function `push-dispatch` qui : lit les préférences, applique le mode silencieux, envoie aux tokens, purge les
  tokens invalides, déclenche le repli SMS si nécessaire (FEAT-008).
- Côté app : `firebase_messaging` uniquement pour le transport (pas d'Analytics ni autre service Firebase).

## Conséquences

- ✅ Standard, gratuit, un seul canal pour 3 plateformes.
- ⚠️ Ajout d'un projet Firebase (configuration par environnement) ; dépendance Google.
- ⚠️ iOS : compte Apple Developer requis (99 $/an).

## Alternatives considérées

| Option | Raison du rejet |
|---|---|
| OneSignal | Service tiers supplémentaire, données membres chez un tiers |
| Notifications locales + polling | Batterie, pas d'instantanéité |

## Vérification

Tests Deno de `push-dispatch` (préférences, silence, tokens invalides) ; test réel sur appareil avant release.
