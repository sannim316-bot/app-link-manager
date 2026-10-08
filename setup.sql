-- Run once in the Supabase SQL Editor, preferably in a dedicated project.
create table public.link_admins (user_id uuid primary key references auth.users(id) on delete cascade);
alter table public.link_admins enable row level security;
revoke all on public.link_admins from anon, authenticated;
create function public.is_link_admin() returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.link_admins where user_id = (select auth.uid())); $$;
revoke all on function public.is_link_admin() from public;
grant execute on function public.is_link_admin() to authenticated;
create table public.app_links (
 app_id text primary key check(app_id ~ '^[a-z0-9-]{1,64}$'),
 name text not null check(length(name) between 1 and 100),
 links jsonb not null,
 revision integer not null default 1,
 updated_at timestamptz not null default now(),
 constraint valid_links check (
   jsonb_typeof(links) = 'object' and
   links ?& array['telegram','whatsapp','website','email','phone'] and
   jsonb_typeof(links->'telegram')='string' and
   jsonb_typeof(links->'whatsapp')='string' and
   jsonb_typeof(links->'website')='string' and
   jsonb_typeof(links->'email')='string' and
   jsonb_typeof(links->'phone')='string' and
   (links->>'telegram' = '' or links->>'telegram' ~ '^https://[^[:space:]]+$') and
   (links->>'whatsapp' = '' or links->>'whatsapp' ~ '^https://[^[:space:]]+$') and
   (links->>'website' = '' or links->>'website' ~ '^https://[^[:space:]]+$') and
   length(links::text) < 10000
 )
);
alter table public.app_links enable row level security;
revoke all on public.app_links from anon, authenticated;
grant select on public.app_links to anon, authenticated;
grant insert,update on public.app_links to authenticated;
create policy public_read on public.app_links for select to anon,authenticated using (true);
create policy admin_insert on public.app_links for insert to authenticated with check((select public.is_link_admin()));
create policy admin_update on public.app_links for update to authenticated using((select public.is_link_admin())) with check((select public.is_link_admin()));
create function public.touch_app_links() returns trigger language plpgsql set search_path='' as $$
begin
 if TG_OP='UPDATE' then NEW.revision := OLD.revision+1; else NEW.revision := 1; end if;
 NEW.updated_at := now(); return NEW;
end; $$;
create trigger touch_links before insert or update on public.app_links for each row execute function public.touch_app_links();
insert into public.app_links(app_id,name,links) values('lagos-life','Lagos Life',
 '{"telegram":"https://esw1uj.s.gy/lagoslife","whatsapp":"","website":"","email":"Jaytechxlab@gmail.com","phone":"07040683556"}');
-- After creating your admin user under Authentication > Users:
-- insert into public.link_admins(user_id) values('YOUR-AUTH-USER-UUID');
