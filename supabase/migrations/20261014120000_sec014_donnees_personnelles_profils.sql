-- SEC-014 — Protéger les données personnelles des profils
--
-- Contexte :
--   1. handle_new_user copiait l'email dans la colonne phone.
--   2. is_profile_public valait true par défaut.
--   3. Les policies de lecture exposaient toutes les colonnes (phone, email)
--      à tous les utilisateurs (y compris anon pour les profils publics).
--
-- Actions :
--   1. Colonne email distincte dans profiles et nettoyage des emails dans phone.
--   2. Contrainte empêchant tout email futur dans profiles.phone.
--   3. is_profile_public passe à false par défaut pour les nouveaux comptes.
--   4. Mise à jour de handle_new_user() (phone = new.phone, email = new.email,
--      is_profile_public = false par défaut).
--   5. Restriction des policies RLS sur public.profiles (aucun accès anon,
--      seul l'utilisateur et le staff lisent les données privées de profiles).
--   6. Création de la vue public.member_directory (colonnes non sensibles,
--      phone masqué pour les tiers et visible uniquement par soi et le staff).

-- 1. Structure de la table profiles & nettoyage des données -------------------------------

alter table public.profiles add column if not exists email text;

-- Déplacer les emails indûment enregistrés dans phone vers email
update public.profiles
   set email = coalesce(email, phone),
       phone = null
 where phone like '%@%';

-- Contrainte interdisant toute adresse email dans phone
alter table public.profiles drop constraint if exists profiles_phone_not_email;
alter table public.profiles add constraint profiles_phone_not_email
  check (phone is null or phone not like '%@%');

-- Nouveaux comptes non publics par défaut (Privacy by Default)
alter table public.profiles alter column is_profile_public set default false;

-- 2. Trigger d'inscription handle_new_user ------------------------------------------------

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone, email, is_profile_public)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Nouveau membre'),
    new.phone,
    new.email,
    coalesce((new.raw_user_meta_data ->> 'is_profile_public')::boolean, false)
  );
  return new;
end;
$$;

-- 3. RLS sur public.profiles --------------------------------------------------------------

drop policy if exists "Profils publics lisibles" on public.profiles;
drop policy if exists "Staff voit tous les profils" on public.profiles;
drop policy if exists "Profils lisibles par proprietaire et staff" on public.profiles;

create policy "Profils lisibles par proprietaire et staff"
  on public.profiles for select
  using (
    auth.uid() = id
    or public.is_staff()
  );

-- 4. Vue public.member_directory ----------------------------------------------------------

create or replace view public.member_directory
with (security_invoker = false)
as
select
  p.id,
  p.full_name,
  p.avatar_url,
  p.section,
  p.specialty,
  p.role,
  p.is_profile_public,
  p.created_at,
  case
    when auth.uid() = p.id or public.is_staff() then p.phone
    else null
  end as phone
from public.profiles p
where (p.is_profile_public = true or auth.uid() = p.id or public.is_staff())
  and auth.role() = 'authenticated';

comment on view public.member_directory is
  'Annuaire des membres : réservé aux connectés, téléphone masqué pour les tiers (SEC-014).';

grant select on public.member_directory to authenticated;
revoke all on public.member_directory from anon;
