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
