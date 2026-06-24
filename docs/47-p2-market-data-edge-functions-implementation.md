# 47. P2 Market Data Edge Functions Implementation

## Scope

Implementasi awal P2 Edge Functions dibuat tanpa mengubah P1, Flutter UI, atau Edge Functions P0.

Functions dibuat:

- `supabase/functions/sync-market-candidates/index.ts`
- `supabase/functions/get-market-context/index.ts`
- `supabase/functions/_shared/marketData.ts`

## Function: sync-market-candidates

Purpose:

- Mengisi cache market data P2 untuk kandidat symbol.
- Membuat/menjaga `provider_sources`.
- Menulis audit ke `provider_sync_runs`.
- Menulis sample quote ke `market_price_snapshots`.
- Menulis sample indicator ke `technical_indicator_snapshots`.
- Opsional menulis sample market context ke `market_context_snapshots`.

Request:

```json
{
  "symbol_codes": ["BBCA", "ASII"],
  "limit": 10,
  "include_market_context": true,
  "run_mode": "manual"
}
```

Response sukses:

```json
{
  "ok": true,
  "data": {
    "sync_run_id": "uuid",
    "provider": {
      "provider_name": "sample_provider",
      "provider_type": "sample",
      "status": "active"
    },
    "synced_symbols": [],
    "synced_count": 0,
    "rows_inserted": 0,
    "data_quality": "sample",
    "provider_status": "provider belum aktif",
    "risk_warning": [
      {
        "level": "medium",
        "message": "Market candidate sync memakai sample data sampai provider production aktif."
      }
    ]
  },
  "meta": {
    "rule_version": "p2_market_data_sample_sync_v1",
    "data_quality": "sample",
    "provider_name": "sample_provider"
  }
}
```

Security:

- Jika `MARKET_DATA_SYNC_TOKEN` diset, request harus memakai header `x-sync-token`.
- Jika token internal belum diset, request harus memakai JWT user Supabase.
- Function memakai service role hanya di backend via environment.
- Secret provider tidak dikembalikan di response.

## Function: get-market-context

Purpose:

- Membaca latest market context dari `market_context_snapshots`.
- Membuat sample context jika belum ada dan `create_sample_if_missing = true`.
- Mengembalikan response edukatif untuk Flutter.

Request:

```json
{
  "market_code": "IDX",
  "index_symbol": "IHSG",
  "allow_stale": true,
  "create_sample_if_missing": true
}
```

Response sukses:

```json
{
  "ok": true,
  "data": {
    "market_context": {
      "market_code": "IDX",
      "index_symbol": "IHSG",
      "market_status": "provider belum aktif",
      "index_trend": "needs_more_data",
      "risk_regime": "needs_more_data",
      "data_quality": "sample",
      "is_stale": true,
      "staleness_warning": "provider belum aktif - sample data"
    }
  },
  "meta": {
    "data_quality": "sample",
    "provider_name": "sample_provider",
    "provider_status": "provider belum aktif"
  }
}
```

Security:

- User-facing endpoint wajib memakai JWT user Supabase.
- Flutter tetap memakai anon key dan JWT user.
- Function tidak mengekspos provider secret.

## Environment Variables

Required existing:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` atau publishable key equivalent
- `SUPABASE_SERVICE_ROLE_KEY`

Optional P2:

- `MARKET_DATA_PROVIDER_NAME`
- `MARKET_DATA_CACHE_TTL_SECONDS`
- `MARKET_DATA_SYNC_TOKEN`

Reserved for future provider integration:

- `MARKET_DATA_API_BASE_URL`
- `MARKET_DATA_API_KEY`
- `MARKET_DATA_TIMEOUT_MS`

## Deploy Via Supabase Dashboard

Deploy function folders:

- `sync-market-candidates`
- `get-market-context`

Pastikan migration `0005_create_market_data_schema.sql` sudah berjalan sebelum deploy/test.

## Smoke Test Payload

`sync-market-candidates`:

```json
{
  "symbol_codes": ["BBCA", "ASII"],
  "limit": 10,
  "include_market_context": true,
  "run_mode": "manual"
}
```

`get-market-context`:

```json
{
  "market_code": "IDX",
  "index_symbol": "IHSG",
  "allow_stale": true,
  "create_sample_if_missing": true
}
```

## Guardrails

- P1 tetap berjalan.
- `p0_dummy_scoring_v1` tidak dihapus.
- AI/RAG belum aktif.
- Market provider production belum aktif.
- Semua data awal diberi label `sample data` atau `provider belum aktif`.
- Tidak ada fitur transaksi saham.
