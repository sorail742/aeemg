-- Phase 3 — Lancement : préférences notifications, tokens push

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

create policy "Ses préférences notifications"
  on public.notification_preferences for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "Ses tokens push"
  on public.push_device_tokens for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Préférences par défaut à la création du profil
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

-- Membres existants sans préférences
insert into public.notification_preferences (user_id)
select id from public.profiles
on conflict (user_id) do nothing;
