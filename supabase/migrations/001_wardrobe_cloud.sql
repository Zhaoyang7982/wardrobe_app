-- 在 Supabase SQL Editor 中执行（或 CLI link 后 migrate）
-- 前置：Authentication → Providers 中启用「Anonymous（匿名）」登录，否则客户端无法匿名建号。

-- 衣物表
create table if not exists public.clothes (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  category text not null,
  colors jsonb not null default '[]'::jsonb,
  brand text,
  size text,
  image_public_url text,
  cropped_image_public_url text,
  tags jsonb not null default '[]'::jsonb,
  season text,
  occasion text,
  style text,
  purchase_date timestamptz,
  purchase_price double precision,
  status text not null default '在穿',
  usage_count int not null default 0,
  last_worn_date timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists clothes_user_id_created_at_idx
  on public.clothes (user_id, created_at desc);

-- 搭配表
create table if not exists public.outfits (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  clothing_ids text[] not null default '{}',
  scene text,
  occasion text,
  season text,
  cover_image_url text,
  worn_dates timestamptz[] not null default '{}',
  planned_dates timestamptz[] not null default '{}',
  notes text,
  is_shared boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists outfits_user_id_created_at_idx
  on public.outfits (user_id, created_at desc);

-- RLS
alter table public.clothes enable row level security;
alter table public.outfits enable row level security;

drop policy if exists "clothes_select_own" on public.clothes;
drop policy if exists "clothes_insert_own" on public.clothes;
drop policy if exists "clothes_update_own" on public.clothes;
drop policy if exists "clothes_delete_own" on public.clothes;
drop policy if exists "outfits_select_own" on public.outfits;
drop policy if exists "outfits_insert_own" on public.outfits;
drop policy if exists "outfits_update_own" on public.outfits;
drop policy if exists "outfits_delete_own" on public.outfits;

create policy "clothes_select_own" on public.clothes
  for select using (auth.uid() = user_id);
create policy "clothes_insert_own" on public.clothes
  for insert with check (auth.uid() = user_id);
create policy "clothes_update_own" on public.clothes
  for update using (auth.uid() = user_id);
create policy "clothes_delete_own" on public.clothes
  for delete using (auth.uid() = user_id);

create policy "outfits_select_own" on public.outfits
  for select using (auth.uid() = user_id);
create policy "outfits_insert_own" on public.outfits
  for insert with check (auth.uid() = user_id);
create policy "outfits_update_own" on public.outfits
  for update using (auth.uid() = user_id);
create policy "outfits_delete_own" on public.outfits
  for delete using (auth.uid() = user_id);

-- Storage：新建 bucket 名 wardrobe，在 Dashboard → Storage 中设为 public（便于 getPublicUrl 直链展示）
-- 以下为宽松策略（仅登录用户可读写该 bucket）；上线可收紧为「路径首段 = auth.uid()」

insert into storage.buckets (id, name, public)
values ('wardrobe', 'wardrobe', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "wardrobe_read" on storage.objects;
drop policy if exists "wardrobe_insert" on storage.objects;
drop policy if exists "wardrobe_update" on storage.objects;
drop policy if exists "wardrobe_delete" on storage.objects;

create policy "wardrobe_read" on storage.objects
  for select using (bucket_id = 'wardrobe');
create policy "wardrobe_insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'wardrobe');
create policy "wardrobe_update" on storage.objects
  for update to authenticated using (bucket_id = 'wardrobe');
create policy "wardrobe_delete" on storage.objects
  for delete to authenticated using (bucket_id = 'wardrobe');
