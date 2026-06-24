-- Base app schema for stock-ai-advisor.
-- Scope: identity profile and stock master data only.
-- No Edge Functions, Flutter UI, API keys, or real trading transaction features.

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references auth.users(id) on delete cascade,
  full_name text,
  email text,
  risk_profile text check (risk_profile is null or risk_profile in ('conservative', 'moderate', 'aggressive')),
  investment_goal text,
  investment_horizon text check (investment_horizon is null or investment_horizon in ('short_term', 'medium_term', 'long_term')),
  monthly_budget numeric check (monthly_budget is null or monthly_budget >= 0),
  preferred_strategy text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.exchanges (
  id uuid primary key default gen_random_uuid(),
  exchange_code text unique not null,
  exchange_name text not null,
  country text,
  currency text,
  timezone text,
  created_at timestamptz not null default now()
);

create table public.sectors (
  id uuid primary key default gen_random_uuid(),
  sector_name text unique not null,
  description text,
  created_at timestamptz not null default now()
);

create table public.symbols (
  id uuid primary key default gen_random_uuid(),
  symbol_code text not null,
  company_name text not null,
  exchange_id uuid references public.exchanges(id) on delete restrict,
  sector_id uuid references public.sectors(id) on delete set null,
  instrument_type text not null default 'stock',
  currency text not null default 'IDR',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (symbol_code, exchange_id)
);

create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger set_symbols_updated_at
before update on public.symbols
for each row execute function public.set_updated_at();

create index idx_profiles_user_id on public.profiles(user_id);
create index idx_symbols_symbol_code on public.symbols(symbol_code);
create index idx_symbols_exchange_id on public.symbols(exchange_id);
create index idx_symbols_sector_id on public.symbols(sector_id);

alter table public.profiles enable row level security;
alter table public.exchanges enable row level security;
alter table public.sectors enable row level security;
alter table public.symbols enable row level security;

create policy "Users can select own profile"
on public.profiles
for select
using (auth.uid() = user_id);

create policy "Users can insert own profile"
on public.profiles
for insert
with check (auth.uid() = user_id);

create policy "Users can update own profile"
on public.profiles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

comment on table public.exchanges is 'Master exchange data. RLS enabled without public policy; access through Edge Functions or service role until read rules are finalized.';
comment on table public.sectors is 'Master sector data. RLS enabled without public policy; access through Edge Functions or service role until read rules are finalized.';
comment on table public.symbols is 'Master stock symbol data. RLS enabled without public policy; access through Edge Functions or service role until read rules are finalized.';
