-- SEC-008 : statut des dons et sessions de paiement.
-- Exécution : supabase test db
begin;
select plan(15);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000f001', 'donateur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000f002', 'autre@aeemg.test'),
  ('00000000-0000-0000-0000-00000000f003', 'tresorier@aeemg.test');
update public.profiles set role = 'treasurer' where id = '00000000-0000-0000-0000-00000000f003';

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- Le donateur.
select pg_temp.login('00000000-0000-0000-0000-00000000f001');
set local role authenticated;
select lives_ok(
  $$insert into public.donations (id, user_id, amount, status, payment_method)
    values ('50000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000f001',
            10000, 'pending', 'orange_money')$$,
  'Un membre crée un don en attente (flux de l''app)');
select throws_ok(
  $$insert into public.donations (user_id, amount, status, payment_method)
    values ('00000000-0000-0000-0000-00000000f001', 10000, 'completed', 'orange_money')$$,
  '42501', null, 'Un membre ne peut pas créer un don déjà confirmé');
update public.donations set status = 'completed'
 where id = '50000000-0000-0000-0000-000000000001';
select is(
  (select status::text from public.donations where id = '50000000-0000-0000-0000-000000000001'),
  'pending', 'Un membre ne peut pas confirmer son propre don');
select throws_ok(
  $$insert into public.payment_sessions (user_id, amount, phone, status)
    values ('00000000-0000-0000-0000-00000000f001', 10000, '+224620000000', 'completed')$$,
  '42501', null, 'Un membre ne peut pas créer de session de paiement');
-- Don en espèces déclaré par le membre, à valider par le trésorier.
insert into public.donations (id, user_id, amount, status, payment_method)
values ('50000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000f001',
        5000, 'pending', 'cash');
select is(
  (select count(*)::int from public.donation_status_history
    where donation_id = '50000000-0000-0000-0000-000000000001'),
  1, 'Le donateur voit l''historique de son don');
reset role;

-- Un autre membre.
select pg_temp.login('00000000-0000-0000-0000-00000000f002');
set local role authenticated;
select is(
  (select count(*)::int from public.donation_status_history), 0,
  'Un autre membre ne voit pas l''historique des dons');
reset role;

-- Le trésorier.
select pg_temp.login('00000000-0000-0000-0000-00000000f003');
set local role authenticated;
update public.donations set status = 'completed'
 where id = '50000000-0000-0000-0000-000000000001';
select is(
  (select status::text from public.donations where id = '50000000-0000-0000-0000-000000000001'),
  'pending', 'Le trésorier ne confirme pas un don mobile money (réservé au webhook)');
select lives_ok(
  $$update public.donations set status = 'completed'
     where id = '50000000-0000-0000-0000-000000000002'$$,
  'Le trésorier confirme un don en espèces');
select is(
  (select status::text from public.donations where id = '50000000-0000-0000-0000-000000000002'),
  'completed', 'Le don en espèces est confirmé');
select is(
  (select changed_by from public.donation_status_history
    where donation_id = '50000000-0000-0000-0000-000000000002' and new_status = 'completed'),
  '00000000-0000-0000-0000-00000000f003'::uuid,
  'L''historique enregistre qui a confirmé le don');
select throws_ok(
  $$update public.donations set status = 'pending'
     where id = '50000000-0000-0000-0000-000000000002'$$,
  '42501', null, 'Un don confirmé ne revient pas en attente');
select lives_ok(
  $$insert into public.donations (user_id, amount, status, payment_method)
    values ('00000000-0000-0000-0000-00000000f001', 2000, 'pending', 'cash')$$,
  'Le trésorier enregistre un don en espèces pour un membre');
select throws_ok(
  $$update public.donations set amount = 1
     where id = '50000000-0000-0000-0000-000000000002'$$,
  '42501', null, 'Le montant d''un don ne peut pas être modifié');
reset role;

-- Le webhook de paiement (service role) confirme le don mobile money.
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
set local role service_role;
update public.donations set status = 'completed'
 where id = '50000000-0000-0000-0000-000000000001';
reset role;
select is(
  (select status::text from public.donations where id = '50000000-0000-0000-0000-000000000001'),
  'completed', 'Le service role confirme un don mobile money');
select is(
  (select changed_via from public.donation_status_history
    where donation_id = '50000000-0000-0000-0000-000000000001' and new_status = 'completed'),
  'service_role', 'L''historique indique une confirmation par le service role');

select * from finish();
rollback;
