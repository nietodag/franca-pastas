alter table products add column if not exists featured boolean not null default false;
update products set featured = true where name = 'Seso & Verdura' and not exists (select 1 from products where featured);
