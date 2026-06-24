# P2 Real Market Data Provider Smoke Test Template

Use this template after configuring provider secrets in Supabase Edge Functions. Do not paste provider key, service role key, or private provider response into this document.

## Environment

| Item | Value |
| --- | --- |
| Date |  |
| Supabase project |  |
| Branch | `p2-real-market-data-provider` |
| Provider name |  |
| Provider adapter | `generic_json` |
| Function `sync-market-candidates` deployed | yes / no |
| Function `get-market-context` deployed | yes / no |

## Secret Verification

Run:

```bash
supabase secrets list
```

Expected secret names:

- `MARKET_DATA_PROVIDER_MODE`
- `MARKET_DATA_PROVIDER`
- `MARKET_DATA_PROVIDER_BASE_URL`
- `MARKET_DATA_PROVIDER_API_KEY`

Legacy alias names may also exist, but Flutter must not contain provider secrets.

Actual:

```text

```

Status: Pass / Fail

## Deploy

```bash
supabase functions deploy sync-market-candidates
supabase functions deploy get-market-context
```

Status: Pass / Fail

## PowerShell Variables

```powershell
$env:SUPABASE_URL = "https://PROJECT_REF.supabase.co"
$env:USER_JWT = "USER_ACCESS_TOKEN"
$headers = @{
  Authorization = "Bearer $env:USER_JWT"
  "Content-Type" = "application/json"
}
```

## Test 1 - Sync Market Candidates

```powershell
$body = @{
  symbol_codes = @("BBCA", "TLKM")
  limit = 10
  include_market_context = $true
  run_mode = "manual"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "$env:SUPABASE_URL/functions/v1/sync-market-candidates" `
  -Headers $headers `
  -Body $body
```

Expected valid live result:

- `ok = true`
- `data.data_quality = live` or `delayed`
- `meta.provider_mode = live`
- `risk_warning` is empty or low-noise
- rows are written to `market_price_snapshots`

Expected fallback result:

- `ok = true`
- `data.data_quality = stale` or `sample`
- `meta.provider_mode = provider_error` or `fallback_sample`
- `risk_warning` explains fallback state

Actual:

Status: PASS

Actual Result:
- sync-market-candidates returned ok true.
- get-market-context returned ok true.
- sync-market-candidates provider_mode: provider_error.
- sync-market-candidates data_quality: stale.
- sync-market-candidates provider_status: provider live error - fallback sample aktif.
- get-market-context provider_mode: provider_error.
- get-market-context data_quality: stale.
- get-market-context provider_status: provider live belum mengembalikan data valid - fallback cache aktif.
- fallback_status: active.
- provider_sync_runs: 7 rows.
- market_price_snapshots: 35 rows.
- ohlcv_bars: 0 rows.
- technical_indicator_snapshots: 35 rows.
- market_context_snapshots: 7 rows.
- news_items: 0 rows.
- Provider secrets remain handled in Supabase Edge Functions.
- Flutter does not expose service role key or provider secret.

Conclusion:
The real market data provider adapter is structurally working, but live production data is not active yet. The system safely falls back to stale/sample data with clear provider_error metadata and risk warnings.

## Test 2 - Get Market Context

```powershell
$body = @{
  market_code = "IDX"
  index_symbol = "IHSG"
  allow_stale = $true
  create_sample_if_missing = $true
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "$env:SUPABASE_URL/functions/v1/get-market-context" `
  -Headers $headers `
  -Body $body
```

Expected valid live result:

- `ok = true`
- `data.market_context.data_quality = live` or `delayed`
- `data.provider.data_quality` matches `data.market_context.data_quality`
- `meta.provider_mode = live`

Expected fallback result:

- `ok = true`
- `data.market_context.data_quality = stale` or `sample`
- `data.provider.data_quality` matches `data.market_context.data_quality`
- `meta.provider_mode = provider_error`, `fallback_sample`, or `sample`
- disclaimer remains educational

Actual:

```text

```

Status: Pass / Fail

## Database Verification

Run in Supabase SQL Editor:

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
  metadata ->> 'provider_mode' as provider_mode,
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
  open_price,
  high_price,
  low_price,
  volume,
  data_quality,
  is_stale,
  observed_at
from public.market_price_snapshots
order by created_at desc
limit 20;
```

```sql
select
  market_code,
  index_symbol,
  provider_name,
  index_last,
  index_change_percent,
  data_quality,
  is_stale,
  observed_at
from public.market_context_snapshots
order by created_at desc
limit 10;
```

Expected:

- Data rows appear after successful sync.
- `raw_payload` and metadata contain no provider credential.
- Stale/sample fallback is clearly marked when live provider is not usable.

Status: Pass / Fail

## Secret Exposure Check

```bash
rg -n "SERVICE_ROLE|SERVICE_ROLE_KEY|MARKET_DATA_PROVIDER_API_KEY|MARKET_DATA_API_KEY|MARKET_DATA_SYNC_TOKEN" apps/mobile/lib apps/mobile/test
```

Expected:

- No results in Flutter source or tests.
- Provider credential exists only in Supabase Edge Function secrets.

Status: Pass / Fail

## Final Result

Overall status: Pass / Fail

Known limitations:

```text

```

Next step:

```text

```
