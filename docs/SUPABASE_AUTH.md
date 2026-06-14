# Authentification Email — AEEMG

## Méthode recommandée : Mot de passe

**Onglet « Mot de passe »** dans l'app — fonctionne immédiatement, sans config email.

1. Profil → Se connecter → **Mot de passe**
2. Pas de compte ? → **S'inscrire**
3. Email + mot de passe (6 caractères min.) → Connexion

### Supabase (une fois)

[Authentication → Providers → Email](https://supabase.com/dashboard/project/fuumkjatgczkbxdpjduo/auth/providers)

- **Enable Email** : ON
- **Confirm email** : **OFF** (recommandé pour les tests — sinon connexion bloquée avant confirmation)
- **Allow new users to sign up** : ON

### Erreur « Invalid login credentials »

Causes fréquentes :

1. **Compte créé par code email** — pas de mot de passe. Connectez-vous via « Code email », puis **Profil → Définir un mot de passe**.
2. **Confirm email activé** — confirmez l’email ou désactivez l’option ci-dessus.
3. **Pas encore inscrit** — utilisez « S'inscrire » avant « Se connecter ».

Pour repartir de zéro : Supabase → Authentication → Users → supprimer l’utilisateur → réinscription.

---

## Code OTP par email (optionnel)

Si vous recevez un email **sans code** (seulement un lien), Supabase envoie un **Magic Link** au lieu d'un OTP.

### Corriger en 3 étapes

**1.** Authentication → Providers → Email → activer **Email OTP**

**2.** Authentication → Email Templates → **Magic Link**  
Remplacer le contenu par :

```html
<h2>Code AEEMG</h2>
<p>Votre code de connexion :</p>
<h1>{{ .Token }}</h1>
<p>Ce code expire bientôt. Ne le partagez pas.</p>
```

**3.** Sauvegarder → retester l'onglet **Code email**

> Important : le template doit contenir `{{ .Token }}` et **pas seulement** `{{ .ConfirmationURL }}`.

---

## Migration SQL

`supabase/migrations/20260411000000_email_auth.sql`

---

## Limites gratuites

- ~3–4 emails/heure (quota Supabase dev)
- Production : SMTP custom (Resend, SendGrid) dans Project Settings → Auth → SMTP
