# P2 Real Market Data Provider Smoke Test Template

Use this template after configuring provider secrets in Supabase Edge Functions. Do not paste provider key, service role key, or private provider response into this document.

## Environment

| Item | Value |
| --- | --- |
| Date |  |
| Supabase project |  |
| Branch | `p2-real-market-data-provider` |
| Provider name | `alpha_vantage` or `generic_json` |
| Provider adapter | `alpha_vantage` or `generic_json` |
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

Alpha Vantage setup example:

```text
MARKET_DATA_PROVIDER_MODE=live
MARKET_DATA_PROVIDER=alpha_vantage
MARKET_DATA_PROVIDER_BASE_URL=https://www.alphavantage.co/query
MARKET_DATA_PROVIDER_API_KEY=<set only in Supabase Edge Function secrets>
```

Optional Alpha Vantage settings:

- `MARKET_DATA_ALPHA_VANTAGE_SYMBOL_SUFFIX=.JK` for IDX suffix retry.
- `MARKET_DATA_ALPHA_VANTAGE_SYMBOL_MAP={"BBCA":"BBCA.JK"}` for explicit provider symbol overrides.
- Example IDX override coverage map:
  `{"ASII":"ASII.JK","BBCA":"BBCA.JK","BBRI":"BBRI.JK","TLKM":"TLKM.JK","UNVR":"UNVR.JK"}`
- `MARKET_DATA_ALPHA_VANTAGE_INDEX_SYMBOL=IHSG` or a provider-supported index symbol.
- `MARKET_DATA_ALPHA_VANTAGE_FETCH_DAILY=true` to request latest daily OHLCV bars.
- `MARKET_DATA_ALPHA_VANTAGE_STALE_DAYS=7` to control delayed daily data staleness.

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
- `data.ohlcv_bars_inserted` is greater than 0 only when provider returns complete OHLC fields
- `risk_warning` is empty or low-noise
- rows are written to `market_price_snapshots`

Expected fallback result:

- `ok = true`
- `data.data_quality = stale` or `sample`
- `meta.provider_mode = provider_error` or `fallback_sample`
- `risk_warning` explains fallback state
- when `meta.provider_mode = provider_error`, `meta.provider_diagnostics` may include safe diagnostics:
  - `provider_configured`
  - `provider_host`
  - `requested_symbol_count`
  - `provider_http_status`
  - `provider_status_code`
  - `provider_content_type`
  - `json_top_level_keys`
  - `provider_response_keys`
  - `symbol_diagnostics`
  - `fallback_reason`
- diagnostics must not include API key, Authorization header, JWT, service role key, full URL, or raw provider response

Safe symbol diagnostics may include:

- `requested_symbol`
- `attempted_provider_symbols`
- `selected_provider_symbol`
- `fallback_reason`

Symbol candidate order:

1. Original internal symbol, for example `BBCA`.
2. IDX suffix variant, for example `BBCA.JK`.
3. Configured override value from `MARKET_DATA_ALPHA_VANTAGE_SYMBOL_MAP` when available.

Alpha Vantage fallback examples:

- `fallback_reason = alpha_vantage_information_response` when provider returns a top-level `Information` response.
- `fallback_reason = alpha_vantage_rate_limited` when provider returns a top-level `Note` response.
- `fallback_reason = alpha_vantage_invalid_symbol` when provider returns a top-level `Error Message` response after symbol variants are attempted.
- `fallback_reason = alpha_vantage_quote_missing` when `Global Quote` is empty.
- `fallback_reason = provider_invalid_json` when the response is not valid JSON.
- When `Information` or `Note` appears for one symbol, the sync should stop extra Alpha Vantage calls for the remaining symbols in that run and use stale/sample fallback safely.

Actual:

Status: PASS - provider information response handled safely

Actual result:
- sync-market-candidates returned ok true.
- provider_name: alpha_vantage.
- provider_host: www.alphavantage.co.
- provider_http_status: 200.
- provider_response_keys: Information.
- fallback_reason: alpha_vantage_information_response.
- live_symbol_count: 1.
- live_symbols: ASII.
- fallback_symbol_count: 4.
- fallback_symbols: BBCA, BBRI, TLKM, UNVR.
- data_quality remains stale because fallback symbols still exist.
- No duplicate key error occurred.
- No provider API key, JWT token, service role key, or raw provider response is exposed.

Conclusion:
Alpha Vantage credential activation is partially successful. The provider is reachable and returns valid JSON, but not all IDX symbols are mapped into complete live data yet. The system safely falls back to stale/sample data for incomplete symbols.

Rate-limit/provider-message handling:

- Top-level `Information` is treated as `alpha_vantage_information_response`.
- Top-level `Note` is treated as `alpha_vantage_rate_limited`.
- Top-level `Error Message` is treated as `alpha_vantage_invalid_symbol`.
- If all configured variants fail for a symbol, mark it as `alpha_vantage_invalid_symbol` or quote-missing provider limitation, not a database failure.
- Diagnostics include only safe metadata such as `provider_response_keys`, HTTP status, content type, host, and fallback reason.
- Raw provider response and credentials must not be pasted into this report.

## Test 2 - Get Market Context

get-market-context:
- returned ok true.
- provider_name: sample_provider.
- requested_provider_name: alpha_vantage.
- provider_mode: provider_error.
- data_quality: stale.
- index_last: null.
- provider_status: provider live belum mengembalikan data valid - fallback cache aktif.
- disclaimer is present.
- IHSG context remains fallback/stale because live index data is not available yet.

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
- when `meta.provider_mode = provider_error`, `meta.provider_diagnostics` may include safe diagnostics only
- disclaimer remains educational

For Alpha Vantage market context, live data requires the configured index symbol to be supported by the provider. If not supported, fallback stale/sample context is expected and safe.

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
- `ohlcv_bars` may remain empty when provider does not include complete OHLC fields.
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
