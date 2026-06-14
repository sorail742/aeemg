-- Phase 5 - Reseau Social (Posts, Commentaires, Likes, Follows)

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  image_url text,
  likes_count int not null default 0,
  comments_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id != following_id)
);

-- Triggers pour updated_at
create trigger posts_updated_at
  before update on public.posts
  for each row execute function public.set_updated_at();

create trigger post_comments_updated_at
  before update on public.post_comments
  for each row execute function public.set_updated_at();

-- RLS
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.follows enable row level security;

-- Posts (Public pour tous les connectes)
create policy "Posts lisibles par tous les connectes"
  on public.posts for select
  using (auth.uid() is not null);

create policy "Creer un post"
  on public.posts for insert
  with check (auth.uid() = author_id);

create policy "Modifier son post"
  on public.posts for update
  using (auth.uid() = author_id);

create policy "Supprimer son post"
  on public.posts for delete
  using (auth.uid() = author_id or public.is_staff());

-- Post Likes
create policy "Likes lisibles"
  on public.post_likes for select
  using (auth.uid() is not null);

create policy "Liker"
  on public.post_likes for insert
  with check (auth.uid() = user_id);

create policy "Unliker"
  on public.post_likes for delete
  using (auth.uid() = user_id);

-- Post Comments
create policy "Commentaires lisibles"
  on public.post_comments for select
  using (auth.uid() is not null);

create policy "Commenter"
  on public.post_comments for insert
  with check (auth.uid() = author_id);

create policy "Modifier son commentaire"
  on public.post_comments for update
  using (auth.uid() = author_id);

create policy "Supprimer son commentaire"
  on public.post_comments for delete
  using (auth.uid() = author_id or public.is_staff());

-- Follows
create policy "Abonnements lisibles"
  on public.follows for select
  using (auth.uid() is not null);

create policy "S'abonner"
  on public.follows for insert
  with check (auth.uid() = follower_id);

create policy "Se desabonner"
  on public.follows for delete
  using (auth.uid() = follower_id);

-- Storage pour les images des posts
insert into storage.buckets (id, name, public) 
values ('social_images', 'social_images', true)
on conflict (id) do nothing;

create policy "Images publiques"
  on storage.objects for select
  using (bucket_id = 'social_images');

create policy "Utilisateurs uploadent images"
  on storage.objects for insert
  with check (bucket_id = 'social_images' and auth.uid() is not null);

create policy "Utilisateurs gerent leurs images"
  on storage.objects for delete
  using (bucket_id = 'social_images' and auth.uid() = owner);

-- Fonctions et Triggers pour incrementer les compteurs
create or replace function public.increment_post_likes()
returns trigger language plpgsql security definer as $$
begin
  update public.posts set likes_count = likes_count + 1 where id = new.post_id;
  return new;
end;
$$;

create trigger on_post_like_insert
  after insert on public.post_likes
  for each row execute function public.increment_post_likes();

create or replace function public.decrement_post_likes()
returns trigger language plpgsql security definer as $$
begin
  update public.posts set likes_count = greatest(likes_count - 1, 0) where id = old.post_id;
  return old;
end;
$$;

create trigger on_post_like_delete
  after delete on public.post_likes
  for each row execute function public.decrement_post_likes();

create or replace function public.increment_post_comments()
returns trigger language plpgsql security definer as $$
begin
  update public.posts set comments_count = comments_count + 1 where id = new.post_id;
  return new;
end;
$$;

create trigger on_post_comment_insert
  after insert on public.post_comments
  for each row execute function public.increment_post_comments();

create or replace function public.decrement_post_comments()
returns trigger language plpgsql security definer as $$
begin
  update public.posts set comments_count = greatest(comments_count - 1, 0) where id = old.post_id;
  return old;
end;
$$;

create trigger on_post_comment_delete
  after delete on public.post_comments
  for each row execute function public.decrement_post_comments();

-- Ajout d'un compte de followers dans public.profiles (optionnel mais utile)
alter table public.profiles add column if not exists followers_count int not null default 0;
alter table public.profiles add column if not exists following_count int not null default 0;

create or replace function public.increment_follows()
returns trigger language plpgsql security definer as $$
begin
  update public.profiles set following_count = following_count + 1 where id = new.follower_id;
  update public.profiles set followers_count = followers_count + 1 where id = new.following_id;
  return new;
end;
$$;

create trigger on_follow_insert
  after insert on public.follows
  for each row execute function public.increment_follows();

create or replace function public.decrement_follows()
returns trigger language plpgsql security definer as $$
begin
  update public.profiles set following_count = greatest(following_count - 1, 0) where id = old.follower_id;
  update public.profiles set followers_count = greatest(followers_count - 1, 0) where id = old.following_id;
  return old;
end;
$$;

create trigger on_follow_delete
  after delete on public.follows
  for each row execute function public.decrement_follows();
