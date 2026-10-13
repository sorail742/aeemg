# AEEMG — Plan de Développement par Phases

**Stack : Flutter + Supabase**  
**Version app :** 1.1.0+2

---

## Résumé statut

| Phase | Statut code | Action utilisateur |
|---|---|---|
| **0** Préparation | Terminé | Valider maquettes avec membres |
| **1** MVP | Terminé | — |
| **2** Complément | Terminé | — |
| **3** Lancement | Terminé | Beta 20–30 membres, publier stores |
| **4** Évolution | Terminé (code) | Clés API Orange Money + SMS, déploiement functions |

---

## Phase 3 — Terminé (code)

- Auth email + mot de passe
- Préférences notifications + badge
- Retours beta + écran admin staff
- Cache hors ligne (accueil + agenda)
- Coran complet (audio, Mushaf 604 pages)
- CI : analyze, test, build web
- Docs : [BETA_LAUNCH.md](./BETA_LAUNCH.md), [ADMIN_GUIDE.md](./ADMIN_GUIDE.md)

**Migration :** `20260412000000_phase3_launch.sql` + `20260411000000_email_auth.sql`

---

## Phase 4 — Terminé (code)

- Orange Money : `orange-money-init` + flux dons
- SMS secours : `send-sms` + toggle paramètres
- Langue Peul (navigation)
- Google Calendar export
- [PHASE4.md](./PHASE4.md)

**Migration :** `20260413000000_phase4_evolution.sql`

---

## Modules

| Module | Statut |
|---|---|
| Membres + profil | Terminé |
| Communication | Terminé |
| Événements + Agenda | Terminé |
| Notifications | Terminé |
| Finances + Dons | Terminé (+ Orange Money stub) |
| Mosquée | Terminé |
| Rappels islamiques | Terminé |
| Coran complet | Terminé |
| Admin beta | Terminé |
| Paramètres (FR/FF) | Terminé |

---

## Prochaine action

1. Exécuter `20260413000000_phase4_evolution.sql` dans Supabase
2. Déployer Edge Functions (voir PHASE4.md)
3. Build APK beta : `flutter build apk --release --dart-define-from-file=config/prod.json`
4. Lancer beta fermée (checklist BETA_LAUNCH.md)
