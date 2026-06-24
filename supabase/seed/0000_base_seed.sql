insert into public.exchanges (exchange_code, exchange_name, country, currency, timezone)
values
  ('IDX', 'Indonesia Stock Exchange', 'Indonesia', 'IDR', 'Asia/Jakarta')
on conflict (exchange_code) do update
set
  exchange_name = excluded.exchange_name,
  country = excluded.country,
  currency = excluded.currency,
  timezone = excluded.timezone;

insert into public.sectors (sector_name, description)
values
  ('Financials', 'Banks, financing, insurance, and other financial services.'),
  ('Telecommunication', 'Telecommunication operators, connectivity, and digital infrastructure.'),
  ('Consumer Goods', 'Consumer staples and discretionary products.'),
  ('Industrial', 'Industrial goods, automotive, and manufacturing.'),
  ('Infrastructure', 'Infrastructure, transportation, and related services.'),
  ('Energy', 'Energy producers, distributors, and support services.'),
  ('Technology', 'Technology products and digital services.')
on conflict (sector_name) do update
set description = excluded.description;

insert into public.symbols (symbol_code, company_name, exchange_id, sector_id, instrument_type, currency, is_active)
select 'BBCA', 'Bank Central Asia Tbk', e.id, s.id, 'stock', 'IDR', true
from public.exchanges e
join public.sectors s on s.sector_name = 'Financials'
where e.exchange_code = 'IDX'
on conflict (symbol_code, exchange_id) do update
set
  company_name = excluded.company_name,
  sector_id = excluded.sector_id,
  instrument_type = excluded.instrument_type,
  currency = excluded.currency,
  is_active = excluded.is_active;

insert into public.symbols (symbol_code, company_name, exchange_id, sector_id, instrument_type, currency, is_active)
select 'BBRI', 'Bank Rakyat Indonesia Tbk', e.id, s.id, 'stock', 'IDR', true
from public.exchanges e
join public.sectors s on s.sector_name = 'Financials'
where e.exchange_code = 'IDX'
on conflict (symbol_code, exchange_id) do update
set
  company_name = excluded.company_name,
  sector_id = excluded.sector_id,
  instrument_type = excluded.instrument_type,
  currency = excluded.currency,
  is_active = excluded.is_active;

insert into public.symbols (symbol_code, company_name, exchange_id, sector_id, instrument_type, currency, is_active)
select 'TLKM', 'Telkom Indonesia Tbk', e.id, s.id, 'stock', 'IDR', true
from public.exchanges e
join public.sectors s on s.sector_name = 'Telecommunication'
where e.exchange_code = 'IDX'
on conflict (symbol_code, exchange_id) do update
set
  company_name = excluded.company_name,
  sector_id = excluded.sector_id,
  instrument_type = excluded.instrument_type,
  currency = excluded.currency,
  is_active = excluded.is_active;

insert into public.symbols (symbol_code, company_name, exchange_id, sector_id, instrument_type, currency, is_active)
select 'ASII', 'Astra International Tbk', e.id, s.id, 'stock', 'IDR', true
from public.exchanges e
join public.sectors s on s.sector_name = 'Industrial'
where e.exchange_code = 'IDX'
on conflict (symbol_code, exchange_id) do update
set
  company_name = excluded.company_name,
  sector_id = excluded.sector_id,
  instrument_type = excluded.instrument_type,
  currency = excluded.currency,
  is_active = excluded.is_active;

insert into public.symbols (symbol_code, company_name, exchange_id, sector_id, instrument_type, currency, is_active)
select 'UNVR', 'Unilever Indonesia Tbk', e.id, s.id, 'stock', 'IDR', true
from public.exchanges e
join public.sectors s on s.sector_name = 'Consumer Goods'
where e.exchange_code = 'IDX'
on conflict (symbol_code, exchange_id) do update
set
  company_name = excluded.company_name,
  sector_id = excluded.sector_id,
  instrument_type = excluded.instrument_type,
  currency = excluded.currency,
  is_active = excluded.is_active;
