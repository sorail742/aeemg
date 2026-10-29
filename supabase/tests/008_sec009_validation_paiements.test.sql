-- SEC-009 : Réserver la validation des sessions de paiement au trésorier / service role.
-- Exécution : supabase test db
begin;
select plan(5);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000d001', 'donateur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000d002', 'moderateur@aeemg.test'),
  ('00000000-0000-0000-0000-00000000d003', 'tresorier@aeemg.test');

update public.profiles p set role = r.role::public.user_role
  from (values
    ('00000000-0000-0000-0000-00000000d001'::uuid, 'member'),
    ('00000000-0000-0000-0000-00000000d002'::uuid, 'moderator'),
    ('00000000-0000-0000-0000-00000000d003'::uuid, 'treasurer')
  ) as r(id, role)
 where p.id = r.id;

insert into public.payment_sessions (id, user_id, amount, phone, status, provider)
values
  ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000d001', 50000, '+224620000001', 'pending', 'orange_money'),
  ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-00000000d001', 25000, '+224620000002', 'pending', 'orange_money');

create function pg_temp.login(uid uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', uid, 'role', 'authenticated')::text, true);
$$;

-- 1. Le modérateur (is_staff = true, is_treasurer = false) tente de valider -> REFUS
select pg_temp.login('00000000-0000-0000-0000-00000000d002');
set local role authenticated;
update public.payment_sessions
   set status = 'completed'
 where id = '60000000-0000-0000-0000-000000000001';
select is(
  (select status::text from public.payment_sessions where id = '60000000-0000-0000-0000-000000000001'),
  'pending',
  'Un modérateur ne peut pas valider une session de paiement'
);
reset role;

-- 2. Le trésorier (is_treasurer = true) valide la session -> SUCCÈS
select pg_temp.login('00000000-0000-0000-0000-00000000d003');
set local role authenticated;
select lives_ok(
  $$update public.payment_sessions set status = 'completed' where id = '60000000-0000-0000-0000-000000000001'$$,
  'Le trésorier peut modifier une session de paiement'
);
select is(
  (select status::text from public.payment_sessions where id = '60000000-0000-0000-0000-000000000001'),
  'completed',
  'La session de paiement est bien validée par le trésorier'
);
reset role;

-- 3. Le webhook service role valide une session -> SUCCÈS
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
set local role service_role;
select lives_ok(
  $$update public.payment_sessions set status = 'completed' where id = '60000000-0000-0000-0000-000000000002'$$,
  'Le service_role peut modifier une session de paiement'
);
select is(
  (select status::text from public.payment_sessions where id = '60000000-0000-0000-0000-000000000002'),
  'completed',
  'La session de paiement est bien validée par le service_role'
);
reset role;

select * from finish();
rollback;
