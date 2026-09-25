-- Franca Pastas: esquema base. Correr completo en Supabase > SQL Editor.

create table if not exists admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as
$$ select exists (select 1 from admins where user_id = auth.uid()) $$;

create table if not exists categories (
  id text primary key,
  title text not null,
  note text,
  sort int not null default 0
);

create table if not exists products (
  id bigint generated always as identity primary key,
  category_id text not null references categories(id),
  name text not null,
  description text,
  price int not null check (price >= 0),
  photo_url text,
  sort int not null default 0,
  active boolean not null default true,
  stock int check (stock is null or stock >= 0),          -- null = sin límite
  max_per_order int check (max_per_order is null or max_per_order > 0),
  low_stock_at int default 3                               -- muestra "¡Últimas!" si stock <= este valor
);

create table if not exists orders (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  status text not null default 'nuevo' check (status in ('nuevo','confirmado','cancelado')),
  total int not null,
  note text
);

create table if not exists order_items (
  id bigint generated always as identity primary key,
  order_id bigint not null references orders(id) on delete cascade,
  product_id bigint references products(id) on delete set null,
  name text not null,
  qty int not null check (qty > 0),
  unit_price int not null
);

alter table admins enable row level security;
alter table categories enable row level security;
alter table products enable row level security;
alter table orders enable row level security;
alter table order_items enable row level security;

create policy "catalogo publico" on categories for select using (true);
create policy "catalogo admin" on categories for all using (is_admin()) with check (is_admin());
create policy "productos publicos" on products for select using (active or is_admin());
create policy "productos admin" on products for all using (is_admin()) with check (is_admin());
create policy "pedidos admin" on orders for all using (is_admin()) with check (is_admin());
create policy "items admin" on order_items for all using (is_admin()) with check (is_admin());
-- Los clientes NO insertan directo: solo vía place_order().

-- Crea un pedido y descuenta stock de forma atómica.
-- p_items: [{"product_id":1,"qty":2}, ...]
-- Devuelve {ok:true, order_id, total} o {ok:false, problems:[{product_id,name,reason,available}]}
create or replace function place_order(p_items jsonb, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  it jsonb; p products%rowtype; q int;
  problems jsonb := '[]'; total int := 0; oid bigint;
begin
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    return jsonb_build_object('ok', false, 'problems', jsonb_build_array(jsonb_build_object('reason','vacio')));
  end if;

  for it in select * from jsonb_array_elements(p_items) loop
    q := (it->>'qty')::int;
    select * into p from products where id = (it->>'product_id')::bigint and active for update;
    if not found or q is null or q < 1 then
      problems := problems || jsonb_build_object('product_id', it->>'product_id', 'reason', 'no_disponible');
    elsif p.max_per_order is not null and q > p.max_per_order then
      problems := problems || jsonb_build_object('product_id', p.id, 'name', p.name, 'reason', 'max_por_pedido', 'available', p.max_per_order);
    elsif p.stock is not null and q > p.stock then
      problems := problems || jsonb_build_object('product_id', p.id, 'name', p.name, 'reason', 'sin_stock', 'available', p.stock);
    else
      total := total + p.price * q;
    end if;
  end loop;

  if jsonb_array_length(problems) > 0 then
    return jsonb_build_object('ok', false, 'problems', problems);
  end if;

  insert into orders(total, note) values (total, p_note) returning id into oid;
  for it in select * from jsonb_array_elements(p_items) loop
    q := (it->>'qty')::int;
    select * into p from products where id = (it->>'product_id')::bigint;
    insert into order_items(order_id, product_id, name, qty, unit_price) values (oid, p.id, p.name, q, p.price);
    if p.stock is not null then update products set stock = stock - q where id = p.id; end if;
  end loop;

  return jsonb_build_object('ok', true, 'order_id', oid, 'total', total);
end $$;
grant execute on function place_order(jsonb, text) to anon, authenticated;

-- Cambia estado; al cancelar devuelve el stock (una sola vez).
create or replace function set_order_status(p_order bigint, p_status text)
returns void language plpgsql security definer set search_path = public as $$
declare old text; r record;
begin
  if not is_admin() then raise exception 'no autorizado'; end if;
  select status into old from orders where id = p_order for update;
  if p_status = 'cancelado' and old <> 'cancelado' then
    for r in select product_id, qty from order_items where order_id = p_order loop
      update products set stock = stock + r.qty where id = r.product_id and stock is not null;
    end loop;
  elsif old = 'cancelado' and p_status <> 'cancelado' then
    for r in select product_id, qty from order_items where order_id = p_order loop
      update products set stock = greatest(stock - r.qty, 0) where id = r.product_id and stock is not null;
    end loop;
  end if;
  update orders set status = p_status where id = p_order;
end $$;
grant execute on function set_order_status(bigint, text) to authenticated;

-- Estadísticas (solo admin, por security invoker + RLS de orders).
create or replace view stats_daily with (security_invoker = true) as
  select date_trunc('day', created_at at time zone 'America/Argentina/Buenos_Aires')::date as dia,
         count(*) as pedidos, sum(total) as ventas
  from orders where status <> 'cancelado' group by 1 order by 1 desc;

create or replace view stats_products with (security_invoker = true) as
  select oi.name, sum(oi.qty) as unidades, sum(oi.qty * oi.unit_price) as ventas
  from order_items oi join orders o on o.id = oi.order_id
  where o.status <> 'cancelado' group by oi.name order by unidades desc;
