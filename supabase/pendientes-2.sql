update products set price = 9000 where category_id = 'salsas' and price = 10000;
alter table products alter column low_stock_at set default 2;
update products set low_stock_at = 2 where low_stock_at = 3;
