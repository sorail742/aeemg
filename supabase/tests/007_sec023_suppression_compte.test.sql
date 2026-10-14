-- SEC-023 : autorisation de la suppression d'un compte et absence de lignes orphelines.
-- Exécution : supabase test db
begin;
select plan(11);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000a101', 'super@aeemg.test'),
  ('00000000-0000-0000-0000-00000000a102', 'admin@aeemg.test'),
  ('00000000-0000-0000-0000-00000000a103', 'moderateur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000a104', 'membre@aeemg.test'),
  ('00000000-0000-0000-0000-00000000a105', 'admin2@aeemg.test');
update public.profiles p set role = r.role::public.user_role
  from (values
    ('00000000-0000-0000-0000-00000000a101'::uuid, 'super_admin'),
    ('00000000-0000-0000-0000-00000000a102'::uuid, 'admin'),
    ('00000000-0000-0000-0000-00000000a103'::uuid, 'moderator'),
    ('00000000-0000-0000-0000-00000000a105'::uuid, 'admin')
  ) as r(id, role)
 where p.id = r.id;

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- Autorisation ----------------------------------------------------------------------------

select pg_temp.login('00000000-0000-0000-0000-00000000a103');
set local role authenticated;
select throws_ok(
  $$select public.check_member_deletion('00000000-0000-0000-0000-00000000a104')$$,
  '42501', null, 'Un modérateur ne peut pas supprimer un compte');
-- Sans policy DELETE, la suppression directe ne touche aucune ligne.
delete from public.profiles where id = '00000000-0000-0000-0000-00000000a104';
reset role;
select pg_temp.login('00000000-0000-0000-0000-00000000a102');
set local role authenticated;
delete from public.profiles where id = '00000000-0000-0000-0000-00000000a104';
reset role;
select is(
  (select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-00000000a104'),
  1, 'Plus aucune suppression directe de profil par l''API, même par un admin');

select pg_temp.login('00000000-0000-0000-0000-00000000a102');
set local role authenticated;
select lives_ok(
  $$select public.check_member_deletion('00000000-0000-0000-0000-00000000a104')$$,
  'Un admin peut supprimer un membre');
select throws_ok(
  $$select public.check_member_deletion('00000000-0000-0000-0000-00000000a105')$$,
  '42501', null, 'Un admin ne peut pas supprimer un autre admin');
select throws_ok(
  $$select public.check_member_deletion('00000000-0000-0000-0000-00000000a102')$$,
  '42501', null, 'Pas de suppression de son propre compte depuis l''administration');
select throws_ok(
  $$select public.check_member_deletion('00000000-0000-0000-0000-0000000000ff')$$,
  'P0002', null, 'Membre introuvable');
select throws_ok(
  $$select * from public.member_storage_objects('00000000-0000-0000-0000-00000000a104')$$,
  '42501', null, 'La liste des fichiers d''un membre est réservée au service role');
reset role;

select pg_temp.login('00000000-0000-0000-0000-00000000a101');
set local role authenticated;
select lives_ok(
  $$select public.check_member_deletion('00000000-0000-0000-0000-00000000a105')$$,
  'Un super_admin peut supprimer un admin');
reset role;

-- Suppression du compte : contenus collectifs conservés, aucune ligne orpheline -------------

insert into public.events (id, title, event_type, starts_at, created_by) values
  ('40000000-0000-0000-0000-000000000001', 'Conférence', 'conference', now(),
   '00000000-0000-0000-0000-00000000a104');
insert into public.announcements (id, title, content, author_id) values
  ('40000000-0000-0000-0000-000000000002', 'Annonce', 'Contenu',
   '00000000-0000-0000-0000-00000000a104');

-- Ce que fait l'Edge Function avec le service role (auth.admin.deleteUser).
delete from auth.users where id = '00000000-0000-0000-0000-00000000a104';

select is(
  (select count(*)::int from public.profiles where id = '00000000-0000-0000-0000-00000000a104'),
  0, 'Le profil est supprimé avec le compte');
select is(
  (select count(*)::int from public.events
    where id = '40000000-0000-0000-0000-000000000001' and created_by is null),
  1, 'L''événement est conservé, sans auteur');
select is(
  (select count(*)::int from public.announcements
    where id = '40000000-0000-0000-0000-000000000002' and author_id is null),
  1, 'L''annonce est conservée, sans auteur');

select * from finish();
rollback;
