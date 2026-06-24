-- P2 market data schema for stock-ai-advisor.
-- Scope: provider metadata, market data cache, OHLCV bars, indicators, market context, and news cache.
-- Safe additive migration: creates new P2 tables only; no Flutter changes, provider API keys, or transaction features.
--
-- Dependency note:
-- - Requires 0000_create_base_app_schema.sql for public.symbols and public.set_updated_at().
-- - Market data tables are backend-managed. Flutter must read through Edge Functions with anon key + user JWT.

create extension if not exists pgcrypto;

create table public.provider_sources (
  id uuid primary key default gen_random_uuid(),
  provider_name text not null unique,
  provider_type text not null check (provider_type in ('sample', 'official', 'vendor', 'manual')),
  base_url text,
  documentation_url text,
  attribution_text text,
  terms_url text,
  supports_quotes boolean not null default false,
  supports_ohlcv boolean not null default false,
  supports_market_context boolean not null default false,
  supports_news boolean not null default false,
  rate_limit_per_minute integer check (rate_limit_per_minute is null or rate_limit_per_minute >= 0),
  cache_ttl_seconds integer not null default 900 check (cache_ttl_seconds >= 0),
  data_delay_seconds integer check (data_delay_seconds is null or data_delay_seconds >= 0),
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'archived')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.provider_sources is 'Market data provider metadata only. Do not store API keys, secrets, tokens, or credentials in this table.';
comment on column public.provider_sources.base_url is 'Non-secret provider base URL only. API keys must live in Supabase Edge Function environment variables.';

create table public.provider_sync_runs (
  id uuid primary key default gen_random_uuid(),
  provider_source_id uuid references public.provider_sources(id) on delete set null,
  provider_name text not null,
  sync_type text not null check (sync_type in ('quote', 'ohlcv', 'market_context', 'technical_indicator', 'news')),
  run_mode text not null default 'manual' check (run_mode in ('manual', 'scheduled', 'on_demand')),
  status text not null default 'pending' check (status in ('pending', 'running', 'success', 'partial', 'failed', 'skipped', 'archived')),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text,
  timeframe text,
  observed_at timestamptz,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  rows_requested integer check (rows_requested is null or rows_requested >= 0),
  rows_inserted integer check (rows_inserted is null or rows_inserted >= 0),
  rows_updated integer check (rows_updated is null or rows_updated >= 0),
  rows_failed integer check (rows_failed is null or rows_failed >= 0),
  rate_limit_remaining integer check (rate_limit_remaining is null or rate_limit_remaining >= 0),
  error_code text,
  error_message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.provider_sync_runs is 'Audit trail for backend provider sync. Error fields must not contain provider secrets or API keys.';

create table public.market_price_snapshots (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  provider_source_id uuid references public.provider_sources(id) on delete set null,
  provider_name text not null,
  provider_symbol text,
  observed_at timestamptz not null,
  last_price numeric,
  previous_close numeric,
  open_price numeric,
  high_price numeric,
  low_price numeric,
  change_value numeric,
  change_percent numeric,
  volume numeric,
  value_traded numeric,
  market_cap numeric,
  currency text not null default 'IDR',
  data_quality text not null default 'sample' check (data_quality in ('sample', 'delayed', 'realtime', 'stale', 'needs_more_data')),
  is_stale boolean not null default true,
  staleness_warning text,
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (symbol_code, provider_name, observed_at)
);

comment on table public.market_price_snapshots is 'Backend-managed quote cache for educational analysis. Flutter must access through Edge Functions.';
comment on column public.market_price_snapshots.raw_payload is 'Optional provider payload cache. Do not store API keys, headers, cookies, or credentials.';

create table public.ohlcv_bars (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  provider_source_id uuid references public.provider_sources(id) on delete set null,
  provider_name text not null,
  provider_symbol text,
  timeframe text not null,
  observed_at timestamptz not null,
  open_price numeric not null,
  high_price numeric not null,
  low_price numeric not null,
  close_price numeric not null,
  volume numeric,
  value_traded numeric,
  data_quality text not null default 'sample' check (data_quality in ('sample', 'delayed', 'realtime', 'stale', 'needs_more_data')),
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (symbol_code, provider_name, timeframe, observed_at)
);

comment on table public.ohlcv_bars is 'Backend-managed OHLCV cache. Initial P2 should prefer daily timeframe until provider and rate limits are validated.';
comment on column public.ohlcv_bars.raw_payload is 'Optional provider payload cache. Do not store API keys, headers, cookies, or credentials.';

create table public.technical_indicator_snapshots (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  provider_source_id uuid references public.provider_sources(id) on delete set null,
  provider_name text not null default 'internal_rule_engine',
  timeframe text not null,
  observed_at timestamptz not null,
  ema_20 numeric,
  ema_50 numeric,
  ema_200 numeric,
  rsi_14 numeric,
  atr_14 numeric,
  average_volume_20 numeric,
  volume_ratio numeric,
  support_level numeric,
  resistance_level numeric,
  trend_state text not null default 'needs_more_data',
  candlestick_pattern text,
  indicator_payload jsonb not null default '{}'::jsonb,
  technical_score numeric check (technical_score is null or (technical_score >= 0 and technical_score <= 100)),
  trend_score numeric check (trend_score is null or (trend_score >= 0 and trend_score <= 100)),
  volume_score numeric check (volume_score is null or (volume_score >= 0 and volume_score <= 100)),
  risk_score numeric check (risk_score is null or (risk_score >= 0 and risk_score <= 100)),
  invalidation_level numeric,
  rule_version text not null default 'p2_indicator_v1',
  data_quality text not null default 'sample' check (data_quality in ('sample', 'computed', 'stale', 'needs_more_data')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (symbol_code, timeframe, observed_at, rule_version)
);

comment on table public.technical_indicator_snapshots is 'Backend-computed technical indicators. Flutter renders results only; sensitive scoring logic stays in Edge Functions/backend.';

create table public.market_context_snapshots (
  id uuid primary key default gen_random_uuid(),
  provider_source_id uuid references public.provider_sources(id) on delete set null,
  provider_name text not null,
  market_code text not null default 'IDX',
  index_symbol text not null default 'IHSG',
  observed_at timestamptz not null,
  index_last numeric,
  index_change numeric,
  index_change_percent numeric,
  index_trend text not null default 'needs_more_data',
  market_status text not null default 'provider belum aktif',
  risk_regime text not null default 'needs_more_data',
  breadth_summary jsonb not null default '{}'::jsonb,
  context_payload jsonb not null default '{}'::jsonb,
  data_quality text not null default 'sample' check (data_quality in ('sample', 'delayed', 'realtime', 'stale', 'needs_more_data')),
  is_stale boolean not null default true,
  staleness_warning text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (market_code, index_symbol, provider_name, observed_at)
);

comment on table public.market_context_snapshots is 'Backend-managed market context cache for IDX/IHSG and risk regime display.';

create table public.news_items (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text,
  provider_source_id uuid references public.provider_sources(id) on delete set null,
  provider_name text not null,
  headline text not null,
  summary text,
  source_name text,
  source_url text,
  category text not null default 'market' check (category in ('market', 'corporate_action', 'dividend', 'earnings', 'macro', 'company', 'other')),
  sentiment_label text not null default 'needs_more_data' check (sentiment_label in ('positive', 'neutral', 'negative', 'needs_more_data')),
  impact_level text not null default 'medium' check (impact_level in ('low', 'medium', 'high')),
  published_at timestamptz,
  observed_at timestamptz not null default now(),
  data_quality text not null default 'sample' check (data_quality in ('sample', 'delayed', 'realtime', 'stale', 'needs_more_data')),
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.news_items is 'Backend-managed news/catalyst cache. Provider terms and attribution must be reviewed before production use.';
comment on column public.news_items.raw_payload is 'Optional provider payload cache. Do not store API keys, headers, cookies, or credentials.';

-- Updated-at triggers.
create trigger set_provider_sources_updated_at
before update on public.provider_sources
for each row execute function public.set_updated_at();

create trigger set_provider_sync_runs_updated_at
before update on public.provider_sync_runs
for each row execute function public.set_updated_at();

create trigger set_market_price_snapshots_updated_at
before update on public.market_price_snapshots
for each row execute function public.set_updated_at();

create trigger set_technical_indicator_snapshots_updated_at
before update on public.technical_indicator_snapshots
for each row execute function public.set_updated_at();

create trigger set_market_context_snapshots_updated_at
before update on public.market_context_snapshots
for each row execute function public.set_updated_at();

create trigger set_news_items_updated_at
before update on public.news_items
for each row execute function public.set_updated_at();

-- Common indexes for provider, symbol, timeframe, observed_at, and created_at queries.
create index idx_provider_sources_provider_name on public.provider_sources(provider_name);
create index idx_provider_sources_created_at on public.provider_sources(created_at desc);

create index idx_provider_sync_runs_provider_name on public.provider_sync_runs(provider_name);
create index idx_provider_sync_runs_symbol_id on public.provider_sync_runs(symbol_id);
create index idx_provider_sync_runs_symbol_code on public.provider_sync_runs(symbol_code);
create index idx_provider_sync_runs_timeframe on public.provider_sync_runs(timeframe);
create index idx_provider_sync_runs_observed_at on public.provider_sync_runs(observed_at desc);
create index idx_provider_sync_runs_created_at on public.provider_sync_runs(created_at desc);
create index idx_provider_sync_runs_status_started_at on public.provider_sync_runs(status, started_at desc);

create index idx_market_price_snapshots_symbol_id on public.market_price_snapshots(symbol_id);
create index idx_market_price_snapshots_symbol_code on public.market_price_snapshots(symbol_code);
create index idx_market_price_snapshots_provider_name on public.market_price_snapshots(provider_name);
create index idx_market_price_snapshots_observed_at on public.market_price_snapshots(observed_at desc);
create index idx_market_price_snapshots_created_at on public.market_price_snapshots(created_at desc);
create index idx_market_price_snapshots_symbol_observed_at on public.market_price_snapshots(symbol_id, observed_at desc);

create index idx_ohlcv_bars_symbol_id on public.ohlcv_bars(symbol_id);
create index idx_ohlcv_bars_symbol_code on public.ohlcv_bars(symbol_code);
create index idx_ohlcv_bars_timeframe on public.ohlcv_bars(timeframe);
create index idx_ohlcv_bars_provider_name on public.ohlcv_bars(provider_name);
create index idx_ohlcv_bars_observed_at on public.ohlcv_bars(observed_at desc);
create index idx_ohlcv_bars_created_at on public.ohlcv_bars(created_at desc);
create index idx_ohlcv_bars_symbol_timeframe_observed_at on public.ohlcv_bars(symbol_id, timeframe, observed_at desc);

create index idx_technical_indicator_snapshots_symbol_id on public.technical_indicator_snapshots(symbol_id);
create index idx_technical_indicator_snapshots_symbol_code on public.technical_indicator_snapshots(symbol_code);
create index idx_technical_indicator_snapshots_timeframe on public.technical_indicator_snapshots(timeframe);
create index idx_technical_indicator_snapshots_provider_name on public.technical_indicator_snapshots(provider_name);
create index idx_technical_indicator_snapshots_observed_at on public.technical_indicator_snapshots(observed_at desc);
create index idx_technical_indicator_snapshots_created_at on public.technical_indicator_snapshots(created_at desc);
create index idx_technical_indicator_snapshots_symbol_timeframe_observed_at on public.technical_indicator_snapshots(symbol_id, timeframe, observed_at desc);

create index idx_market_context_snapshots_provider_name on public.market_context_snapshots(provider_name);
create index idx_market_context_snapshots_observed_at on public.market_context_snapshots(observed_at desc);
create index idx_market_context_snapshots_created_at on public.market_context_snapshots(created_at desc);
create index idx_market_context_snapshots_market_observed_at on public.market_context_snapshots(market_code, index_symbol, observed_at desc);

create index idx_news_items_symbol_id on public.news_items(symbol_id);
create index idx_news_items_symbol_code on public.news_items(symbol_code);
create index idx_news_items_provider_name on public.news_items(provider_name);
create index idx_news_items_observed_at on public.news_items(observed_at desc);
create index idx_news_items_created_at on public.news_items(created_at desc);
create index idx_news_items_published_at on public.news_items(published_at desc);

-- RLS: market data is global cache, not user-owned.
-- Keep tables protected from direct client reads/writes; Edge Functions should mediate access.
alter table public.provider_sources enable row level security;
alter table public.provider_sync_runs enable row level security;
alter table public.market_price_snapshots enable row level security;
alter table public.ohlcv_bars enable row level security;
alter table public.technical_indicator_snapshots enable row level security;
alter table public.market_context_snapshots enable row level security;
alter table public.news_items enable row level security;

comment on table public.provider_sources is 'RLS enabled without public policy. Managed by backend/Edge Functions. No API keys or secrets.';
comment on table public.provider_sync_runs is 'RLS enabled without public policy. Backend audit log for provider sync.';
comment on table public.market_price_snapshots is 'RLS enabled without public policy. Flutter reads sanitized quote data through Edge Functions.';
comment on table public.ohlcv_bars is 'RLS enabled without public policy. Flutter reads chart data through Edge Functions after P2 endpoint is added.';
comment on table public.technical_indicator_snapshots is 'RLS enabled without public policy. Backend-computed indicators for educational analysis.';
comment on table public.market_context_snapshots is 'RLS enabled without public policy. Flutter reads sanitized market context through Edge Functions.';
comment on table public.news_items is 'RLS enabled without public policy. Flutter reads sanitized news/catalyst summaries through Edge Functions.';
