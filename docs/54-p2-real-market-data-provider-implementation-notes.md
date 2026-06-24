# P2 Real Market Data Provider Implementation Notes

Dokumen ini mencatat implementasi adapter real market data provider untuk P2. Scope tetap backend-only melalui Supabase Edge Functions. Flutter hanya memakai Supabase Auth token dan anon key.

## Implemented

- `MARKET_DATA_PROVIDER`, `MARKET_DATA_PROVIDER_BASE_URL`, dan `MARKET_DATA_PROVIDER_API_KEY` didukung sebagai env utama.
- Env lama tetap didukung sebagai alias:
  - `MARKET_DATA_PROVIDER_NAME`
  - `MARKET_DATA_API_BASE_URL`
  - `MARKET_DATA_API_KEY`
- Adapter default: `generic_json`.
- Request method default: `POST`.
- `MARKET_DATA_PROVIDER_METHOD=GET` didukung untuk provider yang memakai query string.
- Provider failure, timeout, invalid JSON, incomplete quote, stale source time, dan rate limit HTTP akan jatuh ke fallback aman.
- Raw provider response tidak dikirim ke Flutter.
- Provider credential tidak disimpan di Flutter, docs publik, atau response.

## Normalized Quote Fields

Adapter mencoba membaca field berikut dari provider payload:

| Internal Field | Provider Field Candidates |
| --- | --- |
| `symbol_code` | `symbol_code`, `symbol`, `provider_symbol` |
| `company_name` | `company_name`, `name` |
| `source_time` | `source_time`, `observed_at`, `timestamp`, `time`, `date` |
| `last_price` | `last_price`, `price`, `close_price`, `close` |
| `previous_close` | `previous_close` |
| `open_price` | `open_price`, `open` |
| `high_price` | `high_price`, `high` |
| `low_price` | `low_price`, `low` |
| `change_value` | `change_value`, `change` |
| `change_percent` | `change_percent` |
| `volume` | `volume` |
| `value_traded` | `value_traded` |
| `currency` | `currency` |

`company_name` and `source_time` can be stored only as safe normalized metadata. Provider auth headers, cookies, tokens, and raw credential fields must never be stored.

## Data Quality Rules

| Condition | `provider_mode` | `data_quality` |
| --- | --- | --- |
| Sample mode | `sample` | `sample` |
| Live env incomplete | `fallback_sample` | `sample` |
| Live payload valid and fresh | `live` | `live` |
| Live payload marked delayed | `live` | `delayed` |
| Live payload stale/invalid/unavailable | `provider_error` | `stale` |

For database compatibility:

- response `live` is stored as DB `realtime`;
- response `delayed` is stored as DB `delayed`;
- technical indicator snapshots from fresh provider quotes are stored as DB `computed`;
- response `stale` remains DB `stale`.

## Technical Indicator Snapshot

When quote fields are sufficient, the backend writes a minimal technical snapshot:

- `support_level` from low price;
- `resistance_level` from high price;
- `technical_score` from quote change percent;
- `trend_state` as educational watchlist context;
- `invalidation_level` as an educational risk context derived from last price.

This is not a full OHLCV indicator engine. OHLCV-based indicators remain a follow-up.

## Market Context

Market context supports root object, `market_context`, `context`, or `data`. The adapter reads:

- `market_code`
- `index_symbol`
- `source_time` / `observed_at` / `timestamp` / `time` / `date`
- `index_last` / `last_price` / `price` / `close_price` / `close`
- `index_change` / `change_value` / `change`
- `index_change_percent` / `change_percent`
- `index_trend`
- `market_status`
- `risk_regime`

If IHSG/IDX context is unavailable, `get-market-context` returns sample/stale fallback with clear `risk_warning`.

## Security

- Provider credential is read only from Supabase Edge Function environment.
- Flutter must never store provider key or service role key.
- Edge Function responses expose only safe metadata:
  - `provider_name`
  - `requested_provider_name`
  - `provider_mode`
  - `provider_adapter`
  - `provider_status`
  - `data_quality`
  - `missing_env_count`
  - `risk_warning`
- Raw provider response and raw credential metadata are not returned to Flutter.

## Limitations

- Adapter is generic JSON, not a provider-specific SDK.
- OHLCV sync is not implemented here.
- Market news provider is not implemented here.
- Full technical indicator computation remains pending until OHLCV is active.
- Responses are educational watchlist context only, not transaction instructions.
