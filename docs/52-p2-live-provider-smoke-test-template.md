# P2 Live Provider Smoke Test Template

Gunakan dokumen ini untuk mencatat hasil smoke test setelah Edge Functions live provider dideploy.

## Test Environment

| Item | Value |
| --- | --- |
| Date |  |
| Supabase project |  |
| Branch deployed | `p2-market-data-live-provider` |
| Function: `sync-market-candidates` | deployed / not deployed |
| Function: `get-market-context` | deployed / not deployed |
| Provider mode | sample / live / fallback_sample / provider_error |
| Provider adapter | generic_json |
| Tester |  |

## Required Local Variables

```bash
export SUPABASE_URL="https://PROJECT_REF.supabase.co"
export USER_JWT="USER_ACCESS_TOKEN"
```

Optional scheduled sync token:

```bash
export MARKET_DATA_SYNC_TOKEN="SYNC_TOKEN_FROM_EDGE_ENV"
```

Do not place provider secret or service role key in local Flutter env.

## Test 1 - Sample Mode Baseline

Supabase Edge Function env:

```text
MARKET_DATA_PROVIDER_MODE=sample
MARKET_DATA_PROVIDER_NAME=sample_provider
```

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/sync-market-candidates" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"symbol_codes":["BBCA","TLKM"],"limit":10,"include_market_context":true,"run_mode":"manual"}'
```

Expected:

- HTTP 200.
- `ok = true`.
- `data.data_quality = sample`.
- `meta.provider_mode = sample`.
- `risk_warning` is present.

Actual:

```text

```

Status: Pass / Fail

Notes:

```text

```

## Test 2 - Missing Live Env Fallback

Supabase Edge Function env:

```text
MARKET_DATA_PROVIDER_MODE=live
MARKET_DATA_PROVIDER_NAME=example_provider
```

Do not set `MARKET_DATA_API_BASE_URL` or `MARKET_DATA_API_KEY` for this test.

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/sync-market-candidates" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"symbol_codes":["BBCA"],"include_market_context":true,"run_mode":"manual"}'
```

Expected:

- HTTP 200.
- `ok = true`.
- `data.data_quality = sample`.
- `meta.provider_mode = fallback_sample`.
- `provider_status` explains fallback sample.
- No secret value appears in response.

Actual:

```text

```

Status: Pass / Fail

## Test 3 - Live Provider Quote Sync

Supabase Edge Function env:

```text
MARKET_DATA_PROVIDER_MODE=live
MARKET_DATA_PROVIDER_ADAPTER=generic_json
MARKET_DATA_PROVIDER_NAME=provider_name
MARKET_DATA_API_BASE_URL=https://provider.example
MARKET_DATA_API_KEY=secret_value
MARKET_DATA_QUOTES_PATH=/quotes
MARKET_DATA_CONTEXT_PATH=/market-context
```

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/sync-market-candidates" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"symbol_codes":["BBCA","BBRI"],"include_market_context":true,"run_mode":"manual"}'
```

Expected when provider payload is valid:

- HTTP 200.
- `ok = true`.
- `data.data_quality = production` or `stale` if some payload is stale.
- `meta.provider_mode = live` or `provider_error` if fallback was needed.
- `market_price_snapshots` receives rows.
- `provider_sync_runs.status = success`.

Actual:

```text

```

Status: Pass / Fail

## Test 4 - Live Market Context

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/get-market-context" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"market_code":"IDX","index_symbol":"IHSG","allow_stale":true,"create_sample_if_missing":true}'
```

Expected:

- HTTP 200.
- `ok = true`.
- `data.market_context` exists.
- `meta.provider_mode` is one of:
  - `live`
  - `fallback_sample`
  - `provider_error`
  - `sample`
- `risk_warning` appears when `data_quality` is not `production`.

Actual:

```text

```

Status: Pass / Fail

## Test 5 - Database Verification

Run in Supabase SQL Editor.

```sql
select
  provider_name,
  provider_type,
  supports_quotes,
  supports_market_context,
  status,
  cache_ttl_seconds,
  created_at
from public.provider_sources
order by created_at desc
limit 10;
```

```sql
select
  provider_name,
  sync_type,
  run_mode,
  status,
  rows_requested,
  rows_inserted,
  rows_failed,
  metadata ->> 'data_quality' as data_quality,
  metadata ->> 'provider_status' as provider_status,
  metadata ->> 'provider_mode' as provider_mode,
  metadata ->> 'used_live_adapter' as used_live_adapter,
  created_at
from public.provider_sync_runs
order by created_at desc
limit 10;
```

```sql
select
  symbol_code,
  provider_name,
  last_price,
  previous_close,
  change_percent,
  volume,
  data_quality,
  is_stale,
  observed_at
from public.market_price_snapshots
order by created_at desc
limit 20;
```

Expected:

- Rows are created after sync.
- No secret exists in `metadata`, `raw_payload`, or `context_payload`.
- DB `data_quality` remains compatible with existing constraints.

Actual:

```text

```

Status: Pass / Fail

## Test 6 - Secret Exposure Check

Repo check:

```bash
rg -n "SERVICE_ROLE|SERVICE_ROLE_KEY|MARKET_DATA_API_KEY|MARKET_DATA_SYNC_TOKEN" apps/mobile/lib apps/mobile/test
```

Response check:

```bash
curl -s "$SUPABASE_URL/functions/v1/get-market-context" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"create_sample_if_missing":true}'
```

Expected:

- No provider secret in Flutter.
- No service role key in Flutter.
- Edge Function response contains safe metadata only.

Actual:

```text

P2 Live Provider Smoke Test Result

Status: PASS

Actual Result:
- sync-market-candidates returned ok true.
- get-market-context returned ok true.
- provider_sources: 1 row.
- provider_sync_runs: 3 rows.
- market_price_snapshots: 15 rows.
- technical_indicator_snapshots: 15 rows.
- market_context_snapshots: 3 rows.
- news_items: 0 rows, expected because news provider is not active yet.
- sync-market-candidates provider_mode: sample.
- sync-market-candidates data_quality: sample.
- get-market-context provider_mode: sample.
- get-market-context data_quality: stale.
- get-market-context is_stale: true.
- Provider production/live mode is not active yet.
- Provider secrets remain handled through Supabase Edge Function environment.
- Flutter client does not expose service role key or provider secret.

Conclusion:
P2 live provider foundation is working correctly with sample-provider fallback. The Edge Functions deploy successfully, API calls return ok true, database write flow is verified, and stale/sample state is clearly exposed for educational/non-real-time usage.

```

Status: Pass / Fail

## Final Result

Overall status: Pass / Fail

Known limitations:

```text

```

Next step:

```text

```
