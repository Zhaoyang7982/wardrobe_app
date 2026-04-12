-- 搭配「软删除」：列表中隐藏，仍保留行以供日历/详情展示
alter table public.outfits
  add column if not exists is_archived boolean not null default false;
