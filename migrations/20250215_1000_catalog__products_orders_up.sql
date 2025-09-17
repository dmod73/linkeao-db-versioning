-- Productos
create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  tenant_slug text not null,
  name text not null,
  price_cents integer not null check (price_cents >= 0),
  currency text not null default 'USD',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

-- Pedidos (simplificado)
create table if not exists orders (
  id uuid primary key default gen_random_uuid(),
  tenant_slug text not null,
  status text not null default 'draft',
  total_cents integer not null default 0,
  currency text not null default 'USD',
  customer_email text,
  created_at timestamptz not null default now()
);

create table if not exists order_items (
  order_id uuid not null references orders(id) on delete cascade,
  product_id uuid not null references products(id),
  qty integer not null default 1,
  price_cents integer not null,
  primary key (order_id, product_id)
);

-- Outbox emails (para prueba)
create table if not exists outbox_emails (
  id bigserial primary key,
  tenant_slug text not null,
  to_email text not null,
  subject text not null,
  body_txt text not null,
  body_html text,
  created_at timestamptz not null default now()
);

-- RLS (asume app_tenant_id()/app.tenant_slug)
alter table products enable row level security;
alter table orders   enable row level security;
alter table order_items enable row level security;
alter table outbox_emails enable row level security;

drop policy if exists p_products_tenant on products;
create policy p_products_tenant on products
  using (tenant_slug = current_setting('app.tenant_slug', true));

drop policy if exists p_orders_tenant on orders;
create policy p_orders_tenant on orders
  using (tenant_slug = current_setting('app.tenant_slug', true));

drop policy if exists p_order_items_tenant on order_items;
create policy p_order_items_tenant on order_items
  using (
    exists (
      select 1
      from orders o
      where o.id = order_id
        and o.tenant_slug = current_setting('app.tenant_slug', true)
    )
  );

drop policy if exists p_outbox_tenant on outbox_emails;
create policy p_outbox_tenant on outbox_emails
  using (tenant_slug = current_setting('app.tenant_slug', true));

-- RPC para crear draft de pedido
create or replace function create_order_draft(p_tenant text, p_items jsonb)
returns jsonb
language plpgsql
as $$
declare
  v_order orders%rowtype;
  v_item jsonb;
  v_pid uuid;
  v_qty int;
  v_price int;
  v_total int := 0;
begin
  insert into orders(tenant_slug,status)
    values (p_tenant,'draft')
    returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_pid  := coalesce((v_item->>'productId')::uuid, gen_random_uuid());
    v_qty  := coalesce((v_item->>'qty')::int,1);
    select price_cents into v_price from products where id = v_pid and tenant_slug = p_tenant;
    if v_price is null then
      raise exception 'product % not found for tenant %', v_pid, p_tenant;
    end if;
    insert into order_items(order_id, product_id, qty, price_cents)
      values (v_order.id, v_pid, v_qty, v_price);
    v_total := v_total + v_price * v_qty;
  end loop;

  update orders set total_cents = v_total where id = v_order.id;
  return to_jsonb((select o from (
    select v_order.id as id,
           v_order.tenant_slug as tenant,
           v_order.status,
           v_total as total_cents,
           v_order.currency,
           v_order.created_at as created_at
  ) o));
end;
$$;

-- Seed demo (idempotente)
insert into products (tenant_slug, name, price_cents, currency, active)
  values
  ('demo-coach','Curso Básico',4900,'USD',true),
  ('demo-coach','Avanzado',9900,'USD',true),
  ('demo-store','T-Shirt',2500,'USD',true),
  ('demo-store','Pants',5000,'USD',true)
on conflict do nothing;