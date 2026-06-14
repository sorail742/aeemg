# Guide Administrateur — AEEMG

## Rôles

| Rôle | Capacités |
|---|---|
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
