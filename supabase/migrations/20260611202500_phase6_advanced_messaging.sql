-- Phase 6 — Messagerie Avancée Type WhatsApp

-- 1. Adapter la table chat_groups pour supporter le 1-à-1
alter table public.chat_groups alter column name drop not null;
alter table public.chat_groups add column is_group boolean not null default true;

-- 2. Adapter la table messages pour les médias et citations
alter table public.messages add column message_type text not null default 'text' check (message_type in ('text', 'image', 'audio'));
alter table public.messages add column media_url text;
alter table public.messages add column reply_to_id uuid references public.messages(id);
alter table public.messages add column is_deleted boolean not null default false;

-- 3. Créer la table des accusés de réception
create table public.message_receipts (
  message_id uuid not null references public.messages (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null check (status in ('delivered', 'read')),
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

-- RLS pour message_receipts
alter table public.message_receipts enable row level security;

create policy "Accusés lisibles par les participants du groupe"
  on public.message_receipts for select
  using (
    exists (
      select 1 from public.chat_group_members m
      join public.messages msg on msg.group_id = m.group_id
      where msg.id = message_receipts.message_id and m.user_id = auth.uid()
    )
  );

create policy "Créer un accusé"
  on public.message_receipts for insert
  with check (auth.uid() = user_id);

create policy "Modifier un accusé"
  on public.message_receipts for update
  using (auth.uid() = user_id);

-- 4. Ajouter les buckets de stockage pour les médias
insert into storage.buckets (id, name, public) values ('chat_images', 'chat_images', true)
on conflict (id) do nothing;
insert into storage.buckets (id, name, public) values ('chat_audio', 'chat_audio', true)
on conflict (id) do nothing;

create policy "Images de chat lisibles"
  on storage.objects for select
  using ( bucket_id = 'chat_images' );

create policy "Images de chat insérables"
  on storage.objects for insert
  with check ( bucket_id = 'chat_images' and auth.uid() is not null );

create policy "Audio de chat lisibles"
  on storage.objects for select
  using ( bucket_id = 'chat_audio' );

create policy "Audio de chat insérables"
  on storage.objects for insert
  with check ( bucket_id = 'chat_audio' and auth.uid() is not null );

-- 5. Realtime pour les accusés
do $$ begin
  alter publication supabase_realtime add table public.message_receipts;
exception when duplicate_object then null; end $$;
