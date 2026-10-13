-- AEEMG - Schema initial (Phase 0)
-- Stack : Supabase PostgreSQL + RLS

-- Roles utilisateur
create type public.user_role as enum (
  'super_admin',
  'admin',
  'moderator',
  'treasurer',
  'section_lead',
  'member',
  'volunteer',
  'visitor'
);

-- Profils membres (lie a auth.users)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text,
  section text,
  specialty text,
  avatar_url text,
  role public.user_role not null default 'member',
  is_profile_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Lecture : profils publics ou son propre profil
create policy "Profils publics lisibles"
  on public.profiles for select
  using (is_profile_public = true or auth.uid() = id);

-- Mise a jour : uniquement son propre profil
create policy "Mise a jour de son propre profil"
  on public.profiles for update
  using (auth.uid() = id);

-- Insertion : a la creation du compte
create policy "Creation de son propre profil"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Trigger : creer un profil a l'inscription
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Nouveau membre'),
    new.phone
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Mise a jour automatique de updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Phase 1 - MVP : communication, evenements, notifications

create type public.event_type as enum (
  'conference', 'quran_contest', 'outing', 'iftar', 'halaqa', 'training', 'other'
);

create type public.notification_category as enum (
  'events', 'finance', 'messages', 'islamic', 'general'
);

create type public.rsvp_status as enum ('going', 'maybe', 'not_going');

-- Helpers roles
create or replace function public.is_staff()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role in ('super_admin', 'admin', 'moderator', 'section_lead')
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role in ('super_admin', 'admin')
  );
$$;

-- Groupes de discussion
create table public.chat_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  is_official boolean not null default false,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.chat_group_members (
  group_id uuid not null references public.chat_groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.chat_groups (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  is_pinned boolean not null default false,
  created_at timestamptz not null default now()
);

-- Annonces officielles
create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text not null,
  author_id uuid references public.profiles (id),
  is_important boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.announcement_reads (
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (announcement_id, user_id)
);

-- Evenements
create table public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  event_type public.event_type not null default 'other',
  location text,
  starts_at timestamptz not null,
  ends_at timestamptz,
  is_recurring boolean not null default false,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create table public.event_rsvps (
  event_id uuid not null references public.events (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status public.rsvp_status not null default 'going',
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

-- Notifications in-app
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text not null,
  category public.notification_category not null default 'general',
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- Contenu islamique (verset du jour)
create table public.islamic_contents (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('verse', 'hadith', 'quote')),
  title text,
  body text not null,
  source text,
  translation_peul text,
  active_date date,
  created_at timestamptz not null default now()
);

-- RLS
alter table public.chat_groups enable row level security;
alter table public.chat_group_members enable row level security;
alter table public.messages enable row level security;
alter table public.announcements enable row level security;
alter table public.announcement_reads enable row level security;
alter table public.events enable row level security;
alter table public.event_rsvps enable row level security;
alter table public.notifications enable row level security;
alter table public.islamic_contents enable row level security;

-- chat_groups
create policy "Groupes visibles aux utilisateurs connectes"
  on public.chat_groups for select
  using (auth.uid() is not null);

create policy "Staff cree des groupes"
  on public.chat_groups for insert
  with check (public.is_staff());

-- chat_group_members
create policy "Membres de groupe visibles"
  on public.chat_group_members for select
  using (user_id = auth.uid() or public.is_staff());

create policy "Rejoindre un groupe"
  on public.chat_group_members for insert
  with check (auth.uid() = user_id);

-- messages
create policy "Messages du groupe lisibles"
  on public.messages for select
  using (
    exists (
      select 1 from public.chat_group_members m
      where m.group_id = messages.group_id and m.user_id = auth.uid()
    )
  );

create policy "Envoyer un message"
  on public.messages for insert
  with check (
    auth.uid() = sender_id and exists (
      select 1 from public.chat_group_members m
      where m.group_id = messages.group_id and m.user_id = auth.uid()
    )
  );

-- announcements
create policy "Annonces publiques"
  on public.announcements for select
  using (true);

create policy "Staff publie des annonces"
  on public.announcements for insert
  with check (public.is_staff());

-- announcement_reads
create policy "Lecture de ses accuses"
  on public.announcement_reads for select
  using (user_id = auth.uid());

create policy "Marquer comme lu"
  on public.announcement_reads for insert
  with check (user_id = auth.uid());

-- events
create policy "Evenements publics"
  on public.events for select
  using (true);

create policy "Staff cree des evenements"
  on public.events for insert
  with check (public.is_staff());

create policy "Staff modifie des evenements"
  on public.events for update
  using (public.is_staff());

-- event_rsvps
create policy "RSVP visibles"
  on public.event_rsvps for select
  using (true);

create policy "Son propre RSVP"
  on public.event_rsvps for insert
  with check (auth.uid() = user_id);

create policy "Modifier son RSVP"
  on public.event_rsvps for update
  using (auth.uid() = user_id);

-- notifications
create policy "Ses notifications"
  on public.notifications for select
  using (user_id = auth.uid());

create policy "Marquer notification lue"
  on public.notifications for update
  using (user_id = auth.uid());

-- islamic_contents
create policy "Contenu islamique public"
  on public.islamic_contents for select
  using (true);

create policy "Staff gere le contenu islamique"
  on public.islamic_contents for insert
  with check (public.is_staff());

-- Realtime (idempotent)
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;

-- Donnees initiales
insert into public.chat_groups (name, description, is_official)
values ('General AEEMG', 'Discussions de toute la communaute', true);

insert into public.islamic_contents (content_type, title, body, source, active_date)
values (
  'verse',
  'Verset du jour',
  'Et cramponnez-vous tous ensemble au cable d''Allah et ne vous divisez pas.',
  'Coran 3:103',
  current_date
);

-- Phase 2 - Finances, Dons, Mosquee, Rappels

create type public.transaction_type as enum ('income', 'expense');
create type public.donation_category as enum (
  'general', 'ramadan_iftar', 'mosque_renovation', 'emergency'
);
create type public.donation_status as enum ('pending', 'completed', 'failed');
create type public.mosque_need_status as enum ('open', 'fulfilled', 'cancelled');

-- Finances
create table public.finance_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  type public.transaction_type not null,
  amount numeric(12, 2) not null check (amount > 0),
  category_id uuid references public.finance_categories (id),
  description text,
  recorded_by uuid references public.profiles (id),
  transaction_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table public.monthly_reports (
  id uuid primary key default gen_random_uuid(),
  year int not null,
  month int not null check (month between 1 and 12),
  total_income numeric(12, 2) not null default 0,
  total_expense numeric(12, 2) not null default 0,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  unique (year, month)
);

-- Dons
create table public.donation_campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category public.donation_category not null default 'general',
  goal_amount numeric(12, 2) not null,
  raised_amount numeric(12, 2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.donations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id),
  campaign_id uuid references public.donation_campaigns (id),
  amount numeric(12, 2) not null check (amount > 0),
  category public.donation_category not null default 'general',
  is_anonymous boolean not null default false,
  status public.donation_status not null default 'pending',
  payment_method text,
  created_at timestamptz not null default now()
);

-- Mosquee
create table public.mosque_needs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  quantity_needed int not null default 1,
  quantity_fulfilled int not null default 0,
  status public.mosque_need_status not null default 'open',
  created_at timestamptz not null default now()
);

create table public.volunteer_signups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  mission text not null,
  event_date date,
  notes text,
  created_at timestamptz not null default now()
);

create table public.islamic_favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  content_id uuid not null references public.islamic_contents (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, content_id)
);

-- RLS
alter table public.finance_categories enable row level security;
alter table public.transactions enable row level security;
alter table public.monthly_reports enable row level security;
alter table public.donation_campaigns enable row level security;
alter table public.donations enable row level security;
alter table public.mosque_needs enable row level security;
alter table public.volunteer_signups enable row level security;
alter table public.islamic_favorites enable row level security;

create or replace function public.is_treasurer()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role in ('super_admin', 'admin', 'treasurer')
  );
$$;

-- finance_categories
create policy "Categories lisibles"
  on public.finance_categories for select using (auth.uid() is not null);

-- transactions
create policy "Tresorier gere les transactions"
  on public.transactions for all
  using (public.is_treasurer())
  with check (public.is_treasurer());

-- monthly_reports
create policy "Bilans publies lisibles"
  on public.monthly_reports for select
  using (is_published or public.is_treasurer());

create policy "Tresorier gere les bilans"
  on public.monthly_reports for all
  using (public.is_treasurer())
  with check (public.is_treasurer());

-- donation_campaigns
create policy "Campagnes visibles"
  on public.donation_campaigns for select using (true);

create policy "Staff gere les campagnes"
  on public.donation_campaigns for all
  using (public.is_staff())
  with check (public.is_staff());

-- donations
create policy "Ses dons ou staff"
  on public.donations for select
  using (user_id = auth.uid() or public.is_staff());

create policy "Creer un don"
  on public.donations for insert
  with check (auth.uid() = user_id);

-- mosque_needs
create policy "Besoins mosquee visibles"
  on public.mosque_needs for select using (true);

create policy "Staff gere les besoins"
  on public.mosque_needs for all
  using (public.is_staff())
  with check (public.is_staff());

-- volunteer_signups
create policy "Inscriptions visibles staff ou soi"
  on public.volunteer_signups for select
  using (user_id = auth.uid() or public.is_staff());

create policy "S inscrire benevole"
  on public.volunteer_signups for insert
  with check (auth.uid() = user_id);

-- islamic_favorites
create policy "Ses favoris"
  on public.islamic_favorites for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Donnees initiales
insert into public.finance_categories (name) values
  ('Activites'), ('Mosquee'), ('Fournitures'), ('Iftar'), ('Autres');

insert into public.donation_campaigns (title, description, category, goal_amount)
values (
  'Fonds Ramadan 2026',
  'Soutenez les iftars communautaires de l''AEEMG.',
  'ramadan_iftar',
  50000000
);

insert into public.mosque_needs (title, description, quantity_needed)
values
  ('Tapis de priere', 'Renouvellement des tapis de la salle principale', 20),
  ('Bouteilles d''eau', 'Pour les fideles lors du vendredi', 100);

-- Correctifs : visibilite groupes/annonces + donnees de demo

-- Groupes visibles par tout utilisateur connecte (pas seulement les membres)
drop policy if exists "Groupes lisibles par membres" on public.chat_groups;
create policy "Groupes visibles aux utilisateurs connectes v2"
  on public.chat_groups for select
  using (auth.uid() is not null);

-- Annonces visibles meme sans connexion (accueil visiteur)
drop policy if exists "Annonces lisibles par utilisateurs connectes" on public.announcements;
create policy "Annonces publiques v2"
  on public.announcements for select
  using (true);

-- Rejoindre automatiquement le groupe General a la creation du profil
create or replace function public.join_default_chat_group()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
declare
  default_group_id uuid;
begin
  select id into default_group_id
  from public.chat_groups
  where name = 'General AEEMG'
  limit 1;

  if default_group_id is not null then
    insert into public.chat_group_members (group_id, user_id)
    values (default_group_id, new.id)
    on conflict do nothing;
  end if;

  return new;
end;
$$;

drop trigger if exists on_profile_join_default_group on public.profiles;
create trigger on_profile_join_default_group
  after insert on public.profiles
  for each row execute function public.join_default_chat_group();

-- Evenement de demo (si aucun evenement a venir)
insert into public.events (title, description, event_type, location, starts_at)
select
  'Conference AEEMG - Rentree 2026',
  'Grande conference de rentree pour tous les membres.',
  'conference',
  'Mosquee AEEMG, Conakry',
  (current_date + interval '14 days')::timestamptz + time '18:00'
where not exists (select 1 from public.events limit 1);

-- Annonce de bienvenue
insert into public.announcements (title, content, is_important)
select
  'Bienvenue sur AEEMG',
  'La plateforme officielle de communication de l''AEEMG est en ligne. Rejoignez le groupe General pour rester informe.',
  true
where not exists (select 1 from public.announcements limit 1);

-- Phase 3 — Lancement : preferences notifications, tokens push

create table if not exists public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  events_enabled boolean not null default true,
  finance_enabled boolean not null default true,
  messages_enabled boolean not null default true,
  islamic_enabled boolean not null default true,
  general_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.push_device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

alter table public.notification_preferences enable row level security;
alter table public.push_device_tokens enable row level security;

create policy "Ses preferences notifications"
  on public.notification_preferences for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Ses tokens push"
  on public.push_device_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.create_default_notification_prefs()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_profile_notification_prefs on public.profiles;
create trigger on_profile_notification_prefs
  after insert on public.profiles
  for each row execute function public.create_default_notification_prefs();

insert into public.notification_preferences (user_id)
select id from public.profiles
on conflict (user_id) do nothing;

-- Auth email + feedback (Phase 3)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Nouveau membre'),
    coalesce(new.phone, new.email)
  );
  return new;
end;
$$;

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  message text not null,
  rating int check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

drop policy if exists "Envoyer un retour" on public.feedback;
create policy "Envoyer un retour"
  on public.feedback for insert
  with check (auth.uid() = user_id or user_id is null);

drop policy if exists "Staff lit les retours" on public.feedback;
create policy "Staff lit les retours"
  on public.feedback for select
  using (public.is_staff());

-- Phase 4 — Evolution
do $$ begin
  create type public.payment_provider as enum ('orange_money', 'mtn_momo');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.payment_status as enum ('initiated', 'pending', 'completed', 'failed', 'cancelled');
exception when duplicate_object then null; end $$;

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
  add column if not exists preferred_locale text not null default 'fr';

alter table public.payment_sessions enable row level security;
alter table public.sms_notifications enable row level security;

drop policy if exists "Ses sessions paiement" on public.payment_sessions;
create policy "Ses sessions paiement"
  on public.payment_sessions for select
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists "Creer session paiement" on public.payment_sessions;
create policy "Creer session paiement"
  on public.payment_sessions for insert
  with check (auth.uid() = user_id);

drop policy if exists "Staff gere paiements" on public.payment_sessions;
create policy "Staff gere paiements"
  on public.payment_sessions for update
  using (public.is_staff());

drop policy if exists "Ses SMS" on public.sms_notifications;
create policy "Ses SMS"
  on public.sms_notifications for select
  using (user_id = auth.uid() or public.is_staff());

drop policy if exists "Staff envoie SMS" on public.sms_notifications;
create policy "Staff envoie SMS"
  on public.sms_notifications for insert
  with check (public.is_staff());- -   P h a s e   5   -   R e s e a u   S o c i a l   ( P o s t s ,   C o m m e n t a i r e s ,   L i k e s ,   F o l l o w s )  
  
 c r e a t e   t a b l e   i f   n o t   e x i s t s   p u b l i c . p o s t s   (  
     i d   u u i d   p r i m a r y   k e y   d e f a u l t   g e n _ r a n d o m _ u u i d ( ) ,  
     a u t h o r _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p r o f i l e s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     c o n t e n t   t e x t   n o t   n u l l ,  
     i m a g e _ u r l   t e x t ,  
     l i k e s _ c o u n t   i n t   n o t   n u l l   d e f a u l t   0 ,  
     c o m m e n t s _ c o u n t   i n t   n o t   n u l l   d e f a u l t   0 ,  
     c r e a t e d _ a t   t i m e s t a m p t z   n o t   n u l l   d e f a u l t   n o w ( ) ,  
     u p d a t e d _ a t   t i m e s t a m p t z   n o t   n u l l   d e f a u l t   n o w ( )  
 ) ;  
  
 c r e a t e   t a b l e   i f   n o t   e x i s t s   p u b l i c . p o s t _ l i k e s   (  
     p o s t _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p o s t s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     u s e r _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p r o f i l e s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     c r e a t e d _ a t   t i m e s t a m p t z   n o t   n u l l   d e f a u l t   n o w ( ) ,  
     p r i m a r y   k e y   ( p o s t _ i d ,   u s e r _ i d )  
 ) ;  
  
 c r e a t e   t a b l e   i f   n o t   e x i s t s   p u b l i c . p o s t _ c o m m e n t s   (  
     i d   u u i d   p r i m a r y   k e y   d e f a u l t   g e n _ r a n d o m _ u u i d ( ) ,  
     p o s t _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p o s t s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     a u t h o r _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p r o f i l e s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     c o n t e n t   t e x t   n o t   n u l l ,  
     c r e a t e d _ a t   t i m e s t a m p t z   n o t   n u l l   d e f a u l t   n o w ( ) ,  
     u p d a t e d _ a t   t i m e s t a m p t z   n o t   n u l l   d e f a u l t   n o w ( )  
 ) ;  
  
 c r e a t e   t a b l e   i f   n o t   e x i s t s   p u b l i c . f o l l o w s   (  
     f o l l o w e r _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p r o f i l e s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     f o l l o w i n g _ i d   u u i d   n o t   n u l l   r e f e r e n c e s   p u b l i c . p r o f i l e s   ( i d )   o n   d e l e t e   c a s c a d e ,  
     c r e a t e d _ a t   t i m e s t a m p t z   n o t   n u l l   d e f a u l t   n o w ( ) ,  
     p r i m a r y   k e y   ( f o l l o w e r _ i d ,   f o l l o w i n g _ i d ) ,  
     c h e c k   ( f o l l o w e r _ i d   ! =   f o l l o w i n g _ i d )  
 ) ;  
  
 - -   T r i g g e r s   p o u r   u p d a t e d _ a t  
 c r e a t e   t r i g g e r   p o s t s _ u p d a t e d _ a t  
     b e f o r e   u p d a t e   o n   p u b l i c . p o s t s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . s e t _ u p d a t e d _ a t ( ) ;  
  
 c r e a t e   t r i g g e r   p o s t _ c o m m e n t s _ u p d a t e d _ a t  
     b e f o r e   u p d a t e   o n   p u b l i c . p o s t _ c o m m e n t s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . s e t _ u p d a t e d _ a t ( ) ;  
  
 - -   R L S  
 a l t e r   t a b l e   p u b l i c . p o s t s   e n a b l e   r o w   l e v e l   s e c u r i t y ;  
 a l t e r   t a b l e   p u b l i c . p o s t _ l i k e s   e n a b l e   r o w   l e v e l   s e c u r i t y ;  
 a l t e r   t a b l e   p u b l i c . p o s t _ c o m m e n t s   e n a b l e   r o w   l e v e l   s e c u r i t y ;  
 a l t e r   t a b l e   p u b l i c . f o l l o w s   e n a b l e   r o w   l e v e l   s e c u r i t y ;  
  
 - -   P o s t s   ( P u b l i c   p o u r   t o u s   l e s   c o n n e c t e s )  
 c r e a t e   p o l i c y   " P o s t s   l i s i b l e s   p a r   t o u s   l e s   c o n n e c t e s "  
     o n   p u b l i c . p o s t s   f o r   s e l e c t  
     u s i n g   ( a u t h . u i d ( )   i s   n o t   n u l l ) ;  
  
 c r e a t e   p o l i c y   " C r e e r   u n   p o s t "  
     o n   p u b l i c . p o s t s   f o r   i n s e r t  
     w i t h   c h e c k   ( a u t h . u i d ( )   =   a u t h o r _ i d ) ;  
  
 c r e a t e   p o l i c y   " M o d i f i e r   s o n   p o s t "  
     o n   p u b l i c . p o s t s   f o r   u p d a t e  
     u s i n g   ( a u t h . u i d ( )   =   a u t h o r _ i d ) ;  
  
 c r e a t e   p o l i c y   " S u p p r i m e r   s o n   p o s t "  
     o n   p u b l i c . p o s t s   f o r   d e l e t e  
     u s i n g   ( a u t h . u i d ( )   =   a u t h o r _ i d   o r   p u b l i c . i s _ s t a f f ( ) ) ;  
  
 - -   P o s t   L i k e s  
 c r e a t e   p o l i c y   " L i k e s   l i s i b l e s "  
     o n   p u b l i c . p o s t _ l i k e s   f o r   s e l e c t  
     u s i n g   ( a u t h . u i d ( )   i s   n o t   n u l l ) ;  
  
 c r e a t e   p o l i c y   " L i k e r "  
     o n   p u b l i c . p o s t _ l i k e s   f o r   i n s e r t  
     w i t h   c h e c k   ( a u t h . u i d ( )   =   u s e r _ i d ) ;  
  
 c r e a t e   p o l i c y   " U n l i k e r "  
     o n   p u b l i c . p o s t _ l i k e s   f o r   d e l e t e  
     u s i n g   ( a u t h . u i d ( )   =   u s e r _ i d ) ;  
  
 - -   P o s t   C o m m e n t s  
 c r e a t e   p o l i c y   " C o m m e n t a i r e s   l i s i b l e s "  
     o n   p u b l i c . p o s t _ c o m m e n t s   f o r   s e l e c t  
     u s i n g   ( a u t h . u i d ( )   i s   n o t   n u l l ) ;  
  
 c r e a t e   p o l i c y   " C o m m e n t e r "  
     o n   p u b l i c . p o s t _ c o m m e n t s   f o r   i n s e r t  
     w i t h   c h e c k   ( a u t h . u i d ( )   =   a u t h o r _ i d ) ;  
  
 c r e a t e   p o l i c y   " M o d i f i e r   s o n   c o m m e n t a i r e "  
     o n   p u b l i c . p o s t _ c o m m e n t s   f o r   u p d a t e  
     u s i n g   ( a u t h . u i d ( )   =   a u t h o r _ i d ) ;  
  
 c r e a t e   p o l i c y   " S u p p r i m e r   s o n   c o m m e n t a i r e "  
     o n   p u b l i c . p o s t _ c o m m e n t s   f o r   d e l e t e  
     u s i n g   ( a u t h . u i d ( )   =   a u t h o r _ i d   o r   p u b l i c . i s _ s t a f f ( ) ) ;  
  
 - -   F o l l o w s  
 c r e a t e   p o l i c y   " A b o n n e m e n t s   l i s i b l e s "  
     o n   p u b l i c . f o l l o w s   f o r   s e l e c t  
     u s i n g   ( a u t h . u i d ( )   i s   n o t   n u l l ) ;  
  
 c r e a t e   p o l i c y   " S ' a b o n n e r "  
     o n   p u b l i c . f o l l o w s   f o r   i n s e r t  
     w i t h   c h e c k   ( a u t h . u i d ( )   =   f o l l o w e r _ i d ) ;  
  
 c r e a t e   p o l i c y   " S e   d e s a b o n n e r "  
     o n   p u b l i c . f o l l o w s   f o r   d e l e t e  
     u s i n g   ( a u t h . u i d ( )   =   f o l l o w e r _ i d ) ;  
  
 - -   S t o r a g e   p o u r   l e s   i m a g e s   d e s   p o s t s  
 i n s e r t   i n t o   s t o r a g e . b u c k e t s   ( i d ,   n a m e ,   p u b l i c )    
 v a l u e s   ( ' s o c i a l _ i m a g e s ' ,   ' s o c i a l _ i m a g e s ' ,   t r u e )  
 o n   c o n f l i c t   ( i d )   d o   n o t h i n g ;  
  
 c r e a t e   p o l i c y   " I m a g e s   p u b l i q u e s "  
     o n   s t o r a g e . o b j e c t s   f o r   s e l e c t  
     u s i n g   ( b u c k e t _ i d   =   ' s o c i a l _ i m a g e s ' ) ;  
  
 c r e a t e   p o l i c y   " U t i l i s a t e u r s   u p l o a d e n t   i m a g e s "  
     o n   s t o r a g e . o b j e c t s   f o r   i n s e r t  
     w i t h   c h e c k   ( b u c k e t _ i d   =   ' s o c i a l _ i m a g e s '   a n d   a u t h . u i d ( )   i s   n o t   n u l l ) ;  
  
 c r e a t e   p o l i c y   " U t i l i s a t e u r s   g e r e n t   l e u r s   i m a g e s "  
     o n   s t o r a g e . o b j e c t s   f o r   d e l e t e  
     u s i n g   ( b u c k e t _ i d   =   ' s o c i a l _ i m a g e s '   a n d   a u t h . u i d ( )   =   o w n e r ) ;  
  
 - -   F o n c t i o n s   e t   T r i g g e r s   p o u r   i n c r e m e n t e r   l e s   c o m p t e u r s  
 c r e a t e   o r   r e p l a c e   f u n c t i o n   p u b l i c . i n c r e m e n t _ p o s t _ l i k e s ( )  
 r e t u r n s   t r i g g e r   l a n g u a g e   p l p g s q l   s e c u r i t y   d e f i n e r   a s   $ $  
 b e g i n  
     u p d a t e   p u b l i c . p o s t s   s e t   l i k e s _ c o u n t   =   l i k e s _ c o u n t   +   1   w h e r e   i d   =   n e w . p o s t _ i d ;  
     r e t u r n   n e w ;  
 e n d ;  
 $ $ ;  
  
 c r e a t e   t r i g g e r   o n _ p o s t _ l i k e _ i n s e r t  
     a f t e r   i n s e r t   o n   p u b l i c . p o s t _ l i k e s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . i n c r e m e n t _ p o s t _ l i k e s ( ) ;  
  
 c r e a t e   o r   r e p l a c e   f u n c t i o n   p u b l i c . d e c r e m e n t _ p o s t _ l i k e s ( )  
 r e t u r n s   t r i g g e r   l a n g u a g e   p l p g s q l   s e c u r i t y   d e f i n e r   a s   $ $  
 b e g i n  
     u p d a t e   p u b l i c . p o s t s   s e t   l i k e s _ c o u n t   =   g r e a t e s t ( l i k e s _ c o u n t   -   1 ,   0 )   w h e r e   i d   =   o l d . p o s t _ i d ;  
     r e t u r n   o l d ;  
 e n d ;  
 $ $ ;  
  
 c r e a t e   t r i g g e r   o n _ p o s t _ l i k e _ d e l e t e  
     a f t e r   d e l e t e   o n   p u b l i c . p o s t _ l i k e s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . d e c r e m e n t _ p o s t _ l i k e s ( ) ;  
  
 c r e a t e   o r   r e p l a c e   f u n c t i o n   p u b l i c . i n c r e m e n t _ p o s t _ c o m m e n t s ( )  
 r e t u r n s   t r i g g e r   l a n g u a g e   p l p g s q l   s e c u r i t y   d e f i n e r   a s   $ $  
 b e g i n  
     u p d a t e   p u b l i c . p o s t s   s e t   c o m m e n t s _ c o u n t   =   c o m m e n t s _ c o u n t   +   1   w h e r e   i d   =   n e w . p o s t _ i d ;  
     r e t u r n   n e w ;  
 e n d ;  
 $ $ ;  
  
 c r e a t e   t r i g g e r   o n _ p o s t _ c o m m e n t _ i n s e r t  
     a f t e r   i n s e r t   o n   p u b l i c . p o s t _ c o m m e n t s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . i n c r e m e n t _ p o s t _ c o m m e n t s ( ) ;  
  
 c r e a t e   o r   r e p l a c e   f u n c t i o n   p u b l i c . d e c r e m e n t _ p o s t _ c o m m e n t s ( )  
 r e t u r n s   t r i g g e r   l a n g u a g e   p l p g s q l   s e c u r i t y   d e f i n e r   a s   $ $  
 b e g i n  
     u p d a t e   p u b l i c . p o s t s   s e t   c o m m e n t s _ c o u n t   =   g r e a t e s t ( c o m m e n t s _ c o u n t   -   1 ,   0 )   w h e r e   i d   =   o l d . p o s t _ i d ;  
     r e t u r n   o l d ;  
 e n d ;  
 $ $ ;  
  
 c r e a t e   t r i g g e r   o n _ p o s t _ c o m m e n t _ d e l e t e  
     a f t e r   d e l e t e   o n   p u b l i c . p o s t _ c o m m e n t s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . d e c r e m e n t _ p o s t _ c o m m e n t s ( ) ;  
  
 - -   A j o u t   d ' u n   c o m p t e   d e   f o l l o w e r s   d a n s   p u b l i c . p r o f i l e s   ( o p t i o n n e l   m a i s   u t i l e )  
 a l t e r   t a b l e   p u b l i c . p r o f i l e s   a d d   c o l u m n   i f   n o t   e x i s t s   f o l l o w e r s _ c o u n t   i n t   n o t   n u l l   d e f a u l t   0 ;  
 a l t e r   t a b l e   p u b l i c . p r o f i l e s   a d d   c o l u m n   i f   n o t   e x i s t s   f o l l o w i n g _ c o u n t   i n t   n o t   n u l l   d e f a u l t   0 ;  
  
 c r e a t e   o r   r e p l a c e   f u n c t i o n   p u b l i c . i n c r e m e n t _ f o l l o w s ( )  
 r e t u r n s   t r i g g e r   l a n g u a g e   p l p g s q l   s e c u r i t y   d e f i n e r   a s   $ $  
 b e g i n  
     u p d a t e   p u b l i c . p r o f i l e s   s e t   f o l l o w i n g _ c o u n t   =   f o l l o w i n g _ c o u n t   +   1   w h e r e   i d   =   n e w . f o l l o w e r _ i d ;  
     u p d a t e   p u b l i c . p r o f i l e s   s e t   f o l l o w e r s _ c o u n t   =   f o l l o w e r s _ c o u n t   +   1   w h e r e   i d   =   n e w . f o l l o w i n g _ i d ;  
     r e t u r n   n e w ;  
 e n d ;  
 $ $ ;  
  
 c r e a t e   t r i g g e r   o n _ f o l l o w _ i n s e r t  
     a f t e r   i n s e r t   o n   p u b l i c . f o l l o w s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . i n c r e m e n t _ f o l l o w s ( ) ;  
  
 c r e a t e   o r   r e p l a c e   f u n c t i o n   p u b l i c . d e c r e m e n t _ f o l l o w s ( )  
 r e t u r n s   t r i g g e r   l a n g u a g e   p l p g s q l   s e c u r i t y   d e f i n e r   a s   $ $  
 b e g i n  
     u p d a t e   p u b l i c . p r o f i l e s   s e t   f o l l o w i n g _ c o u n t   =   g r e a t e s t ( f o l l o w i n g _ c o u n t   -   1 ,   0 )   w h e r e   i d   =   o l d . f o l l o w e r _ i d ;  
     u p d a t e   p u b l i c . p r o f i l e s   s e t   f o l l o w e r s _ c o u n t   =   g r e a t e s t ( f o l l o w e r s _ c o u n t   -   1 ,   0 )   w h e r e   i d   =   o l d . f o l l o w i n g _ i d ;  
     r e t u r n   o l d ;  
 e n d ;  
 $ $ ;  
  
 c r e a t e   t r i g g e r   o n _ f o l l o w _ d e l e t e  
     a f t e r   d e l e t e   o n   p u b l i c . f o l l o w s  
     f o r   e a c h   r o w   e x e c u t e   f u n c t i o n   p u b l i c . d e c r e m e n t _ f o l l o w s ( ) ;  
 