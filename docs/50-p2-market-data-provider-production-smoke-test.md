# P2 Market Data Provider Production Smoke Test

Dokumen ini berisi test notes untuk fondasi production provider market data. Test fokus pada fallback aman, response contract, verifikasi database, dan keamanan secret.

## Environment

Isi placeholder berikut sebelum menjalankan test:

```bash
export SUPABASE_URL="https://PROJECT_REF.supabase.co"
export USER_JWT="USER_ACCESS_TOKEN"
```

Untuk test scheduled sync opsional:

```bash
export MARKET_DATA_SYNC_TOKEN="SYNC_TOKEN_FROM_EDGE_ENV"
```

Jangan memasukkan provider API key, service role key, atau secret backend ke Flutter atau file repository.

## Test 1 - `get-market-context` Fallback Sample

Tujuan:

- Memastikan endpoint tetap berjalan saat provider production belum aktif.
- Memastikan response memakai envelope standar.
- Memastikan `risk_warning` muncul saat data sample/stale.

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/get-market-context" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"market_code":"IDX","index_symbol":"IHSG","allow_stale":true,"create_sample_if_missing":true}'
```

Expected result:

```json
{
  "ok": true,
  "data": {
    "market_context": {
      "market_code": "IDX",
      "index_symbol": "IHSG",
      "data_quality": "sample",
      "provider_status": "provider belum aktif - memakai sample provider",
      "risk_warning": [
        {
          "level": "medium",
          "message": "Data masih sample; gunakan hanya untuk observasi watchlist candidate."
        }
      ]
    },
    "provider": {
      "provider_name": "sample_provider",
      "provider_mode": "sample"
    }
  },
  "meta": {
    "data_quality": "sample",
    "provider_mode": "sample"
  }
}
```

Pass criteria:

- HTTP 200.
- `ok = true`.
- `data.market_context.data_quality` adalah `sample` atau `stale`.
- Tidak ada secret di response.

## Test 2 - `sync-market-candidates` Fallback Sample

Tujuan:

- Memastikan sync market candidate tetap menghasilkan cache edukatif.
- Memastikan `provider_sync_runs` terisi.
- Memastikan Flutter tetap bisa membaca status sample/stale.

Command dengan JWT user:

```bash
curl -i "$SUPABASE_URL/functions/v1/sync-market-candidates" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"symbol_codes":["BBCA","TLKM"],"limit":10,"include_market_context":true,"run_mode":"manual"}'
```

Command dengan sync token opsional:

```bash
curl -i "$SUPABASE_URL/functions/v1/sync-market-candidates" \
  -H "x-sync-token: $MARKET_DATA_SYNC_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"symbol_codes":["BBCA","TLKM"],"limit":10,"include_market_context":true,"run_mode":"scheduled"}'
```

Expected result:

```json
{
  "ok": true,
  "data": {
    "provider": {
      "provider_name": "sample_provider",
      "provider_mode": "sample"
    },
    "synced_symbols": [
      {
        "symbol_code": "BBCA"
      }
    ],
    "data_quality": "sample",
    "provider_status": "provider belum aktif - memakai sample provider",
    "risk_warning": [
      {
        "level": "medium"
      }
    ]
  },
  "meta": {
    "rule_version": "p2_market_data_provider_sync_v1",
    "data_quality": "sample"
  }
}
```

Pass criteria:

- HTTP 200.
- `ok = true`.
- `synced_symbols` berisi symbol aktif yang diminta.
- `data_quality` adalah `sample`, `stale`, atau `production`.
- `risk_warning` muncul jika quality bukan `production`.
- Tidak ada provider API key atau service role key di response.

## Test 3 - Missing Live Provider Env Behavior

Setup di Supabase Edge Function environment:

```text
MARKET_DATA_PROVIDER_MODE=live
MARKET_DATA_PROVIDER_NAME=example_provider
```

Jangan isi `MARKET_DATA_API_BASE_URL` dan `MARKET_DATA_API_KEY` untuk test ini.

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/sync-market-candidates" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"symbol_codes":["BBCA"],"include_market_context":true,"run_mode":"manual"}'
```

Expected result:

```json
{
  "ok": true,
  "data": {
    "data_quality": "sample",
    "provider_status": "provider live belum lengkap - fallback sample provider",
    "risk_warning": [
      {
        "level": "high"
      }
    ]
  },
  "meta": {
    "provider_mode": "fallback_sample"
  }
}
```

Pass criteria:

- Endpoint tidak gagal hanya karena provider env belum lengkap.
- Response menjelaskan fallback.
- Missing env name boleh tampil, tetapi nilai secret tidak boleh tampil.

## Test 4 - Live Provider Configured

Setup minimal di Supabase Edge Function environment:

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
  --data '{"symbol_codes":["BBCA"],"include_market_context":true,"run_mode":"manual"}'
```

Expected result jika provider sandbox mengembalikan payload valid:

```json
{
  "ok": true,
  "data": {
    "provider": {
      "provider_name": "provider_name",
      "provider_mode": "live"
    },
    "data_quality": "production",
    "provider_status": "provider live aktif melalui Edge Function",
    "risk_warning": []
  }
}
```

Expected result jika provider tidak tersedia atau payload belum sesuai:

```json
{
  "ok": true,
  "data": {
    "data_quality": "stale",
    "provider_status": "provider live error - fallback sample aktif",
    "risk_warning": [
      {
        "level": "high"
      }
    ]
  }
}
```

Pass criteria:

- Secret tidak muncul di response atau `provider_sync_runs.metadata`.
- Fallback tetap menghasilkan response sukses yang aman.
- User melihat state sample/stale/production dan provider mode dengan jelas.

## Test 5 - Database Row Verification

Jalankan di Supabase SQL Editor.

Provider sources:

```sql
select
  provider_name,
  provider_type,
  supports_quotes,
  supports_market_context,
  status,
  cache_ttl_seconds,
  notes
from public.provider_sources
order by created_at desc
limit 10;
```

Sync runs:

```sql
select
  provider_name,
  sync_type,
  run_mode,
  status,
  rows_requested,
  rows_inserted,
  rows_failed,
  metadata -> 'provider' as provider_meta,
  metadata ->> 'data_quality' as data_quality,
  metadata ->> 'provider_status' as provider_status,
  metadata ->> 'provider_mode' as provider_mode,
  metadata ->> 'used_live_adapter' as used_live_adapter,
  created_at
from public.provider_sync_runs
order by created_at desc
limit 10;
```

Price snapshots:

```sql
select
  symbol_code,
  provider_name,
  last_price,
  change_percent,
  data_quality,
  is_stale,
  staleness_warning,
  observed_at
from public.market_price_snapshots
order by created_at desc
limit 10;
```

Market context:

```sql
select
  market_code,
  index_symbol,
  provider_name,
  market_status,
  data_quality,
  is_stale,
  staleness_warning,
  observed_at
from public.market_context_snapshots
order by created_at desc
limit 10;
```

Pass criteria:

- Rows baru muncul setelah sync.
- `data_quality` DB memakai nilai yang kompatibel dengan migration P2 awal.
- Tidak ada API key, auth header, cookie, token, atau credential di `metadata`, `raw_payload`, atau `context_payload`.

## Test 6 - No Secret Exposure to Flutter

Checklist manual:

- Cari di repo Flutter:

```bash
rg -n "SERVICE_ROLE|SERVICE_ROLE_KEY|MARKET_DATA_API_KEY|MARKET_DATA_SYNC_TOKEN|API_KEY" apps/mobile lib test
```

Expected:

- Tidak ada service role key.
- Tidak ada provider secret.
- Flutter hanya memakai Supabase anon config dan JWT user.

Checklist response:

```bash
curl -s "$SUPABASE_URL/functions/v1/get-market-context" \
  -H "Authorization: Bearer $USER_JWT" \
  -H "Content-Type: application/json" \
  --data '{"create_sample_if_missing":true}' | jq
```

Expected:

- Response hanya memuat metadata aman.
- Tidak ada value provider secret.

## Test 7 - Invalid Auth

Command:

```bash
curl -i "$SUPABASE_URL/functions/v1/get-market-context" \
  -H "Content-Type: application/json" \
  --data '{"market_code":"IDX"}'
```

Expected:

```json
{
  "ok": false,
  "error": {
    "code": "unauthorized"
  }
}
```

Pass criteria:

- HTTP 401.
- Tidak ada data market yang dikirim tanpa JWT user.

## Final Acceptance

P2 provider production foundation dianggap lulus smoke test jika:

- `sync-market-candidates` sukses di mode sample/fallback.
- `get-market-context` sukses di mode sample/fallback.
- Missing env tidak membuat endpoint crash.
- Live env lengkap bisa mencoba adapter provider.
- Fallback stale tetap aman saat provider gagal.
- Database rows terisi tanpa secret.
- Flutter tidak menyimpan service role key atau provider secret.
- Wording response tetap edukatif: watchlist candidate, layak dianalisis, risk warning, invalidation level, sample data, provider belum aktif.
