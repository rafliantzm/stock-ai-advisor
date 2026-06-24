-- Backfill and enforce feature-schema foreign keys.
-- Safe to run after 0000_create_base_app_schema.sql and 0003_create_user_feature_schema.sql.
-- This migration is intentionally idempotent for projects that already added inline FKs in 0003.

create or replace function public.backfill_symbol_id_from_symbol_code(target_table regclass)
returns void
language plpgsql
as $$
begin
  execute format(
    'update %s as target
     set symbol_id = null
     where target.symbol_id is not null
       and not exists (
         select 1
         from public.symbols s
         where s.id = target.symbol_id
       )',
    target_table
  );

  execute format(
    'with preferred_symbols as (
       select
         s.id,
         upper(s.symbol_code) as normalized_symbol_code,
         row_number() over (
           partition by upper(s.symbol_code)
           order by
             case when e.exchange_code = ''IDX'' then 0 else 1 end,
             s.created_at,
             s.id
         ) as rank_order
       from public.symbols s
       left join public.exchanges e on e.id = s.exchange_id
       where s.is_active = true
     )
     update %s as target
     set symbol_id = preferred_symbols.id
     from preferred_symbols
     where target.symbol_id is null
       and target.symbol_code is not null
       and upper(target.symbol_code) = preferred_symbols.normalized_symbol_code
       and preferred_symbols.rank_order = 1',
    target_table
  );
end;
$$;

create or replace function public.add_fk_if_missing(
  child_table regclass,
  child_column text,
  parent_table regclass,
  parent_column text,
  constraint_name text,
  on_delete_action text
)
returns void
language plpgsql
as $$
declare
  child_attnum smallint;
  parent_attnum smallint;
  delete_clause text;
begin
  select attnum
  into child_attnum
  from pg_attribute
  where attrelid = child_table
    and attname = child_column
    and not attisdropped;

  select attnum
  into parent_attnum
  from pg_attribute
  where attrelid = parent_table
    and attname = parent_column
    and not attisdropped;

  if child_attnum is null or parent_attnum is null then
    raise exception 'Cannot create FK %. Missing %.% or %.%',
      constraint_name, child_table, child_column, parent_table, parent_column;
  end if;

  if exists (
    select 1
    from pg_constraint
    where contype = 'f'
      and conrelid = child_table
      and confrelid = parent_table
      and conkey = array[child_attnum]
      and confkey = array[parent_attnum]
  ) then
    return;
  end if;

  delete_clause := case lower(on_delete_action)
    when 'cascade' then 'on delete cascade'
    when 'set null' then 'on delete set null'
    when 'restrict' then 'on delete restrict'
    else ''
  end;

  execute format(
    'alter table %s add constraint %I foreign key (%I) references %s(%I) %s',
    child_table,
    constraint_name,
    child_column,
    parent_table,
    parent_column,
    delete_clause
  );
end;
$$;

-- Backfill symbol_id from symbol_code where possible.
select public.backfill_symbol_id_from_symbol_code('public.watchlist_items'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.watchlist_scores'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.user_alerts'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.alert_logs'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.screener_results'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.stock_financials'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.financial_growth_metrics'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.fundamental_scorecards'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.chart_analysis_runs'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.corporate_actions'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.insight_feed_items'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.portfolio_positions'::regclass);
select public.backfill_symbol_id_from_symbol_code('public.accumulation_distribution_insights'::regclass);

-- Backfill minimal profiles for existing feature rows when the auth user exists.
insert into public.profiles (user_id, email)
select distinct candidate_users.user_id, auth_users.email
from (
  select user_id from public.watchlists
  union
  select user_id from public.user_alerts
  union
  select user_id from public.user_saved_screeners
  union
  select user_id from public.screener_results
  union
  select user_id from public.event_alerts
  union
  select user_id from public.insight_feed_items
  union
  select user_id from public.portfolio_simulations
) candidate_users
join auth.users auth_users on auth_users.id = candidate_users.user_id
left join public.profiles profiles on profiles.user_id = candidate_users.user_id
where profiles.user_id is null;

-- Enforce user ownership FK through profiles(user_id), which maps to auth.users(id).
select public.add_fk_if_missing('public.watchlists'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_watchlists_profiles_user_id', 'cascade');
select public.add_fk_if_missing('public.user_alerts'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_user_alerts_profiles_user_id', 'cascade');
select public.add_fk_if_missing('public.user_saved_screeners'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_user_saved_screeners_profiles_user_id', 'cascade');
select public.add_fk_if_missing('public.screener_results'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_screener_results_profiles_user_id', 'cascade');
select public.add_fk_if_missing('public.event_alerts'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_event_alerts_profiles_user_id', 'cascade');
select public.add_fk_if_missing('public.insight_feed_items'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_insight_feed_items_profiles_user_id', 'cascade');
select public.add_fk_if_missing('public.portfolio_simulations'::regclass, 'user_id', 'public.profiles'::regclass, 'user_id', 'fk_portfolio_simulations_profiles_user_id', 'cascade');

-- Enforce symbol FK after backfill.
select public.add_fk_if_missing('public.watchlist_items'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_watchlist_items_symbols_id', 'set null');
select public.add_fk_if_missing('public.watchlist_scores'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_watchlist_scores_symbols_id', 'set null');
select public.add_fk_if_missing('public.user_alerts'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_user_alerts_symbols_id', 'set null');
select public.add_fk_if_missing('public.alert_logs'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_alert_logs_symbols_id', 'set null');
select public.add_fk_if_missing('public.screener_results'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_screener_results_symbols_id', 'set null');
select public.add_fk_if_missing('public.stock_financials'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_stock_financials_symbols_id', 'set null');
select public.add_fk_if_missing('public.financial_growth_metrics'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_financial_growth_metrics_symbols_id', 'set null');
select public.add_fk_if_missing('public.fundamental_scorecards'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_fundamental_scorecards_symbols_id', 'set null');
select public.add_fk_if_missing('public.chart_analysis_runs'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_chart_analysis_runs_symbols_id', 'set null');
select public.add_fk_if_missing('public.corporate_actions'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_corporate_actions_symbols_id', 'set null');
select public.add_fk_if_missing('public.insight_feed_items'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_insight_feed_items_symbols_id', 'set null');
select public.add_fk_if_missing('public.portfolio_positions'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_portfolio_positions_symbols_id', 'set null');
select public.add_fk_if_missing('public.accumulation_distribution_insights'::regclass, 'symbol_id', 'public.symbols'::regclass, 'id', 'fk_accumulation_distribution_insights_symbols_id', 'set null');

drop function public.add_fk_if_missing(regclass, text, regclass, text, text, text);
drop function public.backfill_symbol_id_from_symbol_code(regclass);
