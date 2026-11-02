-- 20% de descuento en TODA la carta durante 48 horas desde que se corre este SQL.
update categories set promo_pct = 20, promo_until = now() + interval '48 hours';
