# Authentification Email — AEEMG

## Méthode recommandée : Mot de passe

**Onglet « Mot de passe »** dans l'app.

1. Profil → Se connecter → **Mot de passe**
2. Pas de compte ? → **S'inscrire**
3. Email + mot de passe (**10 caractères minimum, lettres et chiffres**) → lien de confirmation reçu par
   email → Connexion

## Politique d'authentification (SEC-022)

La configuration locale est versionnée dans `supabase/config.toml` (`[auth]`, `[auth.email]`,
`[auth.captcha]`, `[auth.email.smtp]`, `[auth.rate_limit]`). En staging et en production, les mêmes
valeurs se règlent dans le Dashboard (un `supabase config push` les appliquerait aussi, mais il
pousse tout le fichier : à réserver au Tech Lead).

| Réglage | Valeur | Dashboard (production) |
|---|---|---|
| Longueur minimale du mot de passe | 10 | Authentication → Providers → Email → *Minimum password length* |
| Composition | lettres et chiffres | même écran → *Password requirements* |
| Mots de passe ayant fuité (HaveIBeenPwned) | **activé** | Authentication → Attack Protection → *Prevent use of leaked passwords* (offre Pro) |
| Confirmation d'email | **activée** | Providers → Email → *Confirm email* : **ON** |
| Changement de mot de passe sécurisé | activé | Providers → Email → *Secure password change* |
| Délai entre deux emails | 60 s | Rate Limits |
| CAPTCHA (Turnstile) | à activer quand le widget sera livré | Attack Protection → *Enable Captcha protection* |
| SMTP | Resend (`smtp.resend.com:465`, utilisateur `resend`) | Authentication → SMTP Settings |
| Durée du JWT | 3600 s (défaut) | Settings → JWT |

- La validation du mot de passe s'applique **à l'inscription et au changement de mot de passe**, jamais
  à la connexion : un membre dont l'ancien mot de passe fait moins de 10 caractères se connecte
  normalement, puis le change via Profil → Définir un mot de passe.
- **Ne jamais désactiver « Confirm email »** en staging ou en production : un compte non confirmé peut
  usurper l'adresse d'un tiers. Pour tester sans boîte mail, utiliser l'environnement local (les emails
  arrivent dans Inbucket : http://127.0.0.1:54324).
- **SMTP** : le SMTP intégré de Supabase plafonne à quelques emails par heure, insuffisant dès que la
  confirmation est obligatoire. Créer un compte Resend, vérifier le domaine `aeemg.org` (SPF, DKIM),
  générer une clé API et la saisir comme mot de passe SMTP. La clé ne va jamais dans le dépôt.
- **CAPTCHA** : `supabase_flutter` accepte un `captchaToken` sur `signUp`, `signInWithPassword` et
  `resetPasswordForEmail`, mais l'app n'a pas encore de widget Turnstile. Activer la protection côté
  Supabase avant ce widget bloquerait toutes les inscriptions : elle reste désactivée d'ici là.

### Supabase (une fois)

[Authentication → Providers → Email](https://supabase.com/dashboard/project/fuumkjatgczkbxdpjduo/auth/providers)

- **Enable Email** : ON
- **Confirm email** : **ON**
- **Allow new users to sign up** : ON

### Erreur « Invalid login credentials »

Causes fréquentes :

1. **Compte créé par code email** — pas de mot de passe. Connectez-vous via « Code email », puis **Profil → Définir un mot de passe**.
2. **Email pas encore confirmé** — ouvrez le lien reçu par email (pensez aux indésirables).
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
