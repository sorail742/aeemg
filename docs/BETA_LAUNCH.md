# Lancement Beta — AEEMG

## Prérequis

1. Migrations SQL à jour dans Supabase (jusqu'à `20260413000000_phase4_evolution.sql`)
2. Fichier `.env` avec `SUPABASE_URL` et `SUPABASE_ANON_KEY`
3. Auth email configurée ([SUPABASE_AUTH.md](./SUPABASE_AUTH.md))

---

## Build APK Android (beta)

```bash
flutter pub get
flutter build apk --release
```

APK : `build/app/outputs/flutter-apk/app-release.apk`

Partage direct aux testeurs (WhatsApp, Drive, etc.).

---

## Build Web

```bash
flutter build web --release
```

Déployer le dossier `build/web/` (Netlify, Vercel, Firebase Hosting).

---

## Checklist beta (20–30 membres)

- [ ] Inscription / connexion (mot de passe)
- [ ] Rejoindre le groupe Général et envoyer un message
- [ ] Consulter une annonce sur l'accueil
- [ ] RSVP à un événement dans l'agenda
- [ ] Faire un don test (statut « en attente »)
- [ ] S'inscrire bénévole (onglet Mosquée)
- [ ] Envoyer un retour beta (Profil → Retour beta)
- [ ] Vérifier préférences notifications

---

## Rappels événements automatiques

Edge Function `supabase/functions/event-reminders` :

```bash
supabase functions deploy event-reminders
```

Appeler quotidiennement (cron) :

```bash
curl -X POST https://fuumkjatgczkbxdpjduo.supabase.co/functions/v1/event-reminders \
  -H "Authorization: Bearer VOTRE_SERVICE_ROLE_KEY"
```

---

## Phase 4 (intégré)

- Orange Money : flux don avec numéro + Edge Function
- SMS de secours : Paramètres → toggle
- Hors ligne : annonces + agenda en cache
- Langue Peul : Paramètres → Peul
- Voir [PHASE4.md](./PHASE4.md)

## Reste pour production

- Clés API Orange Money et SMS réelles
- Notifications push FCM
- Publication Google Play / App Store
