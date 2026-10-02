alter table orders add column if not exists subtotal int;
alter table orders add column if not exists discount_pct int not null default 0;
update orders set subtotal = total where subtotal is null;

create or replace function place_order(p_items jsonb, p_note text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  it jsonb; p products%rowtype; q int;
  problems jsonb := '[]'; sub int := 0; pct int := 0; tot int; oid bigint; nm text;
begin
  nm := nullif(left(btrim(coalesce(p_note, '')), 80), '');

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
      sub := sub + p.price * q;
    end if;
  end loop;

  if jsonb_array_length(problems) > 0 then
    return jsonb_build_object('ok', false, 'problems', problems);
  end if;

  if nm ~* '^\s*mayorista(\W|$)' then pct := 20; end if;
  tot := round(sub * (100 - pct) / 100.0);

  insert into orders(subtotal, discount_pct, total, note) values (sub, pct, tot, nm) returning id into oid;
  for it in select * from jsonb_array_elements(p_items) loop
    q := (it->>'qty')::int;
    select * into p from products where id = (it->>'product_id')::bigint;
    insert into order_items(order_id, product_id, name, qty, unit_price) values (oid, p.id, p.name, q, p.price);
    if p.stock is not null then update products set stock = stock - q where id = p.id; end if;
  end loop;

  return jsonb_build_object('ok', true, 'order_id', oid, 'total', tot, 'subtotal', sub, 'discount_pct', pct);
end $$;
grant execute on function place_order(jsonb, text) to anon, authenticated;
