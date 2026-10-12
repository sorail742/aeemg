# Tickets — Fiabilité & robustesse (`REL`)

---

### REL-001 — Dédoublonner les versions de migrations (déploiement impossible)
**Type** : Fiabilité · **Priorité** : P0 · **Estimation** : XS · **Composant** : supabase/db

**Contexte** — Deux fichiers portent la même version `20260614000000`
(`..._phase8_admin_fixes.sql` et `..._phase9_admin_fixes.sql`). La CLI Supabase utilise ce préfixe
comme clé primaire de `supabase_migrations.schema_migrations` : `supabase db push` / `db reset`
échoue ou n'applique qu'un des deux fichiers selon l'environnement.

**Travail attendu** — Renommer `phase9` en `20260614000100_phase9_admin_fixes.sql`. Pour les
environnements déjà migrés manuellement, documenter `supabase migration repair --status applied 20260614000100`.

**Critères d'acceptation**
- [ ] Aucune version dupliquée (contrôle automatique dans le job CI `supabase / migrations-lint`)
- [ ] `supabase db reset` passe de bout en bout en CI
- [ ] Procédure de réparation documentée dans `docs/SUPABASE_SETUP.md`

---

### REL-002 — Rendre la migration phase 9 exécutable et idempotente
**Type** : Fiabilité · **Priorité** : P0 · **Estimation** : S · **Composant** : supabase/db
**Dépendances** : REL-001, SEC-021

**Contexte** — `phase9_admin_fixes.sql` fait `ALTER TYPE user_role ADD VALUE 'staff'` puis, **dans la même
transaction**, crée des policies comparant `role IN ('admin','staff')` → PostgreSQL lève
`unsafe use of new value "staff" of enum type`. Les `CREATE POLICY` ne sont pas protégés
(`drop policy if exists`) → échec en ré-exécution. `user_role` et `profiles` non qualifiés par schéma.

**Critères d'acceptation**
- [ ] L'ajout de valeur d'enum (si conservé après SEC-021) est dans une migration séparée, antérieure
- [ ] Toutes les policies sont précédées de `drop policy if exists`
- [ ] `supabase db reset` exécuté deux fois de suite en CI sans erreur

---

### REL-003 — Rendre toutes les migrations rejouables sur une base vierge
**Type** : Fiabilité · **Priorité** : P0 · **Estimation** : S · **Composant** : supabase/db
**Dépendances** : REL-001, REL-002

**Contexte** — Rejeu constaté en CI et sur PostgreSQL local : `20260409000000_fix_policies` échoue
(policy « Groupes visibles aux utilisateurs connectés » déjà créée par `phase1_mvp`), puis `phase7`
(`uuid_generate_v4`) et `phase9` (REL-002).
- `fix_policies` : `create policy` d'un nom déjà créé par la phase 1 sans `drop policy if exists` préalable.
- `phase6` : `insert into storage.buckets` sans `on conflict do nothing`.
- `phase7` : `uuid_generate_v4()` (extension `uuid-ossp`, schéma `extensions` non garanti dans le `search_path`) alors que le reste utilise `gen_random_uuid()`.
- `phase7` : un seul bloc `DO ... EXCEPTION` pour deux `alter publication` → si la 1re table est déjà publiée, la 2e ne l'est jamais.
- `phase1`/`phase2`/`fix_policies` : données de démo insérées dans les migrations (cf. DEL-012).

**Décision préalable** — Corriger ces migrations impose de **modifier des migrations déjà appliquées**
(contraire à ADR-0010). Options : (a) les rendre idempotentes en place (`drop policy if exists`,
`gen_random_uuid()`), sans effet sur les bases déjà migrées qui ne les rejouent pas ; (b) remplacer
l'historique par une migration de base (squash) générée depuis la production (`supabase db dump`).

**Critères d'acceptation**
- [ ] Décision (a) ou (b) tracée dans un ADR qui amende ADR-0010
- [ ] `gen_random_uuid()` partout
- [ ] Un bloc `DO` par `alter publication`
- [ ] Job CI : `supabase db reset` sur base vierge + `supabase db lint --level warning` sans erreur

---

### REL-004 — Supprimer la dérive `APPLY_ALL.sql` / migrations
**Type** : Fiabilité · **Priorité** : P1 · **Estimation** : XS · **Composant** : supabase/db
**Dépendances** : DEL-001

**Contexte** — `supabase/APPLY_ALL.sql` (950 lignes) est une copie manuelle des migrations, déjà
divergente (ne contient pas forcément phase 5 à 9). Deux sources de vérité = environnements incohérents.

**Critères d'acceptation**
- [ ] Une seule source : `supabase/migrations/` appliquée via `supabase db push` (cf. [ADR-0010](../adr/0010-migrations-versionnees.md))
- [ ] `docs/SUPABASE_SETUP.md` ne mentionne plus le copier-coller SQL

---

### REL-005 — Fiabiliser les rappels d'événements (doublons, cron, performances)
**Type** : Fiabilité · **Priorité** : P1 · **Estimation** : M · **Composant** : edge-functions, supabase/db
**Dépendances** : SEC-010

**Contexte** — `event-reminders/index.ts` :
- deux exécutions le même jour → notifications en double (aucune déduplication) ;
- requêtes N+1 (RSVP puis préférences par participant) ;
- bornes `T00:00:00`/`T23:59:59` sans fuseau explicite (UTC implicite ; à garantir pour `Africa/Conakry`) et oubli de la dernière seconde ;
- aucun ordonnancement configuré (le cron est « à faire » dans la doc) ;
- une erreur sur un jour interrompt tout le traitement.

**Critères d'acceptation**
- [ ] Table `event_reminder_log(event_id, user_id, offset_days)` avec contrainte `unique` ; l'insertion de la notification et du log est atomique (RPC SQL)
- [ ] Planification `pg_cron` versionnée dans une migration (chaque jour 07:00 Africa/Conakry)
- [ ] Une requête SQL unique par décalage (jointure RSVP × préférences)
- [ ] Test : deux exécutions consécutives → aucune notification en double
- [ ] Résumé d'exécution journalisé (nb notifications, durée, erreurs)

---

### REL-006 — Statistiques admin exactes (dons)
**Type** : Fiabilité · **Priorité** : P2 · **Estimation** : S · **Composant** : supabase/db, flutter
**Dépendances** : AMEL-015

**Contexte** — `AdminRepository.fetchStats` additionne côté client **tous** les dons (y compris
`pending` et `failed`) et seulement les 1000 premiers (`limit(1000)`) ; 7 requêtes séquentielles.

**Critères d'acceptation**
- [ ] RPC `admin_dashboard_stats()` (réservée staff) renvoyant les agrégats calculés en SQL
- [ ] Seuls les dons `completed` sont comptés dans le total
- [ ] Test pgTAP avec un jeu de dons mixte

---

### REL-007 — Mettre à jour `raised_amount` des campagnes de dons
**Type** : Fiabilité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/db
**Dépendances** : SEC-008

**Contexte** — `donation_campaigns.raised_amount` n'est jamais recalculé : la barre de progression
(CDC §3.6) reste à 0 ou dépend d'une mise à jour manuelle.

**Critères d'acceptation**
- [ ] Trigger sur `donations` (passage à/depuis `completed`) qui met à jour la campagne ; ou vue calculée
- [ ] Test pgTAP : don complété → `raised_amount` augmente ; remboursé/échoué → diminue

---

### REL-008 — Centraliser la gestion des erreurs et ne plus afficher d'exceptions brutes
**Type** : Robustesse · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter

**Contexte** — De nombreux écrans affichent `Text('Erreur: $e')` (ex. `chat_screen.dart`) : messages
techniques en anglais, fuite d'informations internes (noms de tables, policies). `lib/core/utils/supabase_errors.dart`
existe mais n'est pas utilisé partout.

**Critères d'acceptation**
- [ ] Type `AppFailure` (réseau, non autorisé, validation, inconnu) + traduction en message FR
- [ ] Aucune occurrence de `'Erreur: $e'` / `'$e'` dans un widget (contrôle grep en CI)
- [ ] Les erreurs inattendues sont envoyées à l'outil de crash reporting (OPS-008)

---

### REL-009 — Uploads de médias robustes (noms uniques, compression, reprise)
**Type** : Robustesse · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter
**Dépendances** : SEC-006, AMEL-011

**Contexte** — Noms de fichiers = `millisecondsSinceEpoch` (collisions possibles), pas de redimensionnement
(seul `imageQuality: 70`), pas de limite de taille côté client, pas d'indicateur de progression ni de reprise
sur réseau instable (contexte 3G guinéen, CDC §4.3).

**Critères d'acceptation**
- [ ] Noms en UUID v4 ; images redimensionnées (≤ 1280 px) et compressées (< 500 Ko visé)
- [ ] Refus côté client au-delà des limites du bucket avec message clair
- [ ] Indicateur d'envoi + bouton « Réessayer » en cas d'échec ; message non créé si l'upload échoue

---

### REL-010 — Démarrage résilient (configuration absente, Supabase injoignable)
**Type** : Robustesse · **Priorité** : P2 · **Estimation** : S · **Composant** : flutter
**Dépendances** : SEC-019

**Contexte** — `main.dart` : `dotenv.load` lève une exception si `.env` est absent (écran blanc) ; si la
configuration est invalide, `SupabaseConfig.initialize` ne fait rien et tous les repositories reçoivent
un client `null` silencieusement.

**Critères d'acceptation**
- [ ] Erreurs de démarrage capturées (`runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`)
- [ ] Écran d'erreur explicite si la configuration est invalide (en dev) ; mode hors ligne si le réseau est absent
- [ ] Test widget couvrant le démarrage sans configuration

---

### REL-011 — Auditer et corriger les abonnements Realtime / ressources non libérées
**Type** : Robustesse · **Priorité** : P2 · **Estimation** : M · **Composant** : flutter

**Contexte** — `messages_repository.dart` et `notifications_repository.dart` ouvrent des `.stream()`
Realtime ; `chat_screen.dart` (1208 lignes) gère enregistreur audio, lecteur, contrôleurs.
Risque de fuites (canaux non fermés, `AudioRecorder`/`AudioPlayer` non `dispose`), de `setState` après `dispose`.

**Critères d'acceptation**
- [ ] Tous les providers de flux sont `autoDispose` ; chaque contrôleur/lecteur/enregistreur est libéré dans `dispose`
- [ ] Test : ouvrir/fermer 20 fois une conversation → nombre de canaux Realtime actifs constant
- [ ] Aucun `setState` sans vérification `mounted` après un `await`

---

### REL-012 — Corriger les clés étrangères qui bloquent la suppression d'un membre
**Type** : Fiabilité · **Priorité** : P1 · **Estimation** : S · **Composant** : supabase/db

**Contexte** — `events.created_by`, `announcements.author_id`, `chat_groups.created_by`,
`transactions.recorded_by`, `donations.campaign_id`… référencent `profiles` **sans** `on delete` :
supprimer un membre ayant créé un événement échoue (`phase9` n'a corrigé que `donations.user_id`).
`messages.reply_to_id` sans `on delete set null`.

**Critères d'acceptation**
- [ ] Chaque FK vers `profiles` a une règle explicite (`set null` pour l'auteur, `cascade` pour les données personnelles)
- [ ] Test pgTAP : suppression d'un membre ayant créé événement, annonce, groupe, transaction, message cité → succès
- [ ] Requête de contrôle (CI) listant les FK sans `on delete` explicite → 0

---

### REL-013 — Paginer les listes (messages, fil social, membres, notifications)
**Type** : Robustesse / Performance · **Priorité** : P1 · **Estimation** : M · **Composant** : flutter, supabase/db

**Contexte** — Les listes chargent l'intégralité des lignes (`select()` sans `range`) : temps de chargement et
consommation data qui croissent sans limite (contrainte 3G du CDC §7.1 : < 3 s). Supabase tronque en plus à
`max_rows = 1000` (`config.toml`) → données silencieusement manquantes.

**Critères d'acceptation**
- [ ] Pagination par curseur (`created_at`, `id`) de 30 éléments + chargement infini
- [ ] Index couvrants associés (cf. AMEL-016)
- [ ] Test avec 5 000 messages : premier affichage < 1 s sur émulateur, mémoire stable

---

### REL-014 — Valider les paramètres de route (crash sur URL invalide)
**Type** : Robustesse · **Priorité** : P2 · **Estimation** : XS · **Composant** : flutter

**Contexte** — `app_router.dart` fait `int.parse(state.pathParameters['number']!)` pour
`/quran/surah/:number`, `/quran/juz/:number`, `/quran/test/:surah` : `/quran/surah/abc` ou `/quran/surah/999`
(web, liens partagés) provoque une exception non gérée.

**Critères d'acceptation**
- [ ] `int.tryParse` + bornes (1–114, 1–30) ; page « introuvable » sinon
- [ ] `errorBuilder` global GoRouter
- [ ] Tests de router pour les valeurs invalides

---

### REL-015 — File d'envoi hors ligne pour les actions utilisateur
**Type** : Robustesse · **Priorité** : P3 · **Estimation** : L · **Composant** : flutter
**Dépendances** : AMEL-019

**Contexte** — Hors connexion, l'envoi d'un message, d'un RSVP ou d'un retour échoue définitivement. Le CDC
(§4.3, §8) identifie la connectivité irrégulière comme risque majeur.

**Critères d'acceptation**
- [ ] Les messages texte et RSVP sont mis en file locale et envoyés au retour du réseau (idempotence par UUID client)
- [ ] État visuel « en attente d'envoi » / « échec »
- [ ] Tests unitaires de la file (persistance, rejeu, déduplication)

---

### REL-016 — Rétablir la compilation de l'application (build cassé sur `main`)
**Type** : Fiabilité · **Priorité** : P0 · **Estimation** : S · **Composant** : flutter

**Contexte** — Le commit initial de `main` ne compile pas (CI « Flutter CI » déjà en échec) ; constaté par
les jobs `analyze`, `test`, `android` de la PR de mise en place de la CI :
- `lib/features/admin/presentation/admin_screen.dart` : la classe `_IslamTab` n'est pas fermée (accolade
  manquante après sa méthode `build`, ~l. 1602), donc `_showCreateUserDialog` / `_showEventDialog` sont lus
  comme des membres de la classe ; l'onglet Membres (~l. 782) passe `floatingActionButton`/`body` à un
  `RefreshIndicator` (paramètres de `Scaffold`) et contient une parenthèse `);` en trop (~l. 872).
- `lib/features/quran/presentation/quran_hub_screen.dart:441` appelle `q.getSurahAndVersesFromHizbQuarter`,
  qui n'existe pas dans le paquet `quran` (1.4.1, dernière version) : il faut une table des débuts de hizb
  (données validées par le référent) ou masquer l'onglet Hizb.
- `test/widget_test.dart` échoue au chargement pour la même raison.

**Critères d'acceptation**
- [ ] `flutter analyze` sans erreur ni warning (les `info` restent suivies par AMEL-006)
- [ ] `flutter test` vert ; `flutter build apk --debug` et `flutter build web` verts en CI
- [ ] L'onglet Membres de l'admin s'affiche (bouton « Créer membre » + liste rafraîchissable)
- [ ] Onglet Hizb : soit 60 hizb corrects (vérifiés sur 3 hizb de référence par le référent), soit masqué avec ticket de suivi

