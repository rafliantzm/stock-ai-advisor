-- User feature schema for stock-ai-advisor.
-- Scope: database schema only. No Edge Functions, Flutter code, API keys, or real trading features.
--
-- Dependency note:
-- - Requires 0000_create_base_app_schema.sql.
-- - user_id columns reference profiles(user_id), which mirrors auth.users(id).
-- - symbol_id columns reference symbols(id); symbol_code is kept for display and lookup convenience.

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

create table public.watchlists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null,
  description text,
  is_default boolean not null default false,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.watchlists.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';

create table public.watchlist_items (
  id uuid primary key default gen_random_uuid(),
  watchlist_id uuid not null references public.watchlists(id) on delete cascade,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  user_notes text,
  added_reason text not null default 'manual',
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  added_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (watchlist_id, symbol_code)
);

comment on column public.watchlist_items.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.watchlist_scores (
  id uuid primary key default gen_random_uuid(),
  watchlist_item_id uuid not null references public.watchlist_items(id) on delete cascade,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  rule_version text not null,
  overall_score numeric,
  candidate_label text not null default 'watchlist_candidate' check (candidate_label in ('layak_dianalisis', 'watchlist_candidate', 'entry_candidate', 'risk_flagged', 'needs_more_data')),
  technical_score numeric,
  fundamental_score numeric,
  risk_score numeric,
  risk_warnings jsonb not null default '[]'::jsonb,
  invalidation_level numeric,
  explanation_id uuid,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  evaluated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.watchlist_scores.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.user_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text,
  name text not null,
  alert_type text not null check (alert_type in ('price', 'volume', 'score', 'event', 'invalidation', 'technical_setup', 'risk_warning')),
  cooldown_minutes integer not null default 60 check (cooldown_minutes >= 0),
  last_triggered_at timestamptz,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.user_alerts.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';
comment on column public.user_alerts.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.alert_conditions (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.user_alerts(id) on delete cascade,
  metric text not null,
  operator text not null check (operator in ('gt', 'gte', 'lt', 'lte', 'eq', 'between', 'in')),
  value_numeric numeric,
  value_text text,
  value_json jsonb,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.alert_logs (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.user_alerts(id) on delete cascade,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text,
  triggered_at timestamptz not null default now(),
  trigger_payload jsonb not null default '{}'::jsonb,
  message text not null,
  delivery_status text not null default 'pending' check (delivery_status in ('pending', 'triggered', 'archived', 'inactive')),
  status text not null default 'triggered' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.alert_logs.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.screener_presets (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  category text not null check (category in ('technical', 'fundamental', 'risk', 'event', 'volume_price', 'mixed')),
  is_system boolean not null default true,
  filter_summary jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.screener_filters (
  id uuid primary key default gen_random_uuid(),
  preset_id uuid references public.screener_presets(id) on delete cascade,
  metric text not null,
  operator text not null check (operator in ('gt', 'gte', 'lt', 'lte', 'eq', 'between', 'in')),
  value_json jsonb not null default '{}'::jsonb,
  weight numeric,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_saved_screeners (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null,
  filter_json jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.user_saved_screeners.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';

create table public.screener_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  screener_id uuid references public.user_saved_screeners(id) on delete set null,
  preset_id uuid references public.screener_presets(id) on delete set null,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  rule_version text not null,
  score numeric,
  candidate_label text not null default 'watchlist_candidate' check (candidate_label in ('layak_dianalisis', 'watchlist_candidate', 'entry_candidate', 'risk_flagged', 'needs_more_data')),
  matched_filters jsonb not null default '[]'::jsonb,
  run_id uuid not null default gen_random_uuid(),
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.screener_results.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';
comment on column public.screener_results.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.stock_financials (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  period text not null,
  revenue numeric,
  net_income numeric,
  total_assets numeric,
  total_liabilities numeric,
  equity numeric,
  operating_cashflow numeric,
  source text,
  reported_at date,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (symbol_code, period)
);

comment on column public.stock_financials.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.financial_growth_metrics (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  period text not null,
  revenue_growth numeric,
  earnings_growth numeric,
  roe numeric,
  roa numeric,
  der numeric,
  gross_margin numeric,
  net_margin numeric,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (symbol_code, period)
);

comment on column public.financial_growth_metrics.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.fundamental_scorecards (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  rule_version text not null,
  valuation_score numeric,
  profitability_score numeric,
  growth_score numeric,
  leverage_score numeric,
  cashflow_score numeric,
  overall_score numeric,
  risk_flags jsonb not null default '[]'::jsonb,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  evaluated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.fundamental_scorecards.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.chart_analysis_runs (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  timeframe text not null,
  window_size integer not null check (window_size > 0),
  rule_version text not null,
  technical_setup text,
  support_levels jsonb not null default '[]'::jsonb,
  resistance_levels jsonb not null default '[]'::jsonb,
  trendline_summary jsonb not null default '{}'::jsonb,
  volume_price_summary jsonb not null default '{}'::jsonb,
  risk_warnings jsonb not null default '[]'::jsonb,
  invalidation_level numeric,
  source_data_snapshot jsonb not null default '{}'::jsonb,
  explanation_id uuid,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.chart_analysis_runs.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.market_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  title text not null,
  description text,
  event_date date not null,
  source text,
  impact_level text not null default 'medium' check (impact_level in ('low', 'medium', 'high')),
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.corporate_actions (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  action_type text not null,
  announcement_date date,
  cum_date date,
  ex_date date,
  payment_date date,
  details jsonb not null default '{}'::jsonb,
  source text,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.corporate_actions.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.event_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  event_id uuid references public.market_events(id) on delete cascade,
  corporate_action_id uuid references public.corporate_actions(id) on delete cascade,
  alert_before_days integer not null default 1 check (alert_before_days >= 0),
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (event_id is not null or corporate_action_id is not null)
);

comment on column public.event_alerts.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';

create table public.insight_feed_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text,
  insight_type text not null check (insight_type in ('score_change', 'alert', 'event', 'screener', 'risk', 'technical_setup', 'fundamental')),
  title text not null,
  summary text not null,
  source_payload jsonb not null default '{}'::jsonb,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  read_at timestamptz
);

comment on column public.insight_feed_items.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';
comment on column public.insight_feed_items.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.portfolio_simulations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null,
  base_cash numeric not null default 0 check (base_cash >= 0),
  assumptions jsonb not null default '{}'::jsonb,
  risk_summary jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.portfolio_simulations.user_id is 'References profiles(user_id), which is the Supabase Auth user id.';

create table public.portfolio_positions (
  id uuid primary key default gen_random_uuid(),
  simulation_id uuid not null references public.portfolio_simulations(id) on delete cascade,
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  virtual_quantity numeric not null default 0 check (virtual_quantity >= 0),
  virtual_entry_price numeric not null default 0 check (virtual_entry_price >= 0),
  target_weight numeric check (target_weight is null or target_weight >= 0),
  notes text,
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.portfolio_positions.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

create table public.accumulation_distribution_insights (
  id uuid primary key default gen_random_uuid(),
  symbol_id uuid references public.symbols(id) on delete set null,
  symbol_code text not null,
  timeframe text not null,
  window_size integer not null check (window_size > 0),
  method text not null check (method in ('obv_proxy', 'adl_proxy', 'volume_price_proxy')),
  signal_label text not null check (signal_label in ('accumulation_pressure', 'distribution_pressure', 'neutral', 'inconclusive')),
  confidence_score numeric check (confidence_score is null or (confidence_score >= 0 and confidence_score <= 100)),
  metrics jsonb not null default '{}'::jsonb,
  limitations text not null default 'Proxy berbasis OHLCV; bukan broker summary.',
  status text not null default 'active' check (status in ('active', 'inactive', 'pending', 'triggered', 'archived')),
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on column public.accumulation_distribution_insights.symbol_id is 'References symbols(id). symbol_code is retained for display and resilient lookups.';

-- Updated-at triggers.
create trigger set_watchlists_updated_at before update on public.watchlists for each row execute function public.set_updated_at();
create trigger set_watchlist_items_updated_at before update on public.watchlist_items for each row execute function public.set_updated_at();
create trigger set_watchlist_scores_updated_at before update on public.watchlist_scores for each row execute function public.set_updated_at();
create trigger set_user_alerts_updated_at before update on public.user_alerts for each row execute function public.set_updated_at();
create trigger set_alert_conditions_updated_at before update on public.alert_conditions for each row execute function public.set_updated_at();
create trigger set_alert_logs_updated_at before update on public.alert_logs for each row execute function public.set_updated_at();
create trigger set_screener_presets_updated_at before update on public.screener_presets for each row execute function public.set_updated_at();
create trigger set_screener_filters_updated_at before update on public.screener_filters for each row execute function public.set_updated_at();
create trigger set_user_saved_screeners_updated_at before update on public.user_saved_screeners for each row execute function public.set_updated_at();
create trigger set_screener_results_updated_at before update on public.screener_results for each row execute function public.set_updated_at();
create trigger set_stock_financials_updated_at before update on public.stock_financials for each row execute function public.set_updated_at();
create trigger set_financial_growth_metrics_updated_at before update on public.financial_growth_metrics for each row execute function public.set_updated_at();
create trigger set_fundamental_scorecards_updated_at before update on public.fundamental_scorecards for each row execute function public.set_updated_at();
create trigger set_chart_analysis_runs_updated_at before update on public.chart_analysis_runs for each row execute function public.set_updated_at();
create trigger set_market_events_updated_at before update on public.market_events for each row execute function public.set_updated_at();
create trigger set_corporate_actions_updated_at before update on public.corporate_actions for each row execute function public.set_updated_at();
create trigger set_event_alerts_updated_at before update on public.event_alerts for each row execute function public.set_updated_at();
create trigger set_insight_feed_items_updated_at before update on public.insight_feed_items for each row execute function public.set_updated_at();
create trigger set_portfolio_simulations_updated_at before update on public.portfolio_simulations for each row execute function public.set_updated_at();
create trigger set_portfolio_positions_updated_at before update on public.portfolio_positions for each row execute function public.set_updated_at();
create trigger set_accumulation_distribution_insights_updated_at before update on public.accumulation_distribution_insights for each row execute function public.set_updated_at();

-- Indexes for common app queries.
create index idx_watchlists_user_id on public.watchlists(user_id);
create index idx_watchlist_items_watchlist_id on public.watchlist_items(watchlist_id);
create index idx_watchlist_items_symbol_code on public.watchlist_items(symbol_code);
create index idx_watchlist_scores_item_evaluated_at on public.watchlist_scores(watchlist_item_id, evaluated_at desc);
create index idx_user_alerts_user_id on public.user_alerts(user_id);
create index idx_alert_conditions_alert_id on public.alert_conditions(alert_id);
create index idx_alert_logs_alert_id_triggered_at on public.alert_logs(alert_id, triggered_at desc);
create index idx_screener_results_user_run_id on public.screener_results(user_id, run_id);
create index idx_stock_financials_symbol_period on public.stock_financials(symbol_code, period);
create index idx_financial_growth_metrics_symbol_period on public.financial_growth_metrics(symbol_code, period);
create index idx_fundamental_scorecards_symbol_evaluated_at on public.fundamental_scorecards(symbol_code, evaluated_at desc);
create index idx_chart_analysis_runs_symbol_calculated_at on public.chart_analysis_runs(symbol_code, calculated_at desc);
create index idx_market_events_event_date on public.market_events(event_date);
create index idx_corporate_actions_symbol_dates on public.corporate_actions(symbol_code, announcement_date, ex_date);
create index idx_event_alerts_user_id on public.event_alerts(user_id);
create index idx_insight_feed_items_user_created_at on public.insight_feed_items(user_id, created_at desc);
create index idx_portfolio_simulations_user_id on public.portfolio_simulations(user_id);
create index idx_portfolio_positions_simulation_id on public.portfolio_positions(simulation_id);
create index idx_accumulation_distribution_symbol_calculated_at on public.accumulation_distribution_insights(symbol_code, calculated_at desc);

-- RLS for user-owned tables and child tables.
alter table public.watchlists enable row level security;
alter table public.watchlist_items enable row level security;
alter table public.watchlist_scores enable row level security;
alter table public.user_alerts enable row level security;
alter table public.alert_conditions enable row level security;
alter table public.alert_logs enable row level security;
alter table public.user_saved_screeners enable row level security;
alter table public.screener_results enable row level security;
alter table public.event_alerts enable row level security;
alter table public.insight_feed_items enable row level security;
alter table public.portfolio_simulations enable row level security;
alter table public.portfolio_positions enable row level security;

create policy "Users can manage own watchlists"
on public.watchlists
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can manage own watchlist items"
on public.watchlist_items
for all
using (
  exists (
    select 1 from public.watchlists
    where watchlists.id = watchlist_items.watchlist_id
      and watchlists.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.watchlists
    where watchlists.id = watchlist_items.watchlist_id
      and watchlists.user_id = auth.uid()
  )
);

create policy "Users can read own watchlist scores"
on public.watchlist_scores
for select
using (
  exists (
    select 1
    from public.watchlist_items
    join public.watchlists on watchlists.id = watchlist_items.watchlist_id
    where watchlist_items.id = watchlist_scores.watchlist_item_id
      and watchlists.user_id = auth.uid()
  )
);

create policy "Users can manage own alerts"
on public.user_alerts
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can manage own alert conditions"
on public.alert_conditions
for all
using (
  exists (
    select 1 from public.user_alerts
    where user_alerts.id = alert_conditions.alert_id
      and user_alerts.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.user_alerts
    where user_alerts.id = alert_conditions.alert_id
      and user_alerts.user_id = auth.uid()
  )
);

create policy "Users can read own alert logs"
on public.alert_logs
for select
using (
  exists (
    select 1 from public.user_alerts
    where user_alerts.id = alert_logs.alert_id
      and user_alerts.user_id = auth.uid()
  )
);

create policy "Users can manage own saved screeners"
on public.user_saved_screeners
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can read own screener results"
on public.screener_results
for select
using (auth.uid() = user_id);

create policy "Users can manage own event alerts"
on public.event_alerts
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can read own insight feed"
on public.insight_feed_items
for select
using (auth.uid() = user_id);

create policy "Users can manage own portfolio simulations"
on public.portfolio_simulations
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can manage own portfolio positions"
on public.portfolio_positions
for all
using (
  exists (
    select 1 from public.portfolio_simulations
    where portfolio_simulations.id = portfolio_positions.simulation_id
      and portfolio_simulations.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.portfolio_simulations
    where portfolio_simulations.id = portfolio_positions.simulation_id
      and portfolio_simulations.user_id = auth.uid()
  )
);
