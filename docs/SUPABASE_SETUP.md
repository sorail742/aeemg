# Configuration Supabase — AEEMG

**Projet :** `fuumkjatgczkbxdpjduo`  
**URL :** https://fuumkjatgczkbxdpjduo.supabase.co

---

## ⚠️ ÉTAPE OBLIGATOIRE — Erreur PGRST205

Si l'app affiche *« Could not find the table »* :

1. Ouvrez le [SQL Editor Supabase](https://supabase.com/dashboard/project/fuumkjatgczkbxdpjduo/sql/new)
2. Copiez **tout** le contenu de `supabase/APPLY_ALL.sql`
3. Cliquez **Run** (une seule fois)
4. Hot restart de l'app Flutter (`R`)

---

## 1. Configuration Flutter (ADR-0009)

La configuration est injectée à la compilation (plus de fichier `.env` embarqué, SEC-019). Copier
`config/example.json` en `config/dev.json` (ignoré par git) :

```json
{
  "APP_ENV": "dev",
  "SUPABASE_URL": "https://fuumkjatgczkbxdpjduo.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_..."
}
```

puis lancer `flutter run --dart-define-from-file=config/dev.json`. Voir [config/README.md](../config/README.md).

---

## 2. Authentification OTP téléphone

### Erreur « Unsupported phone provider »

Le fournisseur SMS n'est pas activé. Deux options :

### Option A — Numéros de test (développement)

1. Dashboard → **Authentication** → **Phone** → **Enable**
2. Section **Phone testing** → ajouter :
   - Numéro : `+224624284874` (votre numéro)
   - Code fixe : `123456`
3. Dans l'app, utilisez ce numéro et le code `123456`

### Option B — Production (Twilio)

1. Créez un compte [Twilio](https://www.twilio.com/)
2. Dashboard Supabase → **Authentication** → **Phone**
3. Renseignez Account SID, Auth Token, Message Service SID
4. Activez Phone provider

---

## 3. Authentification email (gratuite)

Guide : [SUPABASE_AUTH.md](./SUPABASE_AUTH.md)  
Migration : `supabase/migrations/20260411000000_email_auth.sql`

---

## 4. CLI Supabase (optionnel)

```powershell
npm install -g supabase
supabase login
cd c:\Users\keith\aeemg\aeemg
supabase link --project-ref fuumkjatgczkbxdpjduo
supabase db push
```

### Réparer l'historique après le renommage de la migration phase 9 (REL-001)

Les migrations `phase8_admin_fixes` et `phase9_admin_fixes` portaient la même version
`20260614000000` ; la phase 9 est désormais `20260614000100_phase9_admin_fixes.sql`.
Sur une base **déjà migrée**, vérifier d'abord ce que la CLI croit avoir appliqué :

```bash
supabase migration list --linked
```

- Si le contenu de la phase 9 est **déjà présent** en base (appliqué via `APPLY_ALL.sql` ou le
  Dashboard) mais que `20260614000100` apparaît comme non appliquée, l'enregistrer sans la rejouer :

  ```bash
  supabase migration repair --status applied 20260614000100 --linked
  ```

- Si la phase 9 n'a **jamais** été exécutée, ne rien réparer : `supabase db push` l'appliquera.
  (Attention : elle échoue tant que REL-002 n'est pas corrigé — enum `staff` utilisé dans la même
  transaction que sa création.)

En cas de doute, vérifier en SQL que les policies `Staff can create events` existent sur
`public.events` : si oui, la phase 9 est déjà appliquée.

### Production : historique initialisé le 2026-10-13 (ADR-0024)

La production n'avait aucun historique de migrations. Les 13 migrations historiques
(`20260407000000` → `20260614000100`) y sont marquées appliquées, et la migration idempotente
`20260615000000_reconciliation_production.sql` aligne le schéma. Ensuite :

```bash
supabase migration list --linked   # les versions historiques doivent apparaître « Remote »
supabase db push                    # applique la réconciliation puis les migrations de sécurité
```

Ne plus modifier le schéma de production à la main (Dashboard, éditeur SQL) : toute modification
passe par une migration versionnée (ADR-0010).

---

## 5. Vérifier

Après migration SQL + hot restart :

- **Agenda** : calendrier sans erreur
- **Messages** : groupe « Général AEEMG » visible (connecté)
- **Mosquée** : besoins tapis / eau affichés
- **Connexion** : OTP avec numéro de test

---

*AEEMG | Supabase setup*
