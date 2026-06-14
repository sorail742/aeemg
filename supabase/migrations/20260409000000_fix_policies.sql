-- Correctifs : visibilité groupes/annonces + données de démo

-- Groupes visibles par tout utilisateur connecté (pas seulement les membres)
drop policy if exists "Groupes lisibles par membres" on public.chat_groups;
create policy "Groupes visibles aux utilisateurs connectés"
  on public.chat_groups for select
  using (auth.uid() is not null);

-- Annonces visibles même sans connexion (accueil visiteur)
drop policy if exists "Annonces lisibles par utilisateurs connectés" on public.announcements;
create policy "Annonces publiques"
  on public.announcements for select
  using (true);

-- Rejoindre automatiquement le groupe Général à la création du profil
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
  where name = 'Général AEEMG'
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

-- Événement de démo (si aucun événement à venir)
insert into public.events (title, description, event_type, location, starts_at)
select
  'Conférence AEEMG — Rentrée 2026',
  'Grande conférence de rentrée pour tous les membres.',
  'conference',
  'Mosquée AEEMG, Conakry',
  (current_date + interval '14 days')::timestamptz + time '18:00'
where not exists (select 1 from public.events limit 1);

-- Annonce de bienvenue
insert into public.announcements (title, content, is_important)
select
  'Bienvenue sur AEEMG Connect',
  'La plateforme officielle de communication de l''AEEMG est en ligne. Rejoignez le groupe Général pour rester informé.',
  true
where not exists (select 1 from public.announcements limit 1);
