-- Phase 1 — MVP : communication, événements, notifications

create type public.event_type as enum (
  'conference', 'quran_contest', 'outing', 'iftar', 'halaqa', 'training', 'other'
);

create type public.notification_category as enum (
  'events', 'finance', 'messages', 'islamic', 'general'
);

create type public.rsvp_status as enum ('going', 'maybe', 'not_going');

-- Helpers rôles
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

-- Événements
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
create policy "Groupes visibles aux utilisateurs connectés"
  on public.chat_groups for select
  using (auth.uid() is not null);

create policy "Staff crée des groupes"
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
create policy "Lecture de ses accusés"
  on public.announcement_reads for select
  using (user_id = auth.uid());

create policy "Marquer comme lu"
  on public.announcement_reads for insert
  with check (user_id = auth.uid());

-- events
create policy "Événements publics"
  on public.events for select
  using (true);

create policy "Staff crée des événements"
  on public.events for insert
  with check (public.is_staff());

create policy "Staff modifie des événements"
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

create policy "Staff gère le contenu islamique"
  on public.islamic_contents for insert
  with check (public.is_staff());

-- Realtime (idempotent)
do $$ begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table public.notifications;
exception when duplicate_object then null; end $$;

-- Données initiales
insert into public.chat_groups (name, description, is_official)
values ('Général AEEMG', 'Discussions de toute la communauté', true);

insert into public.islamic_contents (content_type, title, body, source, active_date)
values (
  'verse',
  'Verset du jour',
  'Et cramponnez-vous tous ensemble au câble d''Allah et ne vous divisez pas.',
  'Coran 3:103',
  current_date
);
