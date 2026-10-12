-- Garde-fous de sécurité du schéma (ADR-0007, AMEL-008).
-- Exécution : supabase test db
-- Les tests marqués todo() documentent une faille connue : ils n'échouent pas la
-- suite tant que le ticket n'est pas livré. Retirer le todo() dans la PR du correctif.
begin;
select plan(4);

-- 1. RLS activée sur toutes les tables du schéma public.
select is(
  (select count(*)::int
     from pg_class c
     join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity),
  0,
  'RLS activée sur toutes les tables de public'
);

-- 2. Aucune policy « ouverte à tous » en écriture (with check (true)).
select todo('SEC-004 : group_invitations accepte with check (true)', 1);
select is(
  (select count(*)::int
     from pg_policies
    where schemaname = 'public'
      and cmd in ('INSERT', 'UPDATE', 'ALL')
      and coalesce(with_check, qual) = 'true'),
  0,
  'Aucune policy d''écriture with check (true) dans public'
);

-- 3. Toute fonction SECURITY DEFINER fixe son search_path.
select todo('SEC-013 : fonctions de compteurs sociales sans search_path', 1);
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
  'Toutes les fonctions SECURITY DEFINER de public fixent search_path'
);

-- 4. Un membre ne peut pas s'attribuer le rôle super_admin (SEC-001).
insert into auth.users (id, email, raw_user_meta_data)
values ('00000000-0000-0000-0000-0000000000a1', 'membre-test@aeemg.test', '{"full_name":"Membre Test"}');

select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);
set local role authenticated;

update public.profiles
   set role = 'super_admin'
 where id = '00000000-0000-0000-0000-0000000000a1';

reset role;

select todo('SEC-001 : la policy update de profiles autorise la modification du rôle', 1);
select is(
  (select role::text from public.profiles where id = '00000000-0000-0000-0000-0000000000a1'),
  'member',
  'Un membre ne peut pas modifier son propre rôle'
);

select * from finish();
rollback;
