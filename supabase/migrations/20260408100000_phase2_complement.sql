-- Phase 2 — Finances, Dons, Mosquée, Rappels

create type public.transaction_type as enum ('income', 'expense');
create type public.donation_category as enum (
  'general', 'ramadan_iftar', 'mosque_renovation', 'emergency'
);
create type public.donation_status as enum ('pending', 'completed', 'failed');
create type public.mosque_need_status as enum ('open', 'fulfilled', 'cancelled');

-- Finances
create table public.finance_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  type public.transaction_type not null,
  amount numeric(12, 2) not null check (amount > 0),
  category_id uuid references public.finance_categories (id),
  description text,
  recorded_by uuid references public.profiles (id),
  transaction_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table public.monthly_reports (
  id uuid primary key default gen_random_uuid(),
  year int not null,
  month int not null check (month between 1 and 12),
  total_income numeric(12, 2) not null default 0,
  total_expense numeric(12, 2) not null default 0,
  is_published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  unique (year, month)
);

-- Dons
create table public.donation_campaigns (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  category public.donation_category not null default 'general',
  goal_amount numeric(12, 2) not null,
  raised_amount numeric(12, 2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.donations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id),
  campaign_id uuid references public.donation_campaigns (id),
  amount numeric(12, 2) not null check (amount > 0),
  category public.donation_category not null default 'general',
  is_anonymous boolean not null default false,
  status public.donation_status not null default 'pending',
  payment_method text,
  created_at timestamptz not null default now()
);

-- Mosquée
create table public.mosque_needs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  quantity_needed int not null default 1,
  quantity_fulfilled int not null default 0,
  status public.mosque_need_status not null default 'open',
  created_at timestamptz not null default now()
);

create table public.volunteer_signups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  mission text not null,
  event_date date,
  notes text,
  created_at timestamptz not null default now()
);

create table public.islamic_favorites (
  user_id uuid not null references public.profiles (id) on delete cascade,
  content_id uuid not null references public.islamic_contents (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, content_id)
);

-- RLS
alter table public.finance_categories enable row level security;
alter table public.transactions enable row level security;
alter table public.monthly_reports enable row level security;
alter table public.donation_campaigns enable row level security;
alter table public.donations enable row level security;
alter table public.mosque_needs enable row level security;
alter table public.volunteer_signups enable row level security;
alter table public.islamic_favorites enable row level security;

create or replace function public.is_treasurer()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role in ('super_admin', 'admin', 'treasurer')
  );
$$;

-- finance_categories
create policy "Catégories lisibles"
  on public.finance_categories for select using (auth.uid() is not null);

-- transactions
create policy "Trésorier gère les transactions"
  on public.transactions for all
  using (public.is_treasurer())
  with check (public.is_treasurer());

-- monthly_reports
create policy "Bilans publiés lisibles"
  on public.monthly_reports for select
  using (is_published or public.is_treasurer());

create policy "Trésorier gère les bilans"
  on public.monthly_reports for all
  using (public.is_treasurer())
  with check (public.is_treasurer());

-- donation_campaigns
create policy "Campagnes visibles"
  on public.donation_campaigns for select using (true);

create policy "Staff gère les campagnes"
  on public.donation_campaigns for all
  using (public.is_staff())
  with check (public.is_staff());

-- donations
create policy "Ses dons ou staff"
  on public.donations for select
  using (user_id = auth.uid() or public.is_staff());

create policy "Créer un don"
  on public.donations for insert
  with check (auth.uid() = user_id);

-- mosque_needs
create policy "Besoins mosquée visibles"
  on public.mosque_needs for select using (true);

create policy "Staff gère les besoins"
  on public.mosque_needs for all
  using (public.is_staff())
  with check (public.is_staff());

-- volunteer_signups
create policy "Inscriptions visibles staff ou soi"
  on public.volunteer_signups for select
  using (user_id = auth.uid() or public.is_staff());

create policy "S'inscrire bénévole"
  on public.volunteer_signups for insert
  with check (auth.uid() = user_id);

-- islamic_favorites
create policy "Ses favoris"
  on public.islamic_favorites for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Données initiales
insert into public.finance_categories (name) values
  ('Activités'), ('Mosquée'), ('Fournitures'), ('Iftar'), ('Autres');

insert into public.donation_campaigns (title, description, category, goal_amount)
values (
  'Fonds Ramadan 2026',
  'Soutenez les iftars communautaires de l''AEEMG.',
  'ramadan_iftar',
  50000000
);

insert into public.mosque_needs (title, description, quantity_needed)
values
  ('Tapis de prière', 'Renouvellement des tapis de la salle principale', 20),
  ('Bouteilles d''eau', 'Pour les fidèles lors du vendredi', 100);
