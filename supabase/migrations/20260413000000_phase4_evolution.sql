-- Phase 4 — Évolution : paiements, SMS, préférences langue

create type public.payment_provider as enum ('orange_money', 'mtn_momo');
create type public.payment_status as enum ('initiated', 'pending', 'completed', 'failed', 'cancelled');

create table if not exists public.payment_sessions (
  id uuid primary key default gen_random_uuid(),
  donation_id uuid references public.donations (id) on delete set null,
  user_id uuid references public.profiles (id) on delete set null,
  provider public.payment_provider not null default 'orange_money',
  amount numeric(12, 2) not null check (amount > 0),
  phone text not null,
  external_ref text,
  status public.payment_status not null default 'initiated',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.sms_notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  phone text not null,
  message text not null,
  status text not null default 'queued' check (status in ('queued', 'sent', 'failed')),
  created_at timestamptz not null default now()
);

alter table public.notification_preferences
  add column if not exists sms_fallback_enabled boolean not null default false;

alter table public.profiles
  add column if not exists preferred_locale text not null default 'fr'
    check (preferred_locale in ('fr', 'ff'));

alter table public.payment_sessions enable row level security;
alter table public.sms_notifications enable row level security;

create policy "Ses sessions paiement"
  on public.payment_sessions for select
  using (user_id = auth.uid() or public.is_staff());

create policy "Creer session paiement"
  on public.payment_sessions for insert
  with check (auth.uid() = user_id);

create policy "Staff gere paiements"
  on public.payment_sessions for update
  using (public.is_staff());

create policy "Ses SMS"
  on public.sms_notifications for select
  using (user_id = auth.uid() or public.is_staff());

create policy "Staff envoie SMS"
  on public.sms_notifications for insert
  with check (public.is_staff());
