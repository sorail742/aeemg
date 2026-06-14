-- AEEMG Connect — Schéma initial (Phase 0)
-- Stack : Supabase PostgreSQL + RLS

-- Rôles utilisateur
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

-- Profils membres (lié à auth.users)
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

-- Mise à jour : uniquement son propre profil
create policy "Mise à jour de son propre profil"
  on public.profiles for update
  using (auth.uid() = id);

-- Insertion : à la création du compte
create policy "Création de son propre profil"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Trigger : créer un profil à l'inscription
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

-- Mise à jour automatique de updated_at
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
