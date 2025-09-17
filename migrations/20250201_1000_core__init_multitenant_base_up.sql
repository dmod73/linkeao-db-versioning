create extension if not exists pgcrypto;

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  primary_domain text,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists tenant_domains (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  domain text unique not null,
  verified_at timestamptz,
  is_primary boolean default false
);

create table if not exists tenant_modules (
  tenant_id uuid not null references tenants(id) on delete cascade,
  module text not null,
  enabled boolean default false,
  plan_tier text,
  primary key (tenant_id, module)
);

create table if not exists users (
  id uuid primary key,
  email text unique not null,
  created_at timestamptz default now()
);

create table if not exists user_tenants (
  user_id uuid not null references users(id) on delete cascade,
  tenant_id uuid not null references tenants(id) on delete cascade,
  role text not null,
  primary key (user_id, tenant_id)
);

create index if not exists idx_tenant_domains_tenant on tenant_domains(tenant_id);
create index if not exists idx_user_tenants_role on user_tenants(role);
