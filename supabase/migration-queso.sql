insert into categories (id, title, note, sort, shape, kind)
select 'queso-rallado', 'Queso Rallado', '100grs', coalesce(max(sort), 0) + 1, 'strand', 'menu'
from categories where kind = 'menu'
on conflict (id) do nothing;

update products
set category_id = 'queso-rallado', name = 'Parmesano en hebras',
    description = 'Queso parmesano rallado en hebras, 100grs', shape = null, sort = 0
where category_id = 'salsas' and name like 'Queso Rallado%';
