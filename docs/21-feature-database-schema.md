# 21. Feature Database Schema

Schema ini bersifat rancangan awal. Nama kolom dapat disesuaikan saat migration dibuat, tetapi boundary keamanan harus dipertahankan.

## Common Conventions

- Primary key: `id uuid primary key default gen_random_uuid()`
- User relation: `user_id uuid references auth.users(id)`
- Symbol relation: `symbol_id uuid references symbols(id)` bila tabel `symbols` sudah tersedia.
- Audit fields: `created_at timestamptz`, `updated_at timestamptz`
- Rule outputs harus menyimpan `rule_version`.
- RLS wajib untuk data milik user.

## watchlists

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| name | text | Nama watchlist |
| description | text | Optional |
| is_default | boolean | Default false |
| created_at | timestamptz | Audit |
| updated_at | timestamptz | Audit |

## watchlist_items

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| watchlist_id | uuid | FK watchlists |
| symbol_id | uuid | FK symbols |
| user_notes | text | Catatan user |
| added_reason | text | Manual, screener, alert, event |
| added_at | timestamptz | Audit |

## watchlist_scores

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| watchlist_item_id | uuid | FK watchlist_items |
| symbol_id | uuid | FK symbols |
| rule_version | text | Versi rule engine |
| overall_score | numeric | Score terkontrol |
| candidate_label | text | watchlist_candidate, entry_candidate, risk_flagged |
| technical_score | numeric | Optional |
| fundamental_score | numeric | Optional |
| risk_score | numeric | Optional |
| invalidation_level | numeric | Optional |
| explanation_id | uuid | Optional link |
| evaluated_at | timestamptz | Timestamp |

## user_alerts

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| symbol_id | uuid | Optional for broad alerts |
| name | text | Alert name |
| alert_type | text | price, volume, score, event, invalidation |
| is_active | boolean | Active flag |
| cooldown_minutes | integer | Prevent spam |
| last_triggered_at | timestamptz | Optional |
| created_at | timestamptz | Audit |
| updated_at | timestamptz | Audit |

## alert_conditions

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| alert_id | uuid | FK user_alerts |
| metric | text | price, volume_ratio, score, event_type |
| operator | text | gt, gte, lt, lte, eq, between |
| value_numeric | numeric | Optional |
| value_text | text | Optional |
| value_json | jsonb | Complex conditions |

## alert_logs

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| alert_id | uuid | FK user_alerts |
| symbol_id | uuid | Optional |
| triggered_at | timestamptz | Timestamp |
| trigger_payload | jsonb | Snapshot of matched condition |
| message | text | Safe wording |
| delivery_status | text | pending, sent, read, failed |

## screener_presets

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| name | text | Preset name |
| description | text | Educational description |
| category | text | technical, fundamental, risk, event |
| is_system | boolean | System preset |
| created_at | timestamptz | Audit |

## screener_filters

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| preset_id | uuid | FK screener_presets nullable |
| metric | text | Filter metric |
| operator | text | gt, lt, between, in |
| value_json | jsonb | Filter value |
| weight | numeric | Optional scoring weight |

## user_saved_screeners

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| name | text | Saved name |
| filter_json | jsonb | User-defined filters |
| created_at | timestamptz | Audit |
| updated_at | timestamptz | Audit |

## screener_results

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| screener_id | uuid | Optional saved screener |
| symbol_id | uuid | FK symbols |
| rule_version | text | Rule version |
| score | numeric | Result score |
| candidate_label | text | watchlist_candidate, risk_flagged |
| matched_filters | jsonb | Explainable filter matches |
| run_id | uuid | Batch id |
| created_at | timestamptz | Audit |

## stock_financials

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| symbol_id | uuid | FK symbols |
| period | text | FY2025, Q1-2026 |
| revenue | numeric | Optional |
| net_income | numeric | Optional |
| total_assets | numeric | Optional |
| total_liabilities | numeric | Optional |
| equity | numeric | Optional |
| operating_cashflow | numeric | Optional |
| source | text | Provider/source |
| reported_at | date | Report date |

## financial_growth_metrics

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| symbol_id | uuid | FK symbols |
| period | text | Period |
| revenue_growth | numeric | Optional |
| earnings_growth | numeric | Optional |
| roe | numeric | Optional |
| roa | numeric | Optional |
| der | numeric | Optional |
| gross_margin | numeric | Optional |
| net_margin | numeric | Optional |
| calculated_at | timestamptz | Audit |

## fundamental_scorecards

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| symbol_id | uuid | FK symbols |
| rule_version | text | Rule version |
| valuation_score | numeric | Optional |
| profitability_score | numeric | Optional |
| growth_score | numeric | Optional |
| leverage_score | numeric | Optional |
| cashflow_score | numeric | Optional |
| overall_score | numeric | Overall |
| risk_flags | jsonb | Warnings |
| evaluated_at | timestamptz | Timestamp |

## chart_analysis_runs

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| symbol_id | uuid | FK symbols |
| timeframe | text | 1D, 1W, 1M |
| window_size | integer | Lookback candles |
| rule_version | text | Rule version |
| technical_setup | text | Backend-calculated setup label |
| support_levels | jsonb | Calculated support levels |
| resistance_levels | jsonb | Calculated resistance levels |
| trendline_summary | jsonb | Trendline/channel result |
| volume_price_summary | jsonb | Volume-price result |
| risk_warnings | jsonb | Risk warning list |
| invalidation_level | numeric | Optional level |
| source_data_snapshot | jsonb | OHLCV metadata, not raw secret |
| explanation_id | uuid | Optional link |
| calculated_at | timestamptz | Timestamp |

## market_events

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| event_type | text | macro, holiday, earnings, sector |
| title | text | Event title |
| description | text | Optional |
| event_date | date | Date |
| source | text | Data source |
| impact_level | text | low, medium, high |

## corporate_actions

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| symbol_id | uuid | FK symbols |
| action_type | text | dividend, split, rights, IPO, RUPS |
| announcement_date | date | Optional |
| cum_date | date | Optional |
| ex_date | date | Optional |
| payment_date | date | Optional |
| details | jsonb | Flexible payload |
| source | text | Data source |

## event_alerts

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| event_id | uuid | FK market_events nullable |
| corporate_action_id | uuid | FK corporate_actions nullable |
| alert_before_days | integer | Lead time |
| is_active | boolean | Active flag |
| created_at | timestamptz | Audit |

## insight_feed_items

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| symbol_id | uuid | Optional |
| insight_type | text | score_change, alert, event, screener, risk |
| title | text | Safe title |
| summary | text | AI explanation or rule summary |
| source_payload | jsonb | Traceable source |
| priority | text | low, medium, high |
| created_at | timestamptz | Audit |
| read_at | timestamptz | Optional |

## portfolio_simulations

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| user_id | uuid | Owner |
| name | text | Simulation name |
| base_cash | numeric | Virtual cash |
| assumptions | jsonb | Fees, slippage, period |
| risk_summary | jsonb | Calculated summary |
| created_at | timestamptz | Audit |
| updated_at | timestamptz | Audit |

## portfolio_positions

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| simulation_id | uuid | FK portfolio_simulations |
| symbol_id | uuid | FK symbols |
| virtual_quantity | numeric | Simulated only |
| virtual_entry_price | numeric | Simulated only |
| target_weight | numeric | Optional |
| notes | text | User notes |

## accumulation_distribution_insights

| Column | Type | Notes |
| --- | --- | --- |
| id | uuid | Primary key |
| symbol_id | uuid | FK symbols |
| timeframe | text | daily, weekly |
| window_size | integer | Lookback |
| method | text | obv_proxy, adl_proxy, volume_price_proxy |
| signal_label | text | accumulation_pressure, distribution_pressure, neutral, inconclusive |
| confidence_score | numeric | 0-100 |
| metrics | jsonb | Calculated details |
| limitations | text | Data caveat |
| calculated_at | timestamptz | Timestamp |
