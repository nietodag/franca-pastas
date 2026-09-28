alter table products add column if not exists day29 boolean not null default false;
update products set day29 = true where name = 'Ñoquis de Papa' and category_id = 'noquis' and not exists (select 1 from products where day29);
