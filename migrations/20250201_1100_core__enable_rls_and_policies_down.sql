drop policy if exists tenants_select on tenants;
drop policy if exists tenant_domains_rw on tenant_domains;
drop policy if exists tenant_modules_rw on tenant_modules;
drop policy if exists users_ro on users;
drop policy if exists user_tenants_rw on user_tenants;

alter table if exists tenants disable row level security;
alter table if exists tenant_domains disable row level security;
alter table if exists tenant_modules disable row level security;
alter table if exists users disable row level security;
alter table if exists user_tenants disable row level security;

drop function if exists app_tenant_id();

delete from tenant_domains where domain='demo.localhost';
delete from tenants where slug='demo-coach';
