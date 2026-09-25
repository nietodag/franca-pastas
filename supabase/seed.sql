-- Franca Pastas: migración + carga inicial del catálogo. Correr completo en SQL Editor (una sola vez).
alter table categories add column if not exists shape text, add column if not exists kind text not null default 'menu';
alter table products add column if not exists color text, add column if not exists badge text, add column if not exists shape text;

insert into storage.buckets (id, name, public) values ('product-photos','product-photos',true) on conflict (id) do nothing;
drop policy if exists "fotos publicas" on storage.objects;
drop policy if exists "fotos admin" on storage.objects;
create policy "fotos publicas" on storage.objects for select using (bucket_id = 'product-photos');
create policy "fotos admin" on storage.objects for all using (bucket_id = 'product-photos' and is_admin()) with check (bucket_id = 'product-photos' and is_admin());

insert into categories (id,title,note,sort,shape,kind) values
('tortellonis','Tortellonis','docena',0,'dome','menu'),
('varenikes','Varenikes','docena',1,'dome','menu'),
('sorrentinos','Sorrentinos','docena',2,'dome','menu'),
('ravioles','Ravioles','2 planchas',3,'star','menu'),
('panzottis','Panzottis','docena',4,'star','menu'),
('tovotellis','Tovotellis','docena',5,'star','menu'),
('canelones','Canelones','4 unidades',6,'roll','menu'),
('raviolones','Raviolones','docena',7,'star','menu'),
('fideos','Fideos','500grs',8,'strand','menu'),
('noquis','Ñoquis','500grs',9,'gnocco','menu'),
('frankids','FranKids','30 unidades mini',10,'dome','menu'),
('empanadas','Empanadas','docena',11,'star','menu'),
('salsas','Salsas & Extras','sumalas a cualquier pedido',12,null,'extra')
on conflict (id) do nothing;

insert into products (category_id,name,description,price,photo_url,sort,color,badge,stock,shape) values
('tortellonis','Jamón Serrano y Rúcula','Jamón serrano curado y rúcula fresca',18000,'images/tortellonis-jamon-serrano-y-rucula.jpg',0,'#E8B86D',null,null,null),
('tortellonis','4 Quesos','Mezcla cremosa de cuatro quesos',18000,'images/tortellonis-4-quesos.jpg',1,'#F0CE8A',null,null,null),
('varenikes','Papa & Cebolla','Puré de papa y cebolla salteada',18000,'images/varenikes-papa-cebolla.jpg',0,'#E4C48C',null,null,null),
('sorrentinos','Jamón & Queso','Clásico jamón cocido y queso',18000,'images/sorrentinos-jamon-queso.jpg',0,'#F0CE8A',null,null,null),
('sorrentinos','Calabaza & Mozzarella','Calabaza asada y mozzarella',18000,'images/sorrentinos-calabaza-mozzarella.jpg',1,'#F2A65A',null,null,null),
('sorrentinos','Salmón Rosado','Masa negra rellena de salmón rosado',22000,'images/sorrentinos-salmon-rosado.jpg',2,'#2B2B33','nero',null,null),
('sorrentinos','Wok de Verdura','Verduras salteadas estilo wok',18000,'images/sorrentinos-wok-de-verdura.jpg',3,'#C9A876','integral',null,null),
('ravioles','Verdura','Espinaca, acelga y ricota',18000,'images/ravioles-verdura.jpg',0,'#7A9E52',null,null,null),
('ravioles','Pollo al Verdeo','Pollo desmenuzado y cebolla de verdeo',18000,'images/ravioles-pollo-al-verdeo.jpg',1,'#E3B968',null,null,null),
('panzottis','Hongos & Panceta Ahumada','Hongos salteados y panceta ahumada',22000,'images/panzottis-hongos-panceta-ahumada.jpg',0,'#A9784E',null,null,null),
('tovotellis','Vacío Braseado a la Cerveza','Vacío braseado lento a la cerveza',22000,'images/tovotellis-vacio-braseado-a-la-cerveza.jpg',0,'#B15A3A',null,null,null),
('tovotellis','Mejillones al Ajillo','Mejillones salteados al ajillo',22000,'images/tovotellis-mejillones-al-ajillo.jpg',1,'#D68A55','nero',null,null),
('tovotellis','Bondiola','Bondiola braseada a fuego lento',22000,'images/tovotellis-bondiola.jpg',2,'#C17F4A',null,null,null),
('canelones','Verdura','Espinaca, acelga y ricota',18000,'images/canelones-verdura.jpg',0,'#7A9E52',null,null,null),
('canelones','Seso & Verdura','Relleno de seso y verdura, en masa de espinaca',18000,'images/canelones-seso-verdura.jpg',1,'#D8C4B0',null,null,null),
('raviolones','Cordero Braseado','Cordero braseado a fuego lento',22000,'images/raviolones-cordero-braseado.jpg',0,'#8C4B3E',null,null,null),
('raviolones','Palta & Langostinos','Palta cremosa y langostinos salteados',23000,'images/raviolones-palta-langostinos.jpg',1,'#5F8F6E','nero',null,null),
('raviolones','Berenjena y Tomates S.','Berenjena y tomates secos',18000,null,2,'#B5473F','vegano',0,null),
('fideos','Spaghettis al Huevo','Masa fresca al huevo',14000,'images/fideos-spaghettis-al-huevo.jpg',0,'#EAC26B',null,null,null),
('fideos','Tagliatelles de Espinaca','Cinta fresca de espinaca',14000,'images/fideos-tagliatelles-de-espinaca.jpg',1,'#6E9A55',null,null,null),
('fideos','Spaghetti Nero di Sepia','Masa fresca teñida con tinta de sepia',17000,'images/fideos-spaghetti-nero-di-sepia.jpg',2,'#1C1B1A',null,null,null),
('noquis','Ñoquis de Papa','Receta clásica de papa',17000,'images/noquis-noquis-de-papa.jpg',0,'#EFD9A8',null,null,null),
('noquis','Malfattis de Espinaca','Espinaca y ricota',17000,'images/noquis-malfattis-de-espinaca.jpg',1,'#87A863',null,null,null),
('frankids','Raviolines de Calabaza','Mini raviolines de calabaza',10000,'images/frankids-raviolines-de-calabaza.jpg',0,'#F2A65A',null,null,null),
('empanadas','Criolla de Carne','Receta criolla clásica de carne cortada a cuchillo',22000,'images/empanadas-criolla-de-carne.jpg',0,'#E3C08A',null,null,null),
('empanadas','Batata y Boniato','Batata y boniato',22000,'images/empanadas-batata-y-boniato.jpg',1,'#D98A4A',null,null,null),
('salsas','Filetto',null,10000,null,0,'#D14C33',null,null,null),
('salsas','Bolognesa',null,10000,null,1,'#7A2E22',null,null,null),
('salsas','Mixta',null,10000,null,2,'#D9707B',null,null,null),
('salsas','4 Quesos',null,10000,null,3,'#EFCB6E',null,null,null),
('salsas','Verdeo',null,10000,null,4,'#6B8F4E',null,null,null),
('salsas','Mostaza',null,10000,null,5,'#DDA520',null,null,null),
('salsas','Roquefort',null,10000,null,6,'#B9C4D4',null,null,null),
('salsas','Salsa Blanca',null,10000,null,7,'#F3ECE0',null,null,null),
('salsas','Champignones',null,11000,null,8,'#A9825B',null,null,null),
('salsas','Crema de Hongos',null,11000,null,9,'#8C6A47',null,null,null),
('salsas','Camarones (crema)',null,12000,null,10,'#F2C2BC',null,null,null),
('salsas','Queso Rallado 100grs',null,6000,null,11,'#EFD9A8',null,null,'cheese');
