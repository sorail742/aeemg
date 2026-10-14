# Guide Administrateur — AEEMG

## Rôles

Matrice appliquée par les helpers SQL (ADR-0008, SEC-021). `MemberProfile` (Dart) en est la
réplique exacte ; `supabase/tests/006_sec021_matrice_roles.test.sql` et
`test/profile_roles_test.dart` vérifient chaque cellule.

| Rôle | `is_staff()` / `isStaff` | `is_admin()` / `isAdmin` | `is_treasurer()` / `isTreasurer` |
|---|:-:|:-:|:-:|
| `super_admin` | ✅ | ✅ | ✅ |
| `admin` | ✅ | ✅ | ✅ |
| `moderator` | ✅ | | |
| `section_lead` | ✅ | | |
| `treasurer` | | | ✅ |
| `member`, `volunteer`, `visitor` | | | |

- **Staff** (`is_staff`) : annonces, événements, groupes, contenus, modération.
- **Admin** (`is_admin`) : suppression de membres, attribution des rôles via `set_member_role`
  (admin et super_admin attribuables par un super_admin uniquement).
- **Trésorier** (`is_treasurer`) : transactions, bilans, dons en espèces.
- Le rôle `staff` (phase 9) est **déprécié** : les profils concernés sont devenus `moderator` et
  la contrainte `profiles_role_not_staff` empêche de l'attribuer.

Toute nouvelle policy utilise ces helpers, jamais une liste de rôles en dur, et une seule
policy par (table, opération, intention).

Attribuer un rôle : écran Admin → Membres, ou `select public.set_member_role('<uuid>', 'moderator');`
(un `update` direct de `profiles.role` est refusé, SEC-001).

---|---|
| `admin` | Événements, annonces, membres |
| `moderator` | Modération messages |
| `treasurer` | Finances |
| `member` | Utilisation standard |

Attribuer un rôle : Supabase → Table Editor → `profiles` → colonne `role`

---

## Supprimer un membre (SEC-023)

Écran Admin → Membres → ⋮ → **Supprimer**. L'app appelle l'Edge Function `admin-delete-user`,
qui supprime le **compte** (`auth.users`) : le membre ne peut plus se connecter.

| Règle | Détail |
|---|---|
| Qui peut supprimer | `admin` et `super_admin` ; un admin ou super_admin ne peut être supprimé que par un super_admin |
| Interdit | supprimer son propre compte depuis l'administration |
| Vérification | `public.check_member_deletion()` en base, avec l'identité de l'appelant |

**Choix : suppression des données personnelles, conservation des contenus collectifs.**

| Données | Sort |
|---|---|
| Profil, préférences, appareils, notifications | supprimés |
| Messages, réactions, accusés de lecture, posts, commentaires, likes, abonnements | supprimés (droit à l'effacement) |
| Fichiers déposés (avatars, médias de messagerie, images de posts) | supprimés de Storage |
| Inscriptions aux événements, bénévolat, favoris | supprimées |
| Événements, annonces, groupes créés | **conservés**, auteur vide (« Membre supprimé ») |
| Transactions saisies, dons, retours beta, sessions de paiement | **conservés**, auteur vide (obligations comptables) |

La suppression directe d'une ligne `profiles` n'est plus possible : elle laissait le compte
actif, sans profil.

Déploiement : `supabase functions deploy admin-delete-user` (utilise `SUPABASE_URL`,
`SUPABASE_ANON_KEY` et `SUPABASE_SERVICE_ROLE_KEY`, fournis automatiquement par Supabase).

---

## Publier une annonce

```sql
insert into public.announcements (title, content, is_important)
values ('Titre', 'Contenu de l''annonce', true);
```

---

## Créer un événement

```sql
insert into public.events (title, description, event_type, location, starts_at)
values (
  'Conférence',
  'Description…',
  'conference',
  'Mosquée AEEMG',
  '2026-06-20 18:00:00+00'
);
```

---

## Consulter les retours beta

```sql
select * from public.feedback order by created_at desc;
```

---

## Préférences notifications

Les membres gèrent leurs alertes dans l'app : Notifications → icône réglages.

Table : `notification_preferences` (une ligne par membre).

---

## Notifications membres

```sql
insert into public.notifications (user_id, title, body, category)
values (
  'UUID-du-membre',
  'Nouvel événement',
  'Conférence ce vendredi à 18h',
  'events'
);
```
