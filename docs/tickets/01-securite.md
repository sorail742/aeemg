# Tickets — Sécurité (`SEC`)

> Toute correction de policy RLS doit être accompagnée d'un test pgTAP dans
> `supabase/tests/` qui **échoue avant** le correctif et **passe après**
> (cf. [ADR-0007](../adr/0007-rls-frontiere-de-securite.md)).

---

### SEC-001 — Empêcher un membre de modifier son propre rôle (escalade de privilèges)
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : M · **Composant** : supabase/db
**Statut** : ✅ Livré — migration `20261012160000_sec001_protect_profile_role.sql` (trigger + RPC `set_member_role`), tests pgTAP `001_sec001_member_roles.test.sql`
**Dépendances** : REL-002

**Contexte** — La policy `"Mise a jour de son propre profil"` (`20260407000000_initial_schema.sql`)
puis `"Staff modifie les rôles"` (`20260614000000_phase8_admin_fixes.sql`) autorisent un `UPDATE`
de **toutes les colonnes** de `profiles` dès que `auth.uid() = id`. N'importe quel membre peut donc
exécuter avec la clé anon : `update profiles set role = 'super_admin' where id = auth.uid()`.
De plus, tout « staff » (modérateur, responsable de section) peut promouvoir n'importe qui en `super_admin`.
Le client fait d'ailleurs l'update directement (`lib/features/admin/data/admin_repository.dart:90`).

**Travail attendu**
- Interdire la modification de `role`, `followers_count`, `following_count`, `created_at` par le propriétaire
  (trigger `BEFORE UPDATE` qui rejette les changements de colonnes protégées, ou `REVOKE UPDATE` colonne par colonne + `GRANT UPDATE (full_name, section, specialty, avatar_url, is_profile_public, preferred_locale, phone)`).
- Créer une RPC `public.set_member_role(target uuid, new_role user_role)` `SECURITY DEFINER` :
  seul `super_admin` peut attribuer `super_admin`/`admin` ; `admin` peut attribuer les autres rôles ;
  personne ne peut se rétrograder s'il est le dernier `super_admin`.
- Remplacer l'appel direct dans `AdminRepository.updateRole` par la RPC.
- Journaliser chaque changement de rôle (cf. SEC-026).

**Critères d'acceptation**
- [ ] Test pgTAP : un `member` qui tente `update profiles set role='super_admin'` sur lui-même → erreur ou 0 ligne modifiée, rôle inchangé
- [ ] Test pgTAP : un `moderator` ne peut changer le rôle de personne
- [ ] Test pgTAP : un `admin` ne peut pas attribuer `super_admin` ; un `super_admin` le peut
- [ ] Test pgTAP : un membre peut toujours modifier `full_name`, `section`, `avatar_url`
- [ ] L'écran admin change les rôles via la RPC et affiche une erreur claire en cas de refus
- [ ] Revue de sécurité par 2 personnes (dont le référent backend)

---

### SEC-002 — Protéger les compteurs dénormalisés (likes, commentaires, abonnés)
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/db
**Dépendances** : SEC-001

**Contexte** — `posts.likes_count`, `posts.comments_count` (`phase5_social.sql`) sont modifiables par
l'auteur via la policy `"Modifier son post"` ; `profiles.followers_count/following_count` par le
propriétaire. Les compteurs peuvent être falsifiés.

**Travail attendu** — Restreindre l'`UPDATE` de `posts` à `content`, `image_url` ; les compteurs ne
sont modifiables que par les triggers `SECURITY DEFINER`.

**Critères d'acceptation**
- [ ] Test pgTAP : l'auteur ne peut pas modifier `likes_count`/`comments_count`
- [ ] Test pgTAP : un utilisateur ne peut pas modifier ses `followers_count`
- [ ] Liker/commenter met toujours les compteurs à jour (test pgTAP)

---

### SEC-003 — Empêcher l'auto-ajout dans un groupe/conversation privée
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : M · **Composant** : supabase/db, flutter
**Statut** : ✅ Livré — migration `20261012170000_sec003_groupes_prives.sql`, tests pgTAP `002_sec003_groupes_prives.test.sql`
**Dépendances** : —

**Contexte** — Policy `"Rejoindre un groupe"` (`phase1_mvp.sql`) : `with check (auth.uid() = user_id)`.
Tout utilisateur connecté peut s'insérer dans **n'importe quel** `chat_group`, y compris une
conversation 1-à-1 (`is_group = false`, `phase6`) et lire tout l'historique. `chat_groups` est lisible
par tous les connectés, donc les ID sont découvrables. `addMemberToGroup`
(`messages_repository.dart:147`) permet aussi d'ajouter un tiers mais la policy l'interdit (incohérence).

**Travail attendu**
- Ajouter `chat_groups.visibility` (`public` | `private` | `direct`) et une table/colonne de rôle de membre (`owner`, `admin`, `member`).
- Auto-adhésion uniquement aux groupes `public` ; ajout d'un tiers uniquement par `owner/admin` du groupe ou staff ; conversations `direct` créées via une RPC qui insère les 2 participants.
- Restreindre la lecture de `chat_groups` : groupes publics + groupes dont on est membre.

**Critères d'acceptation**
- [ ] Test pgTAP : un membre C ne peut ni rejoindre ni lire une conversation directe entre A et B
- [ ] Test pgTAP : un membre peut rejoindre un groupe public et y lire les messages
- [ ] Test pgTAP : seul un admin du groupe (ou staff) peut ajouter un tiers à un groupe privé
- [ ] Les conversations 1-à-1 existantes sont migrées en `direct` sans perte
- [ ] Le bouton « ajouter un membre » de l'app fonctionne pour un admin de groupe et est masqué sinon

---

### SEC-004 — Fermer la table `group_invitations` (fuite de numéros de téléphone)
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : S · **Composant** : supabase/db
**Dépendances** : SEC-003
**Statut** : ✅ Livré — migration `20261013120000_sec004_group_invitations.sql`, tests pgTAP `003_sec004_group_invitations.test.sql` ; anciennes invitations conservées (contraintes `invited_by` et E.164 en `NOT VALID`)

**Contexte** — `phase7_messaging_fixes.sql` : policies `SELECT using (true)` et `INSERT with check (true)`.
Un visiteur **non connecté** peut lister tous les numéros invités et en insérer à volonté. La table est
en plus publiée en Realtime. Pas de colonne `invited_by`, `status` sans contrainte.

**Travail attendu** — Ajouter `invited_by uuid not null default auth.uid()`, contrainte `check (status in ('pending','accepted','expired','revoked'))`,
lecture réservée à l'invitant, aux admins du groupe et au staff ; insertion réservée aux admins du groupe ;
retirer la table de la publication Realtime.

**Critères d'acceptation**
- [ ] Test pgTAP : `anon` et un membre quelconque ne voient aucune invitation
- [ ] Test pgTAP : un non-admin du groupe ne peut pas créer d'invitation
- [ ] Les numéros sont validés au format E.164 (contrainte `check`)
- [ ] La table n'apparaît plus dans `supabase_realtime`

---

### SEC-005 — Restreindre la lecture des réactions aux membres du groupe
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : XS · **Composant** : supabase/db

**Contexte** — `message_reactions` : `SELECT using (true)` → lisible par `anon`, révèle l'activité des conversations privées.

**Critères d'acceptation**
- [ ] Policy de lecture identique à celle de `messages` (membre du groupe du message)
- [ ] Test pgTAP : `anon` et un non-membre ne voient aucune réaction

---

### SEC-006 — Rendre privés les médias de la messagerie (images, audio)
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : M · **Composant** : supabase/storage, flutter
**Dépendances** : SEC-003, AMEL-011
**Statut** : ✅ Livré — migration `20261013110000_sec006_medias_prives.sql` (buckets privés + limites, policies par groupe, `messages.media_path`), tests pgTAP `004_sec006_medias_prives.test.sql` ; URL signées côté app

**Contexte** — Buckets `chat_images` et `chat_audio` créés `public = true` (`phase6`), lecture
`using (bucket_id = ...)` pour tous. Les URLs publiques sont stockées dans `messages.media_url`
(`chat_screen.dart:376,418`). Toute personne ayant l'URL (ou listant le bucket) accède aux médias privés.
Aucune limite de taille ni de type MIME, aucune policy de suppression.

**Travail attendu**
- Passer les buckets en privés, chemin `<group_id>/<uuid>.<ext>`, policy `select/insert` vérifiant
  l'appartenance au groupe via `(storage.foldername(name))[1]::uuid`.
- Stocker le **chemin** (pas l'URL) en base ; générer des URL signées (durée courte) côté client.
- `file_size_limit` (images 5 Mo, audio 10 Mo) et `allowed_mime_types` par bucket.
- Migration des messages existants (`media_url` → `media_path`).

**Critères d'acceptation**
- [ ] Une URL publique `/storage/v1/object/public/chat_images/...` renvoie 400/404
- [ ] Test : un non-membre du groupe ne peut ni lire ni écrire dans `chat_images/<group_id>/`
- [ ] Un upload > limite ou d'un type non autorisé est refusé avec un message utilisateur clair
- [ ] Les anciens messages média restent affichables après migration

---

### SEC-007 — Encadrer les uploads du bucket `social_images`
**Type** : Sécurité · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase/storage

**Contexte** — `phase5_social.sql` : tout connecté peut téléverser **n'importe quel fichier, à n'importe quel chemin** dans un bucket public (hébergement de contenu arbitraire).

**Critères d'acceptation**
- [ ] Upload uniquement sous `<auth.uid()>/...` (policy sur `storage.foldername`)
- [ ] `allowed_mime_types` = `image/jpeg, image/png, image/webp` ; `file_size_limit` = 5 Mo
- [ ] Suppression d'un post → suppression de l'image associée (trigger ou Edge Function)

---

### SEC-008 — Empêcher la falsification du statut des dons et des sessions de paiement
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : M · **Composant** : supabase/db, edge-functions
**Dépendances** : FEAT-004
**Statut** : ✅ Livré — migration `20261013130000_sec008_statut_dons.sql` (dons créés `pending`, validation espèces par le trésorier, mobile money par le service role, historique `donation_status_history`, plus d'insertion client dans `payment_sessions`), tests pgTAP `005_sec008_statut_dons.test.sql`

**Contexte** — Policy `"Créer un don"` : `with check (auth.uid() = user_id)` sans contrainte sur `status`.
Un membre peut insérer `status = 'completed'` et gonfler les statistiques / campagnes.
Idem `payment_sessions` : insertion directe par le client avec n'importe quel `status`, `amount`.

**Travail attendu**
- `donations` : insertion client forcée à `status = 'pending'` (check dans la policy ou trigger) ; transitions de statut uniquement via service role (webhook paiement) ou trésorier pour les dons en espèces.
- `payment_sessions` : supprimer la policy d'insertion client (création uniquement par l'Edge Function).
- Table d'historique des transitions de statut.

**Critères d'acceptation**
- [ ] Test pgTAP : un membre ne peut pas insérer un don `completed` ni modifier le statut d'un don existant
- [ ] Test pgTAP : un membre ne peut pas insérer dans `payment_sessions`
- [ ] Le flux de don de l'app fonctionne toujours (don créé `pending`)

---

### SEC-009 — Réserver la validation des paiements au trésorier / service role
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : XS · **Composant** : supabase/db
**Dépendances** : SEC-008

**Contexte** — Policy `"Staff gere paiements"` (`phase4`) : tout `is_staff()` (modérateur, responsable de section) peut passer une session de paiement à `completed`.

**Critères d'acceptation**
- [ ] Seuls `is_treasurer()` (hors modérateur/section_lead) et le service role peuvent modifier `payment_sessions`
- [ ] Test pgTAP pour modérateur (refus) et trésorier (succès)

---

### SEC-010 — Authentifier l'Edge Function `event-reminders`
**Type** : Sécurité · **Priorité** : P0 · **Estimation** : S · **Composant** : edge-functions
**Dépendances** : —
**Statut** : ✅ Livré — secret `CRON_SECRET` exigé dans l'en-tête `x-cron-secret` (comparaison en temps constant, refus si non configuré), tests Deno `event-reminders/auth.test.ts` ; planification `pg_cron` laissée à REL-005

**Contexte** — `supabase/functions/event-reminders/index.ts` n'effectue **aucun contrôle d'appelant**
et utilise la clé service role. Avec la clé anon publique (présente dans l'app), n'importe qui peut
l'appeler en boucle et inonder les membres de notifications.

**Travail attendu** — Exiger un secret dédié (`CRON_SECRET`, comparaison en temps constant) ou un JWT
service role ; déclencher via `pg_cron` + `pg_net` avec ce secret (cf. REL-005).

**Critères d'acceptation**
- [ ] Appel sans secret → 401 ; avec la clé anon → 401 ; avec le secret → 200
- [ ] Test Deno couvrant ces 3 cas
- [ ] Documentation `docs/` mise à jour (suppression de l'exemple `curl` avec service role en clair)

---

### SEC-011 — Durcir l'Edge Function `orange-money-init`
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : M · **Composant** : edge-functions
**Dépendances** : SEC-008, AMEL-012

**Contexte** — `orange-money-init/index.ts` : `donation_id` non vérifié (appartenance à l'appelant,
statut, cohérence du montant) ; `req.json()` non protégé (500 sur JSON invalide) ; `external_ref`
basé sur `Date.now()` (collisions) ; pas de limite de montant ni de format de téléphone ; pas de
limitation de débit ; message d'erreur SQL brut renvoyé au client.

**Critères d'acceptation**
- [ ] Le don doit appartenir à l'appelant, être `pending`, et `amount` == `donations.amount` sinon 400/403
- [ ] Téléphone validé (format guinéen `+224 6XX XX XX XX`), montant borné (min/max configurables)
- [ ] JSON invalide → 400 avec message générique ; aucune erreur SQL brute renvoyée
- [ ] `external_ref` = UUID ; contrainte `unique` en base
- [ ] Max N sessions par utilisateur et par heure (429 au-delà)
- [ ] Tests Deno pour chaque cas ci-dessus

---

### SEC-012 — Corriger `send-sms` (comparaison de secret, faux statut « envoyé »)
**Type** : Sécurité · **Priorité** : P2 · **Estimation** : S · **Composant** : edge-functions
**Dépendances** : FEAT-008

**Contexte** — `send-sms/index.ts` compare le header avec `!==` (non constant) et marque le SMS `sent`
dès que `SMS_API_KEY` existe **sans rien envoyer** (TODO). Les membres et le staff sont induits en erreur.

**Critères d'acceptation**
- [ ] Comparaison en temps constant (`timingSafeEqual`)
- [ ] Le statut `sent` n'est écrit qu'après réponse 2xx du fournisseur ; `failed` + raison sinon
- [ ] Numéro et longueur du message validés (≤ 480 caractères)

---

### SEC-013 — Fixer `search_path` des fonctions `SECURITY DEFINER`
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : XS · **Composant** : supabase/db

**Contexte** — `increment_post_likes`, `decrement_post_likes`, `increment_post_comments`,
`decrement_post_comments`, `increment_follows`, `decrement_follows` (`phase5_social.sql`) sont
`SECURITY DEFINER` **sans** `set search_path` → détournement possible par objet homonyme
(signalé par le linter Supabase `function_search_path_mutable`).

**Critères d'acceptation**
- [ ] Toutes les fonctions `SECURITY DEFINER` ont `set search_path = ''` et des noms qualifiés
- [ ] `supabase db lint` ne remonte plus `function_search_path_mutable`
- [ ] Un test pgTAP liste les fonctions `prosecdef` sans `proconfig` et attend 0 ligne

---

### SEC-014 — Protéger les données personnelles des profils
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : M · **Composant** : supabase/db, flutter

**Contexte** — `handle_new_user` (`email_auth.sql`) copie l'**email dans la colonne `phone`** ;
`is_profile_public` vaut `true` par défaut ; la policy de lecture expose **toutes** les colonnes
(téléphone, email) à tout utilisateur (même `anon` pour les profils publics). Non conforme aux principes
de protection des données (loi guinéenne L/2016/037, principes RGPD retenus par le cahier des charges §4.2).

**Travail attendu**
- Colonne `email` distincte (ou ne pas la dupliquer, elle est dans `auth.users`), migration des données.
- Vue `public.member_directory` (colonnes non sensibles) ; accès au téléphone uniquement pour soi et le staff.
- Paramètres de visibilité par champ (cf. FEAT-022), `is_profile_public` par défaut à `false` pour les nouveaux comptes, consentement explicite à l'inscription.

**Critères d'acceptation**
- [ ] Test pgTAP : `anon` ne lit aucun profil ; un membre ne lit pas le téléphone d'un autre membre
- [ ] Aucune adresse email dans `profiles.phone` après migration
- [ ] L'annuaire de l'app fonctionne via la vue

---

### SEC-015 — Masquer les participants aux événements pour les visiteurs anonymes
**Type** : Sécurité · **Priorité** : P2 · **Estimation** : XS · **Composant** : supabase/db

**Contexte** — `event_rsvps` : `SELECT using (true)` → `anon` voit qui participe à quoi.

**Critères d'acceptation**
- [ ] Lecture réservée aux connectés ; le compteur public passe par une vue/RPC agrégée
- [ ] Test pgTAP `anon` → 0 ligne

---

### SEC-016 — Limiter le spam des retours (feedback anonyme)
**Type** : Sécurité · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase/db

**Contexte** — Policy `"Envoyer un retour"` accepte `user_id is null` → insertion anonyme illimitée.

**Critères d'acceptation**
- [ ] Insertion réservée aux connectés avec `user_id = auth.uid()`
- [ ] `message` limité (1–2000 caractères) par contrainte `check`
- [ ] Max 10 retours / utilisateur / jour (trigger), test pgTAP

---

### SEC-017 — Restreindre la modification des messages
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/db
**Dépendances** : SEC-003

**Contexte** — Policy `"Modifier ses propres messages"` (`phase7`) : l'expéditeur peut modifier
**toutes** les colonnes, y compris `group_id` (déplacer un message dans un groupe dont il n'est pas
membre), `is_pinned` (épinglage réservé aux modérateurs selon le CDC §3.1), `created_at`.

**Critères d'acceptation**
- [ ] L'expéditeur ne peut modifier que `content` (fenêtre de 15 min) et `is_deleted`
- [ ] `is_pinned` modifiable uniquement par modérateur/admin du groupe
- [ ] Test pgTAP pour chaque colonne protégée

---

### SEC-018 — Filtrer par RLS les contenus non publiés / non approuvés
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/db

**Contexte** — `phase8` ajoute `events.is_approved` et `announcements.is_published` mais les policies
de lecture restent `using (true)` : un événement en attente d'approbation est visible de tous via l'API.

**Critères d'acceptation**
- [ ] Non-staff : ne voit que `is_approved = true` / `is_published = true`
- [ ] Staff : voit tout
- [ ] Tests pgTAP correspondants

---

### SEC-019 — Ne plus embarquer `.env` dans les assets de l'application
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : S · **Composant** : flutter, ci
**Dépendances** : —

**Contexte** — `pubspec.yaml` déclare `.env` comme asset : le fichier est copié tel quel dans l'APK et
dans `build/web/assets/.env` (téléchargeable). Si quelqu'un y ajoute une clé sensible (service role,
clé API SMS), elle est publiée. Le build échoue aussi si `.env` est absent.

**Travail attendu** — Passer à `--dart-define-from-file=config/<env>.json` (cf. [ADR-0009](../adr/0009-configuration-par-dart-define.md)),
supprimer `flutter_dotenv`, ajouter un contrôle CI qui refuse tout motif `service_role`/`sk_` dans le client.

**Critères d'acceptation**
- [ ] `build/web/assets/.env` n'existe plus ; `flutter_dotenv` retiré
- [ ] L'app démarre en dev, staging et prod avec la bonne configuration
- [ ] Le job CI `policy-checks` échoue si `.env` réapparaît dans `pubspec.yaml`

---

### SEC-020 — Signature release Android et identifiant d'application définitifs
**Type** : Sécurité · **Priorité** : P0 (avant publication) · **Estimation** : S · **Composant** : android
**Statut** : ✅ Livré — identifiant `org.aeemg` et nom « AEEMG » ([ADR-0023](../adr/0023-identifiant-et-signature-application.md)), signature depuis `key.properties` sans repli debug, procédure [keystore-android](../runbooks/keystore-android.md)

**Contexte** — `android/app/build.gradle.kts` : `applicationId = "com.example.aeemg"` et build release
signé avec la **clé de debug**. Google Play refuse `com.example.*` ; un APK signé debug peut être remplacé
par n'importe qui. iOS : bundle identifier à vérifier.

**Critères d'acceptation**
- [ ] `applicationId`/`namespace` = identifiant définitif validé par le bureau (`org.aeemg`, ADR-0023) — décision tracée dans un ADR
- [ ] Keystore release hors dépôt, chargé depuis `key.properties` / secrets CI ; `key.properties` dans `.gitignore`
- [ ] Le workflow `release.yml` produit un AAB signé ; sans secrets, le build release échoue explicitement (pas de repli sur debug)
- [ ] Procédure de sauvegarde du keystore documentée (2 détenteurs au bureau)

---

### SEC-021 — Unifier le modèle de rôles (`staff` fantôme, helpers incohérents)
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : M · **Composant** : supabase/db, flutter
**Dépendances** : REL-002

**Contexte** — `phase9` ajoute un rôle `staff` à l'enum et des policies `role IN ('admin','staff')` qui
**ignorent** `super_admin`, `moderator`, `section_lead`, alors que `is_staff()` SQL et `Profile.isStaff`
(`lib/shared/models/profile.dart:45`) n'incluent pas `staff`. L'écran admin colore pourtant `staff`.
Policies en double sur `events` (« Staff crée des événements » et « Staff can create events »).

**Travail attendu** — Matrice rôles × permissions unique (cf. [ADR-0008](../adr/0008-modele-de-roles.md)),
helpers SQL `has_permission(text)` ou `is_staff/is_admin/is_treasurer` cohérents, suppression des policies
doublons, alignement du modèle Dart, décision sur `staff` (déprécié).

**Critères d'acceptation**
- [ ] Une seule policy par (table, opération, intention)
- [ ] Matrice des permissions documentée dans `docs/ADMIN_GUIDE.md` et testée par pgTAP (1 test par cellule critique)
- [ ] `Profile.isStaff` et `public.is_staff()` renvoient le même résultat pour chaque rôle (test unitaire + pgTAP)

---

### SEC-022 — Renforcer la politique d'authentification
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/auth, flutter

**Contexte** — Mot de passe minimum 6 caractères ; `docs/SUPABASE_AUTH.md` recommande de **désactiver la
confirmation d'email** ; pas de protection anti-bot ; `jwt_expiry` par défaut ; SMTP par défaut limité à 3–4 mails/h.

**Critères d'acceptation**
- [ ] Mot de passe ≥ 10 caractères, protection « leaked passwords » activée (config + validation client)
- [ ] Confirmation d'email activée en staging/prod ; documentation corrigée
- [ ] CAPTCHA (hCaptcha/Turnstile) sur inscription et reset en prod
- [ ] SMTP de production configuré (Resend/SendGrid) et documenté
- [ ] Configuration versionnée dans `supabase/config.toml` (sections `[auth.email]`, `[auth.captcha]`)

---

### SEC-023 — Supprimer réellement un compte côté serveur (admin)
**Type** : Sécurité · **Priorité** : P1 · **Estimation** : M · **Composant** : edge-functions, supabase/db
**Dépendances** : REL-012

**Contexte** — `AdminRepository.deleteMember` supprime la ligne `profiles` mais pas `auth.users` :
l'utilisateur peut encore se connecter avec une session sans profil (écrans cassés), et ses données
d'authentification restent. Plusieurs FK sans `on delete` bloquent la suppression (cf. REL-012).

**Critères d'acceptation**
- [ ] Edge Function `admin-delete-user` (service role, réservée admin) qui supprime `auth.users` (cascade profil)
- [ ] Choix documenté : anonymisation des contributions (messages « Membre supprimé ») vs suppression
- [ ] Test : après suppression, la connexion échoue et aucune ligne orpheline ne subsiste

---

### SEC-024 — Garde de routes côté client pour les écrans à rôle
**Type** : Sécurité (défense en profondeur) · **Priorité** : P3 · **Estimation** : S · **Composant** : flutter
**Dépendances** : AMEL-018

**Contexte** — `lib/core/router/app_router.dart` n'a aucun `redirect` : `/admin`, `/finance`, `/profile/edit`
sont accessibles par URL (web). Seul l'écran admin teste `isStaff` après chargement.

**Critères d'acceptation**
- [ ] `redirect` global : routes authentifiées → `/login` si déconnecté ; routes staff → `/home` si non autorisé
- [ ] Tests widget/router pour chaque cas

---

### SEC-025 — Réduire les permissions Android/iOS au strict nécessaire
**Type** : Sécurité / Conformité store · **Priorité** : P2 · **Estimation** : S · **Composant** : android, ios

**Contexte** — `AndroidManifest.xml` déclare `USE_EXACT_ALARM` **et** `SCHEDULE_EXACT_ALARM`
(`USE_EXACT_ALARM` est réservé par Google Play aux apps réveil/calendrier), `CAMERA` (l'image picker
n'utilise que la galerie), `ACCESS_FINE_LOCATION` (une localisation approximative suffit pour les heures de prière).
`NSLocationAlwaysUsageDescription` sur iOS alors que seul « When In Use » est nécessaire.

**Critères d'acceptation**
- [ ] Chaque permission restante est justifiée dans `docs/PERMISSIONS.md` (fonctionnalité, écran, texte de demande)
- [ ] Permissions demandées au moment de l'usage (pas au lancement), refus géré proprement
- [ ] Le formulaire « Sécurité des données » Google Play est rempli à partir de ce document

---

### SEC-026 — Journal d'audit des actions sensibles
**Type** : Sécurité · **Priorité** : P2 · **Estimation** : M · **Composant** : supabase/db

**Contexte** — Aucune traçabilité des changements de rôle, suppressions de membres, modifications
financières, validation de dons. Le CDC (§3.3, §4.2) exige transparence et traçabilité.

**Critères d'acceptation**
- [ ] Table `audit_log(actor_id, action, entity, entity_id, before jsonb, after jsonb, at)` alimentée par triggers sur `profiles.role`, `transactions`, `donations.status`, `monthly_reports`, suppressions de membres
- [ ] Lecture réservée `super_admin`/`admin`, aucune policy `update`/`delete`
- [ ] Écran admin « Journal » paginé
