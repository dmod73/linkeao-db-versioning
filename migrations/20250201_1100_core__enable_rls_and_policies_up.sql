alter table if exists tenants enable row level security;
alter table if exists tenant_domains enable row level security;
alter table if exists tenant_modules enable row level security;
alter table if exists users enable row level security;
alter table if exists user_tenants enable row level security;

create or replace function app_tenant_id() returns uuid language sql as 
  select nullif(current_setting('app.tenant_id', true),'')::uuid
;

drop policy if exists tenants_select on tenants;
create policy tenants_select on tenants
for select using ( id = app_tenant_id() );

drop policy if exists tenant_domains_rw on tenant_domains;
create policy tenant_domains_rw on tenant_domains
for all using ( tenant_id = app_tenant_id() )
with check ( tenant_id = app_tenant_id() );

drop policy if exists tenant_modules_rw on tenant_modules;
create policy tenant_modules_rw on tenant_modules
for all using ( tenant_id = app_tenant_id() )
with check ( tenant_id = app_tenant_id() );

drop policy if exists users_ro on users;
create policy users_ro on users
for select using ( exists (
  select 1 from user_tenants ut
  where ut.user_id = users.id and ut.tenant_id = app_tenant_id()
));

drop policy if exists user_tenants_rw on user_tenants;
create policy user_tenants_rw on user_tenants
for all using ( tenant_id = app_tenant_id() )
with check ( tenant_id = app_tenant_id() );

insert into tenants (name, slug, primary_domain)
values ('Demo Coaching', 'demo-coach', 'demo.localhost')
on conflict do nothing;

insert into tenant_domains (tenant_id, domain, verified_at, is_primary)
select id, 'demo.localhost', now(), true from tenants where slug='demo-coach'
on conflict do nothing;
