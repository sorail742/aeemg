-- Auth email : profil + table feedback (Phase 3 beta)

-- Profil : enregistrer l'email à l'inscription
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', 'Nouveau membre'),
    coalesce(new.phone, new.email)
  );
  return new;
end;
$$;

-- Retours beta (Phase 3)
create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles (id) on delete set null,
  message text not null,
  rating int check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

alter table public.feedback enable row level security;

create policy "Envoyer un retour"
  on public.feedback for insert
  with check (auth.uid() = user_id or user_id is null);

create policy "Staff lit les retours"
  on public.feedback for select
  using (public.is_staff());
