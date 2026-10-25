update categories set promo_until = (date_trunc('day', now() at time zone 'America/Argentina/Buenos_Aires') + interval '1 day') at time zone 'America/Argentina/Buenos_Aires' where id = 'salsas';
