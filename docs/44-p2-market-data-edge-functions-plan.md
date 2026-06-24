# 44. P2 Market Data Edge Functions Plan

Dokumen ini merancang Edge Functions P2. Implementasi awal sudah dimulai untuk `sync-market-candidates` dan `get-market-context`.

## Tujuan

Edge Functions P2 menjadi satu-satunya jalur untuk:

- membaca provider eksternal;
- menyimpan cache market data;
- membaca quote dan market context untuk Flutter;
- menghitung technical indicators;
- mengevaluasi watchlist dengan Rule Engine P2.

Flutter tetap hanya memakai anon key dan JWT user.

## Shared Rules

Semua function:

- menerima JSON request;
- membaca JWT user jika endpoint dipakai Flutter;
- tidak mengekspos provider API key;
- memakai CORS handling existing;
- mengembalikan response standar:

```json
{
  "ok": true,
  "data": {},
  "meta": {
    "data_quality": "sample",
    "provider_status": "provider belum aktif"
  }
}
```

Error response:

```json
{
  "ok": false,
  "error": {
    "code": "validation_error",
    "message": "symbol_code is required",
    "details": null
  }
}
```

Wording response harus edukatif:

- `watchlist candidate`
- `layak dianalisis`
- `risk warning`
- `invalidation level`
- `sample data`
- `provider belum aktif`

## Environment Variables

Edge Functions boleh memakai:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY` hanya di backend Edge Functions
- `MARKET_DATA_PROVIDER_NAME`
- `MARKET_DATA_API_BASE_URL`
- `MARKET_DATA_API_KEY`
- `MARKET_DATA_TIMEOUT_MS`
- `MARKET_DATA_CACHE_TTL_SECONDS`

Flutter tidak boleh memakai service role key atau provider API key.

## Function: get-stock-quote

Purpose:

- Flutter membaca quote saham melalui backend.
- Function membaca cache `market_quotes`.
- Jika cache stale, function dapat mengembalikan stale warning atau trigger sync sesuai policy.

Request:

```json
{
  "symbol_code": "BBCA",
  "allow_stale": true
}
```

Response data:

```json
{
  "symbol": {
    "symbol_code": "BBCA",
    "company_name": "Bank Central Asia Tbk"
  },
  "quote": {
    "last_price": 0,
    "change_percent": 0,
    "volume": 0,
    "quote_timestamp": "timestamp",
    "data_quality": "sample",
    "is_stale": true,
    "staleness_warning": "provider belum aktif"
  }
}
```

Validation:

- `symbol_code` required.
- Symbol harus ada di `symbols`.

Cache:

- Cek latest row by `symbol_id`.
- Jika tidak ada data, response boleh `not_found` atau `provider belum aktif` sesuai mode development.

## Function: get-market-context

Purpose:

- Flutter membaca Market Context/IHSG.
- Mengganti placeholder P1 secara bertahap.
- Implementasi awal tersedia di `supabase/functions/get-market-context/index.ts`.

Request:

```json
{
  "market_code": "IDX",
  "index_symbol": "IHSG",
  "allow_stale": true
}
```

Response data:

```json
{
  "market_context": {
    "market_status": "provider belum aktif",
    "index_trend": "needs_more_data",
    "risk_regime": "needs_more_data",
    "last_updated": "timestamp",
    "data_quality": "sample",
    "is_stale": true
  }
}
```

Validation:

- Default `market_code = IDX`.
- Default `index_symbol = IHSG`.

Cache:

- Ambil latest `market_context_snapshots`.
- Return stale warning jika cache melewati TTL.

## Function: sync-stock-quote

Purpose:

- Backend sync quote dari provider ke `market_quotes`.
- Dipanggil scheduler/admin flow, bukan langsung dari UI umum.

Request:

```json
{
  "symbol_codes": ["BBCA", "BBRI"],
  "provider_name": "sample_provider",
  "force": false
}
```

Response data:

```json
{
  "synced_count": 0,
  "skipped_count": 0,
  "failed_count": 0,
  "sync_log_id": "uuid"
}
```

Security:

- Wajib backend-only.
- Jika dipanggil manual, batasi pada user admin atau service job.
- Provider API key hanya dibaca dari environment.

Provider flow:

1. Validate symbols.
2. Check TTL unless `force = true`.
3. Fetch provider.
4. Normalize payload.
5. Upsert `market_quotes`.
6. Insert `provider_sync_logs`.

## Function: sync-ohlcv-candles

Purpose:

- Sync OHLCV candles ke `ohlcv_candles`.

Request:

```json
{
  "symbol_code": "BBCA",
  "timeframe": "1d",
  "from": "2026-01-01",
  "to": "2026-06-24",
  "force": false
}
```

Response data:

```json
{
  "symbol_code": "BBCA",
  "timeframe": "1d",
  "rows_inserted": 0,
  "rows_updated": 0,
  "sync_log_id": "uuid"
}
```

Validation:

- `symbol_code` required.
- `timeframe` allowlist awal: `1d`.
- Date range wajib dibatasi agar tidak boros request.

Cache:

- Unique by `(symbol_id, timeframe, candle_time, provider_name)`.

## Function: compute-technical-indicators

Purpose:

- Menghitung indikator teknikal dari `ohlcv_candles`.
- Menyimpan hasil ke `technical_indicators`.

Request:

```json
{
  "symbol_code": "BBCA",
  "timeframe": "1d",
  "rule_version": "p2_indicator_v1"
}
```

Response data:

```json
{
  "symbol_code": "BBCA",
  "timeframe": "1d",
  "rule_version": "p2_indicator_v1",
  "computed_at": "timestamp",
  "indicator_summary": {
    "technical_score": 0,
    "risk_score": 0,
    "invalidation_level": 0
  }
}
```

Validation:

- OHLCV minimum candle count harus cukup.
- Jika data kurang, return `needs_more_data`.

Computation awal:

- EMA 20/50/200.
- RSI 14.
- ATR 14.
- average volume 20.
- volume ratio.
- simple support/resistance.

## Function: evaluate-watchlist-v2

Purpose:

- Mengevaluasi watchlist memakai market data dan indicators P2.
- Tidak menghapus `evaluate-watchlist` P0.
- Tidak menghapus `p0_dummy_scoring_v1`.

Request:

```json
{
  "watchlist_id": "uuid",
  "allow_stale": true
}
```

Response data:

```json
{
  "watchlist": {},
  "evaluated_count": 0,
  "rule_version": "p2_market_scoring_v1",
  "results": [
    {
      "watchlist_item_id": "uuid",
      "symbol_code": "BBCA",
      "candidate_label": "watchlist candidate",
      "technical_setup": "needs_more_data",
      "risk_warning": [
        {
          "level": "medium",
          "message": "Data provider belum aktif atau stale."
        }
      ],
      "invalidation_level": 0,
      "scores": {
        "technical_score": 0,
        "harmony_score": 0,
        "fundamental_score": 0,
        "risk_score": 0,
        "liquidity_score": 0,
        "final_score": 0
      }
    }
  ]
}
```

Security:

- User hanya boleh mengevaluasi watchlist miliknya.
- Gunakan profile/auth mapping existing.
- Semua writes ke `watchlist_scores` dilakukan backend.

Scoring source:

- `market_quotes`
- `ohlcv_candles`
- `technical_indicators`
- `market_context_snapshots`
- future fundamental data jika sudah tersedia

Fallback:

- Jika data kurang, return `needs_more_data`.
- Jika provider belum aktif, return risk warning dan jangan memalsukan data.

## Caching Dan Rate Limit

Edge Function harus:

- cek TTL sebelum request provider;
- dedupe request symbol yang sama;
- log setiap sync ke `provider_sync_logs`;
- return stale cache jika provider error dan user mengizinkan `allow_stale`;
- tidak retry agresif dari client.

## Flutter Integration Plan

P2 Flutter nanti:

1. `MarketContextScreen` memanggil `get-market-context`.
2. `StockDetailScreen` memanggil `get-stock-quote`.
3. `ChartLabScreen` menunggu endpoint chart data setelah OHLCV siap.
4. Watchlist menambah tombol atau mode `Evaluate V2` hanya setelah P2 stabil.
5. UI tetap menampilkan label `sample data`, `provider belum aktif`, atau `needs_more_data` jika data belum lengkap.

## Testing Plan

Test awal:

- tanpa token menghasilkan `unauthorized` untuk endpoint user-facing;
- symbol tidak ditemukan menghasilkan `not_found`;
- provider belum aktif menghasilkan response aman;
- stale cache menghasilkan `risk warning`;
- watchlist user lain ditolak;
- API key tidak muncul di response/error;
- `evaluate-watchlist-v2` tidak merusak hasil P0.

## Initial Function: sync-market-candidates

Purpose:

- Mengisi cache P2 awal untuk symbol kandidat.
- Menulis sample/normalized quote ke `market_price_snapshots`.
- Menulis sample technical indicator snapshot ke `technical_indicator_snapshots`.
- Opsional menulis sample market context ke `market_context_snapshots`.
- Mencatat audit ke `provider_sync_runs`.

Request:

```json
{
  "symbol_codes": ["BBCA", "ASII"],
  "limit": 10,
  "include_market_context": true,
  "run_mode": "manual"
}
```

Security:

- Jika `MARKET_DATA_SYNC_TOKEN` tersedia, caller harus mengirim header `x-sync-token`.
- Jika `MARKET_DATA_SYNC_TOKEN` belum diset, function fallback ke Supabase Auth JWT.
- Provider secret tetap hanya di Edge Function environment.

Status:

- Implementasi awal tersedia di `supabase/functions/sync-market-candidates/index.ts`.
- Mode awal memakai `sample data` dan label `provider belum aktif`.

## Disclaimer

Semua data dan score P2 hanya untuk edukasi. Quote, OHLCV, technical indicators, market context, watchlist candidate, risk warning, dan invalidation level bukan instruksi transaksi dan tidak menjamin hasil.
