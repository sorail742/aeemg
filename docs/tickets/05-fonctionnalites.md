# Tickets — Fonctionnalités non implémentées (`FEAT`)

Écarts entre le [cahier des charges v1.1](../CAHIER_DES_CHARGES.md) et le code, plus les exigences
des stores (Google Play / App Store) non couvertes. La colonne « Réf. CDC » renvoie à la section du cahier.

> Règle : tout ticket `FEAT` de taille L doit être découpé en sous-tickets (données → API/RLS → UI)
> avant d'entrer en sprint, et chaque sous-ticket livrable indépendamment derrière un feature flag si
> nécessaire.

## Conformité stores & transverse

### FEAT-001 — Notifications push (FCM / APNs)
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : L · **Composant** : flutter, edge-functions · **Réf. CDC** : §3.4, §4.1
**Dépendances** : AMEL-013, [ADR-0012](../adr/0012-notifications-push.md)

**Contexte** — La table `push_device_tokens` existe (phase 3) mais l'app n'enregistre aucun token et aucun
service n'envoie de push. Seules les notifications in-app (Realtime, app ouverte) fonctionnent : l'objectif
principal du projet (réduire les infos reçues en retard de 62,5 % à < 10 %) n'est pas atteint.

**Critères d'acceptation**
- [ ] Enregistrement/rafraîchissement/suppression (déconnexion) du token sur Android, iOS et Web
- [ ] Edge Function `push-dispatch` déclenchée à l'insertion d'une `notification` (webhook DB), respect des préférences et du mode silencieux (FEAT-029)
- [ ] Tokens invalides purgés automatiquement
- [ ] Tap sur la notification → ouverture de l'écran concerné (deep link)
- [ ] Test de bout en bout sur appareil Android réel et iPhone réel (preuve dans la PR)

### FEAT-037 — Signalement et blocage de contenus/utilisateurs
**Type** : Fonctionnalité / Conformité · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter, supabase/db · **Réf. CDC** : §3.1 (modération)

**Contexte** — Fil social, commentaires et messagerie = contenus générés par les utilisateurs. Apple
(guideline 1.2) et Google Play exigent signalement, blocage et modération. Rien n'existe.

**Critères d'acceptation**
- [ ] Bouton « Signaler » sur post, commentaire, message (motif obligatoire) → table `reports`
- [ ] Bloquer un utilisateur : ses contenus sont masqués pour le bloqueur (RLS)
- [ ] File de modération dans l'admin (traiter, masquer, supprimer, avertir) ; délai de traitement affiché
- [ ] Tests pgTAP : un utilisateur bloqué n'apparaît plus dans les lectures du bloqueur

### FEAT-038 — Suppression de compte par l'utilisateur
**Type** : Fonctionnalité / Conformité · **Priorité** : P0 (avant publication) · **Estimation** : M · **Composant** : flutter, edge-functions
**Dépendances** : SEC-023

**Contexte** — Obligatoire sur l'App Store (5.1.1(v)) et Google Play (lien web de suppression requis).

**Critères d'acceptation**
- [ ] Profil → « Supprimer mon compte » avec double confirmation et ré-authentification
- [ ] Page web publique expliquant la procédure (URL déclarée sur Google Play)
- [ ] Données supprimées/anonymisées sous 30 jours conformément à la politique de confidentialité (FEAT-043)

### FEAT-043 — Politique de confidentialité, CGU et consentement
**Type** : Fonctionnalité / Conformité · **Priorité** : P1 · **Estimation** : S · **Composant** : flutter, docs · **Réf. CDC** : §4.2

**Critères d'acceptation**
- [ ] Pages « Confidentialité » et « Conditions d'utilisation » accessibles sans compte et depuis Paramètres
- [ ] Case de consentement à l'inscription, version acceptée enregistrée (`profiles.terms_version`, `accepted_at`)
- [ ] Texte validé par le bureau AEEMG

### FEAT-040 — Liens profonds d'authentification (confirmation email, reset mot de passe)
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : S · **Composant** : android, ios, flutter
**Dépendances** : AMEL-018

**Contexte** — `config.toml` déclare `io.supabase.aeemg://login-callback/` mais ni l'`AndroidManifest.xml` ni
l'`Info.plist` ne le déclarent : le lien « Mot de passe oublié » reçu par email n'ouvre pas l'app.

**Critères d'acceptation**
- [ ] Le lien de réinitialisation ouvre l'écran « Nouveau mot de passe » sur Android, iOS et Web
- [ ] `site_url` et URLs de redirection correctes par environnement

### FEAT-041 — Observabilité applicative (crash reporting)
Voir OPS-008 (ticket DevOps).

## Communication (CDC §3.1)

### FEAT-009 — Invitations de groupe par numéro de téléphone (réelles)
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, edge-functions
**Dépendances** : SEC-003, SEC-004, FEAT-008

**Contexte** — `chat_screen.dart:590` (`TODO`) : l'invitation enregistre seulement une ligne ; aucun SMS,
aucun rattachement quand la personne s'inscrit.

**Critères d'acceptation**
- [ ] Si le numéro correspond à un membre → ajout direct (si autorisé) ; sinon SMS d'invitation avec lien
- [ ] À l'inscription avec ce numéro (vérifié), les invitations `pending` sont converties en adhésions
- [ ] Expiration après 7 jours ; limite d'invitations par jour

### FEAT-010 — Gestion des groupes thématiques et rôles de groupe
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : L · **Composant** : flutter, supabase/db
**Dépendances** : SEC-003

**Critères d'acceptation**
- [ ] Staff : créer/éditer/archiver un groupe (nom, description, visibilité, icône) depuis l'app
- [ ] Rôles de groupe : propriétaire, admin, membre ; quitter un groupe
- [ ] Modérateur : épingler/désépingler, supprimer le message d'autrui (suppression logique tracée)
- [ ] Section « Messages épinglés » dans la conversation

### FEAT-011 — Mentions @membre
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter, supabase/db

**Critères d'acceptation**
- [ ] Autocomplétion des membres du groupe après `@` ; mentions stockées (`message_mentions`)
- [ ] La personne mentionnée reçoit une notification (même si le groupe est en sourdine)

### FEAT-012 — Partage de documents PDF dans la messagerie
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, supabase/storage
**Dépendances** : SEC-006

**Critères d'acceptation**
- [ ] `message_type = 'document'` ; PDF ≤ 10 Mo ; aperçu nom/taille ; ouverture/téléchargement
- [ ] Bucket privé `chat_documents` avec les mêmes règles que SEC-006

### FEAT-013 — Accusés de lecture des annonces importantes (vue bureau)
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : S · **Composant** : flutter, supabase/db

**Contexte** — `announcement_reads` est alimenté mais aucun écran ne l'exploite.

**Critères d'acceptation**
- [ ] Admin : taux de lecture par annonce importante, liste des non-lecteurs (pour relance SMS)
- [ ] Bouton « Relancer par SMS les non-lecteurs » (dépend de FEAT-008)

### FEAT-044 — Archivage et recherche dans les conversations
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter, supabase/db

**Critères d'acceptation**
- [ ] Recherche plein texte (index `tsvector` français) dans les groupes dont on est membre
- [ ] Groupes archivés consultables en lecture seule

## Événements & calendrier (CDC §3.2, §3.9)

### FEAT-014 — Publication programmée des événements et annonces
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase/db, flutter

**Critères d'acceptation**
- [ ] Champ `publish_at` ; invisible (RLS) avant cette date pour les non-staff
- [ ] Notification envoyée à la date de publication, pas à la création

### FEAT-015 — Événements récurrents (halaqas, récitations)
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : L · **Composant** : supabase/db, flutter

**Contexte** — `events.is_recurring` existe mais aucune règle de récurrence n'est stockée ni appliquée.

**Critères d'acceptation**
- [ ] Règle RRULE (hebdomadaire, mensuelle, date de fin) ; occurrences visibles dans l'agenda
- [ ] RSVP et rappels par occurrence ; annuler une occurrence sans annuler la série
- [ ] Tests unitaires de l'expansion des occurrences (fuseau Africa/Conakry)

### FEAT-016 — Galerie photos post-événement
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter, supabase/storage

**Critères d'acceptation**
- [ ] Participants et staff ajoutent des photos (compressées) après la date de l'événement
- [ ] Modération : staff supprime ; signalement (FEAT-037)

### FEAT-017 — Création/édition d'événements dans l'app avec circuit d'approbation
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter, supabase/db
**Dépendances** : SEC-018

**Contexte** — `events.is_approved` existe ; l'admin crée des événements mais il n'y a pas de proposition
par un responsable de section avec validation, ni d'édition complète (type, fin, récurrence, image).

**Critères d'acceptation**
- [ ] Responsable de section : proposer un événement (non approuvé) ; admin : approuver/refuser avec motif
- [ ] Notification au proposant ; seuls les événements approuvés sont visibles des membres
- [ ] Validation : `ends_at > starts_at`, titre 3–120 caractères

### FEAT-030 — Dates islamiques automatiques dans l'agenda
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter

**Critères d'acceptation**
- [ ] Ramadan, Aïd al-Fitr, Aïd al-Adha, Achoura, Mawlid, Nouvel an hégirien affichés pour l'année en cours et suivante
- [ ] Ajustement manuel ±1 jour par l'admin (observation lunaire locale) stocké en base
- [ ] Tests unitaires de conversion Hijri ↔ grégorien sur des dates de référence

### FEAT-031 — Indicateur de conflit avec l'emploi du temps universitaire
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter

**Critères d'acceptation**
- [ ] Le membre saisit ses créneaux de cours récurrents (stockage local ou profil privé)
- [ ] Un événement en chevauchement affiche un badge « Conflit »

### FEAT-032 — Export iCal (.ics) et vue « Mes événements »
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : S · **Composant** : flutter · **Réf. CDC** : §3.9

**Contexte** — Seul l'ajout à Google Calendar est livré (`calendar_export.dart`).

**Critères d'acceptation**
- [ ] Bouton « Exporter (.ics) » sur un événement ; fichier valide RFC 5545 (test unitaire)
- [ ] Onglet « Mes événements » (RSVP `going`/`maybe`) dans l'agenda
- [ ] Optionnel : flux iCal personnel abonnable (URL signée)

### FEAT-020 — Suivi de l'assiduité (check-in QR code)
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : L · **Composant** : flutter, supabase/db · **Réf. CDC** : §3.5

**Critères d'acceptation**
- [ ] QR code par événement (jeton signé, valable pendant l'événement) affiché par le staff
- [ ] Le membre scanne → présence enregistrée (une seule fois) ; saisie manuelle par le staff possible
- [ ] Statistiques d'assiduité par membre et par événement (admin)

## Membres (CDC §3.5, §5)

### FEAT-018 — Formulaire d'adhésion et validation des inscriptions
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter, supabase/db

**Contexte** — Toute inscription devient `member` immédiatement ; le rôle `visitor` et la validation par un
modérateur (CDC §5) ne sont pas implémentés.

**Critères d'acceptation**
- [ ] Nouvel inscrit = `visitor` ; formulaire d'adhésion (section, établissement, spécialité, téléphone)
- [ ] File de validation pour modérateur/responsable de section ; acceptation → `member` + notification
- [ ] Un `visitor` n'accède qu'aux contenus publics (RLS + UI)

### FEAT-019 — Cotisation annuelle et renouvellement
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : L · **Composant** : flutter, supabase/db
**Dépendances** : FEAT-002, FEAT-004

**Critères d'acceptation**
- [ ] Montant de cotisation par année académique configurable ; statut « à jour / en retard » par membre
- [ ] Paiement via Orange Money/MTN ou saisie espèces par le trésorier (génère une transaction `income`)
- [ ] Rappels automatiques J-30, J-7 avant échéance

### FEAT-021 — Recherche et filtres de l'annuaire
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : S · **Composant** : flutter, supabase/db

**Contexte** — `members_screen.dart` propose une recherche texte seulement.

**Critères d'acceptation**
- [ ] Filtres : section, spécialité/compétence, disponibilité bénévole, rôle (staff)
- [ ] Recherche insensible aux accents (`unaccent`) côté SQL, paginée

### FEAT-022 — Confidentialité granulaire du profil
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : S · **Composant** : flutter, supabase/db
**Dépendances** : SEC-014

**Critères d'acceptation**
- [ ] Réglages par champ (téléphone, section, spécialité, photo) : tous / membres / staff / personne
- [ ] Appliqué par la vue SQL de l'annuaire (pas seulement masqué dans l'UI) ; tests pgTAP

### FEAT-035 — Espace responsable de section
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : L · **Composant** : flutter, supabase/db
**Dépendances** : SEC-021

**Critères d'acceptation**
- [ ] `section_lead` rattaché à une section : gère membres et événements **de sa section uniquement** (RLS)
- [ ] Tableau de bord de section (effectif, assiduité, cotisations)

### FEAT-036 — Missions de bénévolat
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, supabase/db · **Réf. CDC** : §3.7

**Contexte** — `volunteer_signups` stocke un texte libre `mission` ; pas de missions définies par le staff,
pas de places limitées, pas de confirmation.

**Critères d'acceptation**
- [ ] Table `volunteer_missions` (titre, date, lieu, places) gérée par le staff
- [ ] Inscription/désinscription avec gestion des places ; liste des bénévoles pour le staff ; rappel J-1

## Finances & dons (CDC §3.3, §3.6)

### FEAT-002 — Saisie des transactions et tableau de bord financier
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : L · **Composant** : flutter, supabase/db

**Contexte** — La table `transactions` existe mais **aucun écran** ne permet de saisir recettes et dépenses ;
les bilans mensuels sont saisis à la main (`admin_finance_dialog.dart`) sans lien avec les transactions.

**Critères d'acceptation**
- [ ] Trésorier : créer/modifier/supprimer une transaction (type, montant GNF, catégorie, date, justificatif photo)
- [ ] Tableau de bord : solde, entrées/sorties du mois, répartition par catégorie
- [ ] Bilan mensuel **calculé** depuis les transactions (RPC), publication par l'admin
- [ ] Toute modification tracée (SEC-026) ; tests pgTAP des droits (trésorier vs admin vs membre)

### FEAT-003 — Export PDF du bilan financier
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter (ou edge-functions)
**Dépendances** : FEAT-002

**Critères d'acceptation**
- [ ] PDF du bilan mensuel/annuel (en-tête AEEMG, totaux, détail par catégorie, date de génération)
- [ ] Partage/téléchargement sur mobile et Web ; test unitaire du contenu généré

### FEAT-004 — Paiement Orange Money réel avec webhook de confirmation
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : L · **Composant** : edge-functions, supabase/db
**Dépendances** : SEC-008, SEC-011, [ADR-0015](../adr/0015-paiements-mobile-money.md)

**Contexte** — `orange-money-init` crée une session mais n'appelle pas l'API (TODO) ; aucun webhook ne
passe le don à `completed`.

**Critères d'acceptation**
- [ ] Appel API Orange Money Web Payment (sandbox puis prod) ; redirection/USSD
- [ ] Edge Function `orange-money-webhook` : vérification de signature/notif_token, idempotence, mise à jour atomique session + don
- [ ] Job de réconciliation des sessions `pending` > 30 min (vérification du statut auprès de l'API)
- [ ] Tests Deno avec réponses API simulées (succès, échec, doublon, signature invalide)

### FEAT-005 — Paiement MTN Mobile Money
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : L · **Composant** : edge-functions
**Dépendances** : FEAT-004

**Critères d'acceptation**
- [ ] Même contrat que FEAT-004 (init, webhook, réconciliation) derrière une interface `PaymentProvider` commune
- [ ] Choix du moyen de paiement dans l'écran de don

### FEAT-006 — Reçu numérique de don
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : edge-functions
**Dépendances** : FEAT-004, FEAT-008

**Critères d'acceptation**
- [ ] À la confirmation du paiement : reçu numéroté (séquence annuelle) par email et/ou SMS
- [ ] Reçu consultable dans l'historique des dons de l'app

### FEAT-007 — Dons récurrents mensuels
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : L · **Composant** : edge-functions, flutter
**Dépendances** : FEAT-004

**Critères d'acceptation**
- [ ] Engagement mensuel (montant, jour) ; rappel de paiement (mobile money ne permet pas le prélèvement automatique)
- [ ] Gestion/annulation par le donateur

### FEAT-042 — Administration des campagnes de dons et besoins de la mosquée
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter

**Contexte** — Les campagnes et besoins ne sont créables qu'en SQL.

**Critères d'acceptation**
- [ ] CRUD campagnes (objectif, dates, catégorie, image, active) et besoins mosquée (quantités, statut) dans l'admin
- [ ] Enregistrement d'un don en espèces par le trésorier (statut `completed`, reçu)

## Notifications & SMS (CDC §3.4)

### FEAT-008 — Envoi SMS réel avec file d'attente et reprise
**Type** : Fonctionnalité · **Priorité** : P1 · **Estimation** : M · **Composant** : edge-functions
**Dépendances** : SEC-012

**Critères d'acceptation**
- [ ] Intégration fournisseur (Orange SMS API Guinée ou Africa's Talking — choix en ADR)
- [ ] Repli SMS automatique pour les notifications importantes si le push n'est pas délivré / membre sans app (préférence `sms_fallback_enabled`)
- [ ] File `sms_notifications` traitée par lot avec retry exponentiel (3 essais), statut et coût enregistrés
- [ ] Plafond mensuel de SMS configurable (maîtrise des coûts)

### FEAT-029 — Mode silencieux aux heures de prière
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, edge-functions

**Critères d'acceptation**
- [ ] Option dans les préférences ; aucune notification push/locale pendant [adhan ; adhan + N min] (N configurable, défaut 20)
- [ ] Les notifications retenues sont délivrées à la fin de la fenêtre
- [ ] Tests unitaires du calcul de fenêtre (Conakry, Labé)

### FEAT-045 — Tableau de bord des indicateurs de succès du projet
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : supabase/db, flutter · **Réf. CDC** : §6

**Critères d'acceptation**
- [ ] Admin : taux d'adoption (inscrits / membres actifs), participation aux événements, nombre de dons, note moyenne des retours
- [ ] Calculé par RPC, sans données personnelles

## Mosquée (CDC §3.7)

### FEAT-023 — Planning d'occupation (vendredi, Aïd, événements)
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, supabase/db

**Critères d'acceptation**
- [ ] Réservation de créneaux par le staff (salle, objet, responsable) ; détection de chevauchement
- [ ] Vue semaine consultable par les membres

### FEAT-024 — Registre de maintenance
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter, supabase/db

**Critères d'acceptation**
- [ ] Signalement d'incident (photo, catégorie : infiltration, climatisation, électricité…), statut, responsable, coût (lié à une transaction)
- [ ] Historique et filtres

### FEAT-025 — Gestion des iftars du Ramadan
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, supabase/db
**Dépendances** : FEAT-036

**Critères d'acceptation**
- [ ] Calendrier des 30 iftars : sponsor/donateur, nombre de repas prévus, bénévoles affectés
- [ ] Lien avec la campagne de dons Ramadan

### FEAT-026 — Galerie photos de la mosquée
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : S · **Composant** : flutter
**Dépendances** : FEAT-016

**Critères d'acceptation**
- [ ] Albums gérés par le staff, réutilise le composant de FEAT-016

## Contenu islamique (CDC §3.8)

### FEAT-027 — Rappels spirituels programmés et citation du vendredi
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, supabase/db

**Critères d'acceptation**
- [ ] Rappels dhikr/douaa (matin, soir) en notifications locales, configurables
- [ ] Citation du vendredi publiée automatiquement (contenu `quote` daté) et notifiée le vendredi matin
- [ ] Administration du contenu islamique avec statut « validé par le référent » obligatoire avant publication

### FEAT-028 — Traduction peule des versets et hadiths
**Type** : Fonctionnalité · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter, contenu
**Dépendances** : AMEL-005

**Contexte** — `islamic_contents.translation_peul` existe mais n'est ni alimentée ni affichée.

**Critères d'acceptation**
- [ ] Affichage FR + Peul quand la langue Peul est choisie ; repli FR sinon
- [ ] Contenus traduits validés par un relecteur peulophone (champ `reviewed_by`)

### FEAT-034 — Audio du Coran hors ligne
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : M · **Composant** : flutter

**Critères d'acceptation**
- [ ] Téléchargement d'une sourate/d'un juz par récitateur, gestion de l'espace (taille affichée, suppression)
- [ ] Lecture hors ligne prioritaire ; téléchargement uniquement en Wi-Fi par défaut

### FEAT-033 — Partage de versets et hadiths
**Type** : Fonctionnalité · **Priorité** : P3 · **Estimation** : S · **Composant** : flutter

**Contexte** — Seule la copie dans le presse-papier existe.

**Critères d'acceptation**
- [ ] Partage natif (texte + référence) et image stylée (carte verset) vers WhatsApp et autres apps
