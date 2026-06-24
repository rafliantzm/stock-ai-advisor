# P2 Live Provider Environment Setup Guide

Dokumen ini menjelaskan env vars untuk mengaktifkan live market data provider di Supabase Edge Functions. Semua secret hanya boleh disimpan di Supabase Dashboard, bukan di Flutter, bukan di repository, dan bukan di file `.env` yang masuk Git.

## Where To Configure

Supabase Dashboard:

1. Open project.
2. Go to Edge Functions.
3. Open Secrets / Environment Variables.
4. Add or update variables below.
5. Redeploy:
   - `sync-market-candidates`
   - `get-market-context`

Supabase CLI check:

```bash
supabase secrets list
```

The command should show secret names only. It must not be copied into Flutter config.

## Minimal Sample Mode

Gunakan mode ini untuk fallback baseline.

```text
MARKET_DATA_PROVIDER_MODE=sample
MARKET_DATA_PROVIDER_NAME=sample_provider
MARKET_DATA_CACHE_TTL_SECONDS=900
```

Expected:

- `provider_mode = sample`
- `data_quality = sample`
- `risk_warning` appears

## Live Mode Required Variables

```text
MARKET_DATA_PROVIDER_MODE=live
MARKET_DATA_PROVIDER_ADAPTER=generic_json
MARKET_DATA_PROVIDER_NAME=provider_name
MARKET_DATA_API_BASE_URL=https://provider.example
MARKET_DATA_API_KEY=secret_value
```

Set these as Supabase Edge Function secrets only. Keep `MARKET_DATA_API_KEY` out of Flutter, mobile build config, public docs, and committed files.

Optional:

```text
MARKET_DATA_QUOTES_PATH=/quotes
MARKET_DATA_CONTEXT_PATH=/market-context
MARKET_DATA_API_KEY_HEADER=Authorization
MARKET_DATA_API_KEY_PREFIX=Bearer
MARKET_DATA_CACHE_TTL_SECONDS=900
MARKET_DATA_SYNC_TOKEN=random-long-secret
```

Notes:

- `MARKET_DATA_PROVIDER_MODE=production` is still accepted as a legacy alias for `live`.
- `MARKET_DATA_PROVIDER_ADAPTER` currently supports `generic_json`.
- Unsupported adapter names return fallback with `provider_mode = provider_error`.
- `MARKET_DATA_SYNC_TOKEN` is optional and only used for backend scheduled sync calls.

## Env Vars Reference

| Env | Required | Secret | Description |
| --- | --- | --- | --- |
| `MARKET_DATA_PROVIDER_MODE` | Yes | No | `sample` or `live` |
| `MARKET_DATA_PROVIDER_ADAPTER` | No | No | Default `generic_json` |
| `MARKET_DATA_PROVIDER_NAME` | Yes | No | Provider label stored in cache metadata |
| `MARKET_DATA_API_BASE_URL` | Live only | No, but backend-only | Provider base URL |
| `MARKET_DATA_API_KEY` | Live only | Yes | Provider credential |
| `MARKET_DATA_QUOTES_PATH` | No | No | Quote endpoint path |
| `MARKET_DATA_CONTEXT_PATH` | No | No | Market context endpoint path |
| `MARKET_DATA_API_KEY_HEADER` | No | No | Header name for provider auth |
| `MARKET_DATA_API_KEY_PREFIX` | No | No | Header prefix, default `Bearer` |
| `MARKET_DATA_CACHE_TTL_SECONDS` | No | No | Cache freshness threshold |
| `MARKET_DATA_SYNC_TOKEN` | No | Yes | Optional backend sync token |

## Generic JSON Adapter Contract

The adapter sends POST requests.

Quotes request body:

```json
{
  "symbol_codes": ["BBCA", "TLKM"]
}
```

Quotes response can be:

```json
{
  "quotes": [
    {
      "symbol_code": "BBCA",
      "observed_at": "2026-06-24T02:00:00Z",
      "last_price": 9500,
      "previous_close": 9450,
      "open_price": 9475,
      "high_price": 9550,
      "low_price": 9400,
      "change_value": 50,
      "change_percent": 0.53,
      "volume": 12345600,
      "value_traded": 117000000000,
      "currency": "IDR"
    }
  ]
}
```

Market context request body:

```json
{
  "market_code": "IDX",
  "index_symbol": "IHSG"
}
```

Market context response can be:

```json
{
  "market_context": {
    "market_code": "IDX",
    "index_symbol": "IHSG",
    "observed_at": "2026-06-24T02:00:00Z",
    "index_last": 7200.5,
    "index_change": 15.2,
    "index_change_percent": 0.21,
    "index_trend": "neutral",
    "market_status": "open",
    "risk_regime": "normal"
  }
}
```

## Expected Edge Function Modes

| Scenario | Expected `provider_mode` | Expected `data_quality` |
| --- | --- | --- |
| Sample env | `sample` | `sample` |
| Live env missing key/base URL | `fallback_sample` | `sample` |
| Live env complete and payload valid | `live` | `production` |
| Live env complete but provider unavailable | `provider_error` | `stale` |
| Live env complete but payload missing price/volume | `provider_error` | `stale` |

## Security Checklist

- Do not put `MARKET_DATA_API_KEY` in Flutter.
- Do not put service role key in Flutter.
- Do not commit provider secrets.
- Do not store provider auth headers, cookies, tokens, or credentials in `raw_payload`.
- Do not send raw provider payload to Flutter.
- Use Supabase Edge Functions as the only path to provider access.

## Deploy Commands

Run from project root after updating Edge Function secrets:

```bash
supabase functions deploy sync-market-candidates
supabase functions deploy get-market-context
```

If the project is not linked locally, pass the project ref:

```bash
supabase functions deploy sync-market-candidates --project-ref PROJECT_REF
supabase functions deploy get-market-context --project-ref PROJECT_REF
```

## PowerShell Smoke Tests

Prepare variables:

```powershell
$env:SUPABASE_URL = "https://PROJECT_REF.supabase.co"
$env:USER_JWT = "USER_ACCESS_TOKEN"
```

Test `sync-market-candidates`:

```powershell
$headers = @{
  Authorization = "Bearer $env:USER_JWT"
  "Content-Type" = "application/json"
}

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

Expected safe response:

- `ok = true`
- `data.data_quality` is `sample`, `stale`, or `production`
- `meta.provider_mode` is `sample`, `live`, `fallback_sample`, or `provider_error`
- `risk_warning` appears when data is sample/stale
- no provider secret is returned

Test `get-market-context`:

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

Expected safe response:

- `ok = true`
- `data.market_context.market_code = IDX`
- `data.market_context.risk_warning` appears when data is sample/stale
- disclaimer says the context is educational and not a transaction instruction
- no provider secret is returned

## Operational Notes

- Start with `sample` mode after deploy.
- Switch to `live` mode only after provider terms, rate limits, and payload shape are verified.
- Keep `MARKET_DATA_CACHE_TTL_SECONDS` conservative during early tests.
- If provider rate limit is tight, schedule sync server-side and let Flutter read cached results.
- Treat every live result as informational context for watchlist candidate analysis, not as an instruction to transact.
