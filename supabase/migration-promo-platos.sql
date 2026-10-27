alter table products add column if not exists promo_pct int;
alter table products add column if not exists promo_until timestamptz;

create or replace function effective_price(pid bigint) returns int
language sql stable security definer set search_path = public as $$
  select case when d.pct > 0 then round(p.price * (100 - d.pct) / 100.0)::int else p.price end
  from products p
  join categories c on c.id = p.category_id
  cross join lateral (
    select greatest(
      case when c.promo_pct > 0 and c.promo_until > now() then c.promo_pct else 0 end,
      case when p.promo_pct > 0 and p.promo_until > now() then p.promo_pct else 0 end
    ) as pct
  ) d
  where p.id = pid
$$;
