-- Réconciliation de la production avec l'historique des migrations (ADR-0024).
--
-- La production a été construite à la main (APPLY_ALL.sql + Dashboard), pas par les migrations :
-- son schéma diverge de l'état « après phase 9 ». Écarts mesurés le 2026-10-13 (empreinte
-- tables/colonnes/contraintes/policies/fonctions/triggers/enums/Realtime) :
--   * phase 4 absente : types payment_provider/payment_status, tables payment_sessions et
--     sms_notifications, colonnes profiles.preferred_locale et notification_preferences
--     .sms_fallback_enabled ;
--   * phase 8/9 partielles : valeur d'enum `staff`, policies « Staff can … events »,
--     FK donations.user_id sans ON DELETE SET NULL ;
--   * 17 policies au nom sans accents (définitions identiques) et 2 doublons « v2 ».
--
-- Sans cette réconciliation, les migrations de sécurité (SEC-001…) laisseraient en place les
-- anciennes policies permissives (`drop policy if exists "Créer un don"` ne trouve pas
-- « Creer un don »). Tout est idempotent : sur une base construite par les migrations, cette
-- migration ne change rien.

-- 1. Phase 4 -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type where typname = 'payment_provider'
                  and typnamespace = 'public'::regnamespace) then
    create type public.payment_provider as enum ('orange_money', 'mtn_momo');
  end if;
  if not exists (select 1 from pg_type where typname = 'payment_status'
                  and typnamespace = 'public'::regnamespace) then
    create type public.payment_status as enum
      ('initiated', 'pending', 'completed', 'failed', 'cancelled');
  end if;
end
$$;

create table if not exists public.payment_sessions (
  id uuid primary key default gen_random_uuid(),
  donation_id uuid references public.donations (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  provider public.payment_provider not null default 'orange_money',
  amount numeric(12, 2) not null check (amount > 0),
  phone text not null,
  external_ref text,
  status public.payment_status not null default 'initiated',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sms_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  phone text not null,
  message text not null,
  status text not null default 'queued' check (status in ('queued', 'sent', 'failed')),
  created_at timestamptz not null default now()
);

alter table public.notification_preferences
  add column if not exists sms_fallback_enabled boolean not null default false;

alter table public.profiles
  add column if not exists preferred_locale text not null default 'fr'
    check (preferred_locale in ('fr', 'ff'));

alter table public.payment_sessions enable row level security;
alter table public.sms_notifications enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'payment_sessions' and policyname = 'Ses sessions paiement') then
    create policy "Ses sessions paiement" on public.payment_sessions for select
      using (user_id = auth.uid() or public.is_staff());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'payment_sessions' and policyname = 'Creer session paiement') then
    create policy "Creer session paiement" on public.payment_sessions for insert
      with check (auth.uid() = user_id);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'payment_sessions' and policyname = 'Staff gere paiements') then
    create policy "Staff gere paiements" on public.payment_sessions for update
      using (public.is_staff());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'sms_notifications' and policyname = 'Ses SMS') then
    create policy "Ses SMS" on public.sms_notifications for select
      using (user_id = auth.uid() or public.is_staff());
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'sms_notifications' and policyname = 'Staff envoie SMS') then
    create policy "Staff envoie SMS" on public.sms_notifications for insert
      with check (public.is_staff());
  end if;
end
$$;

-- 2. Phases 8 et 9 -----------------------------------------------------------------------

alter type public.user_role add value if not exists 'staff';

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'events' and policyname = 'Staff can create events') then
    create policy "Staff can create events" on public.events for insert
      with check (exists (select 1 from public.profiles
                           where profiles.id = auth.uid()
                             and profiles.role::text in ('admin', 'staff')));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'events' and policyname = 'Staff can update events') then
    create policy "Staff can update events" on public.events for update
      using (exists (select 1 from public.profiles
                      where profiles.id = auth.uid()
                        and profiles.role::text in ('admin', 'staff')));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = 'events' and policyname = 'Staff can delete events') then
    create policy "Staff can delete events" on public.events for delete
      using (exists (select 1 from public.profiles
                      where profiles.id = auth.uid()
                        and profiles.role::text in ('admin', 'staff')));
  end if;

  -- FK donations.user_id : ON DELETE SET NULL (phase 9).
  if exists (select 1 from pg_constraint where conname = 'donations_user_id_fkey'
              and conrelid = 'public.donations'::regclass and confdeltype <> 'n') then
    alter table public.donations drop constraint donations_user_id_fkey;
    alter table public.donations add constraint donations_user_id_fkey
      foreign key (user_id) references public.profiles (id) on delete set null;
  end if;
end
$$;

-- 3. Noms de policies -------------------------------------------------------------------

do $$
declare
  r record;
begin
  -- (table, nom en production, nom dans les migrations) : définitions identiques.
  for r in
    select * from (values
      ('announcement_reads', 'Lecture de ses accuses', 'Lecture de ses accusés'),
      ('chat_groups', 'Groupes visibles aux utilisateurs connectes', 'Groupes visibles aux utilisateurs connectés'),
      ('chat_groups', 'Staff cree des groupes', 'Staff crée des groupes'),
      ('donation_campaigns', 'Staff gere les campagnes', 'Staff gère les campagnes'),
      ('donations', 'Creer un don', 'Créer un don'),
      ('events', 'Evenements publics', 'Événements publics'),
      ('events', 'Staff cree des evenements', 'Staff crée des événements'),
      ('events', 'Staff modifie des evenements', 'Staff modifie des événements'),
      ('finance_categories', 'Categories lisibles', 'Catégories lisibles'),
      ('islamic_contents', 'Staff gere le contenu islamique', 'Staff gère le contenu islamique'),
      ('monthly_reports', 'Bilans publies lisibles', 'Bilans publiés lisibles'),
      ('monthly_reports', 'Tresorier gere les bilans', 'Trésorier gère les bilans'),
      ('mosque_needs', 'Besoins mosquee visibles', 'Besoins mosquée visibles'),
      ('mosque_needs', 'Staff gere les besoins', 'Staff gère les besoins'),
      ('profiles', 'Creation de son propre profil', 'Création de son propre profil'),
      ('profiles', 'Mise a jour de son propre profil', 'Mise à jour de son propre profil'),
      ('transactions', 'Tresorier gere les transactions', 'Trésorier gère les transactions'),
      ('volunteer_signups', 'S inscrire benevole', 'S''inscrire bénévole')
    ) as t(tbl, ancien, nouveau)
  loop
    if exists (select 1 from pg_policies where schemaname = 'public'
                and tablename = r.tbl and policyname = r.ancien) then
      if exists (select 1 from pg_policies where schemaname = 'public'
                  and tablename = r.tbl and policyname = r.nouveau) then
        execute format('drop policy %I on public.%I', r.ancien, r.tbl);
      else
        execute format('alter policy %I on public.%I rename to %I', r.ancien, r.tbl, r.nouveau);
      end if;
    end if;
  end loop;
end
$$;

-- Doublons « v2 » (mêmes définitions que les policies d'origine).
drop policy if exists "Annonces publiques v2" on public.announcements;
drop policy if exists "Groupes visibles aux utilisateurs connectes v2" on public.chat_groups;
