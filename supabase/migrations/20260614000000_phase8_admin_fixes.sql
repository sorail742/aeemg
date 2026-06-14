-- Phase 8 : Corrections Admin - colonnes manquantes pour le panneau d'administration
-- Ajouter is_approved aux événements
alter table public.events
  add column if not exists is_approved boolean not null default false;

-- Ajouter is_published aux annonces (si pas présent)
alter table public.announcements
  add column if not exists is_published boolean not null default true;

-- Approuver tous les événements existants créés par le staff
update public.events set is_approved = true where created_by in (
  select id from public.profiles where role in ('super_admin', 'admin', 'moderator', 'section_lead')
);

-- Permettre au staff de voir tous les profils (pour la gestion des membres dans admin)
drop policy if exists "Staff voit tous les profils" on public.profiles;
create policy "Staff voit tous les profils"
  on public.profiles for select
  using (is_profile_public = true or auth.uid() = id or public.is_staff());

-- Permettre au staff de modifier les rôles des membres
drop policy if exists "Staff modifie les rôles" on public.profiles;
create policy "Staff modifie les rôles"
  on public.profiles for update
  using (auth.uid() = id or public.is_staff());

-- Permettre au staff de supprimer des membres (admin seulement)
drop policy if exists "Admin supprime membres" on public.profiles;
create policy "Admin supprime membres"
  on public.profiles for delete
  using (public.is_admin());

-- Staff peut supprimer des événements
drop policy if exists "Staff supprime des événements" on public.events;
create policy "Staff supprime des événements"
  on public.events for delete
  using (public.is_staff());

-- Staff peut supprimer des annonces
drop policy if exists "Staff supprime des annonces" on public.announcements;
create policy "Staff supprime des annonces"
  on public.announcements for delete
  using (public.is_staff());

-- Staff peut modifier les annonces
drop policy if exists "Staff modifie des annonces" on public.announcements;
create policy "Staff modifie des annonces"
  on public.announcements for update
  using (public.is_staff());
