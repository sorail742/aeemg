-- SEC-013 : Fixer le search_path des fonctions SECURITY DEFINER.
-- Exécution : supabase test db
begin;
select plan(8);

-- 1. Les 6 fonctions du fil social ont bien search_path = ''
select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'increment_post_likes',
        'decrement_post_likes',
        'increment_post_comments',
        'decrement_post_comments',
        'increment_follows',
        'decrement_follows'
      )
      and exists (
        select 1 from unnest(p.proconfig) cfg
         where cfg = 'search_path='
      )),
  6,
  'Les 6 fonctions de compteurs du fil social ont search_path='''''
);

-- 2. Aucune fonction SECURITY DEFINER sans search_path fixé dans le schéma public
select is(
  (select count(*)::int
     from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prosecdef
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, '{}'::text[])) cfg
         where cfg like 'search_path=%'
      )),
  0,
  '0 fonction SECURITY DEFINER sans search_path dans public'
);

-- 3. Test fonctionnel des triggers avec search_path fixé
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000a001', 'auteur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000a002', 'lecteur@aeemg.test');

insert into public.posts (id, user_id, content) values
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000a001', 'Post de test SEC-013');

-- Like & Unlike
insert into public.post_likes (post_id, user_id) values
  ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000a002');

select is(
  (select likes_count from public.posts where id = '50000000-0000-0000-0000-000000000001'),
  1,
  'increment_post_likes a incrémenté likes_count à 1'
);

delete from public.post_likes
 where post_id = '50000000-0000-0000-0000-000000000001'
   and user_id = '00000000-0000-0000-0000-00000000a002';

select is(
  (select likes_count from public.posts where id = '50000000-0000-0000-0000-000000000001'),
  0,
  'decrement_post_likes a décrémenté likes_count à 0'
);

-- Comment
insert into public.post_comments (id, post_id, user_id, content) values
  ('50000000-0000-0000-0000-000000000002', '50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000a002', 'Commentaire');

select is(
  (select comments_count from public.posts where id = '50000000-0000-0000-0000-000000000001'),
  1,
  'increment_post_comments a incrémenté comments_count à 1'
);

delete from public.post_comments
 where id = '50000000-0000-0000-0000-000000000002';

select is(
  (select comments_count from public.posts where id = '50000000-0000-0000-0000-000000000001'),
  0,
  'decrement_post_comments a décrémenté comments_count à 0'
);

-- Follow & Unfollow
insert into public.follows (follower_id, following_id) values
  ('00000000-0000-0000-0000-00000000a002', '00000000-0000-0000-0000-00000000a001');

select is(
  (select followers_count from public.profiles where id = '00000000-0000-0000-0000-00000000a001'),
  1,
  'increment_follows a incrémenté followers_count à 1'
);

delete from public.follows
 where follower_id = '00000000-0000-0000-0000-00000000a002'
   and following_id = '00000000-0000-0000-0000-00000000a001';

select is(
  (select followers_count from public.profiles where id = '00000000-0000-0000-0000-00000000a001'),
  0,
  'decrement_follows a décrémenté followers_count à 0'
);

select * from finish();
rollback;
