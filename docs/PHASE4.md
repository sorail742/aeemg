# Phase 4 — Évolution AEEMG

## Livré dans le code

| Fonctionnalité | Statut |
|---|---|
| Orange Money (init paiement) | Edge Function + app |
| SMS de secours | Edge Function + préférence utilisateur |
| Mode hors ligne étendu | Cache annonces + événements agenda |
| Langue Peul (navigation) | Paramètres → Peul |
| Export Google Calendar | Détail événement |
| Écran admin (retours beta) | Staff uniquement |
| Coran complet + audio + Mushaf | Terminé |

## Migrations SQL

Exécuter `supabase/migrations/20260413000000_phase4_evolution.sql`

## Edge Functions

```bash
supabase functions deploy orange-money-init
supabase functions deploy send-sms
supabase functions deploy event-reminders
```

### Variables secrets (Dashboard → Edge Functions)

| Variable | Usage |
|---|---|
| `ORANGE_MONEY_API_KEY` | API Orange Money Guinée |
| `ORANGE_MONEY_MERCHANT_ID` | Marchand AEEMG |
| `SMS_API_KEY` | AfricasTalking / Orange SMS |
| `SMS_SENDER_ID` | Expéditeur SMS |

## À activer en production

1. Clés API Orange Money réelles
2. Fournisseur SMS (AfricasTalking recommandé en Guinée)
3. Notifications push FCM (prochaine itération)
4. Téléchargement audio Coran hors ligne
