-- SEC-013 — Fixer le search_path des fonctions SECURITY DEFINER
--
-- Contexte :
--   Les fonctions de compteurs du fil social (phase5_social.sql) étaient déclarées
--   SECURITY DEFINER sans clause SET search_path.
--   En l'absence de search_path fixé, l'exécution s'effectue avec le search_path
--   de l'appelant, ce qui ouvre un risque d'escalade par détournement d'objets
--   homonymes (signalé par Supabase DB lint : function_search_path_mutable).
--
-- Correction :
--   Application de `SET search_path = ''` et qualification complète de tous
--   les noms d'objets (public.posts, public.profiles, pg_catalog.greatest).

create or replace function public.increment_post_likes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.posts
     set likes_count = likes_count + 1
   where id = new.post_id;
  return new;
end;
$$;

create or replace function public.decrement_post_likes()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.posts
     set likes_count = pg_catalog.greatest(likes_count - 1, 0)
   where id = old.post_id;
  return old;
end;
$$;

create or replace function public.increment_post_comments()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.posts
     set comments_count = comments_count + 1
   where id = new.post_id;
  return new;
end;
$$;

create or replace function public.decrement_post_comments()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.posts
     set comments_count = pg_catalog.greatest(comments_count - 1, 0)
   where id = old.post_id;
  return old;
end;
$$;

create or replace function public.increment_follows()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
     set following_count = following_count + 1
   where id = new.follower_id;
  update public.profiles
     set followers_count = followers_count + 1
   where id = new.following_id;
  return new;
end;
$$;

create or replace function public.decrement_follows()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
     set following_count = pg_catalog.greatest(following_count - 1, 0)
   where id = old.follower_id;
  update public.profiles
     set followers_count = pg_catalog.greatest(followers_count - 1, 0)
   where id = old.following_id;
  return old;
end;
$$;
