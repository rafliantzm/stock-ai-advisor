# P2 Live Market Data Provider Implementation Plan

Dokumen ini menjelaskan fondasi live market data provider untuk `stock-ai-advisor`. Tujuan tahap ini adalah membuat arsitektur provider yang siap disambungkan ke layanan legal/berizin, sambil menjaga `sample_provider` sebagai fallback aman.

## Scope

- Edge Functions yang disentuh:
  - `sync-market-candidates`
  - `get-market-context`
  - `_shared/marketData.ts`
- Flutter tidak menyimpan secret dan tetap membaca data melalui Edge Functions.
- Data tetap digunakan untuk konteks edukatif, watchlist candidate, risk warning, dan invalidation level.
- Tidak ada fitur transaksi saham.

## Provider Mode

Mode yang dikembalikan oleh Edge Functions:

| Mode | Arti | Data Quality |
| --- | --- | --- |
| `sample` | Provider live belum diminta; memakai sample provider | `sample` |
| `live` | Provider live aktif dan payload valid | `live` atau `delayed` |
| `fallback_sample` | Mode live diminta tetapi env belum lengkap; memakai sample provider | `sample` |
| `provider_error` | Env live lengkap tetapi provider gagal/invalid/stale; memakai fallback aman | `stale` |

`MARKET_DATA_PROVIDER_MODE=production` masih diterima sebagai alias lama untuk `live`, agar konfigurasi dari tahap sebelumnya tidak langsung rusak.

## Live Adapter Layer

Adapter dipilih melalui:

```text
MARKET_DATA_PROVIDER_ADAPTER=generic_json
```

Adapter default adalah `generic_json`. Adapter ini mengirim request POST ke path quotes dan market context, lalu menormalkan payload ke kontrak internal.

Adapter juga mendukung `MARKET_DATA_PROVIDER_METHOD=GET` untuk provider yang membutuhkan query string.

Adapter selain `generic_json` belum diaktifkan. Jika env memakai adapter yang belum didukung, function akan turun ke `provider_error` dan memakai fallback aman.

## Expected Generic Provider Payload

Quotes dapat berupa array langsung, atau berada di key `quotes`, `data`, atau `items`.

Contoh:

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

Market context dapat berupa root object, atau berada di key `market_context`, `context`, atau `data`.

Contoh:

```json
{
  "market_context": {
    "market_code": "IDX",
    "index_symbol": "IHSG",
    "observed_at": "2026-06-24T02:00:00Z",
    "index_last": 7200.5,
    "index_change": 15.2,
    "index_change_percent": 0.21,
    "index_trend": "neutral_to_positive",
    "market_status": "open",
    "risk_regime": "normal"
  }
}
```

## Sync Behavior

`sync-market-candidates`:

1. Validasi auth via JWT user atau `MARKET_DATA_SYNC_TOKEN`.
2. Resolve runtime provider.
3. Ensure `provider_sources`.
4. Load symbols dari `symbols`.
5. Jika mode live lengkap, panggil adapter `generic_json`.
6. Normalisasi quote ke `market_price_snapshots`.
7. Tulis technical snapshot:
   - live quote valid: indicator masih fallback stale sampai OHLCV aktif;
   - sample/fallback: indicator sample/stale.
8. Tulis `provider_sync_runs`.
9. Return envelope `{ ok, data, meta }`.

`get-market-context`:

1. Validasi JWT user.
2. Ambil latest context dari cache.
3. Jika kosong dan `create_sample_if_missing=true`, coba live adapter.
4. Jika gagal, buat context sample/stale.
5. Return provider mode, status, cache, risk warning, dan disclaimer edukatif.

## Response Contract

Response tetap kompatibel dengan Flutter P2:

```json
{
  "ok": true,
  "data": {
    "data_quality": "sample | stale | live | delayed",
    "provider_status": "string",
    "risk_warning": []
  },
  "meta": {
    "data_quality": "sample | stale | live | delayed",
    "provider_mode": "sample | live | fallback_sample | provider_error"
  }
}
```

## Security

- Provider key hanya dibaca dari Supabase Edge Function environment.
- Flutter tidak menerima provider key, service role key, raw auth header, cookie, token, atau credential.
- Response hanya memuat metadata aman:
  - provider name;
  - provider mode;
  - provider adapter;
  - provider status;
  - data quality;
  - missing config count.
- Nama env yang hilang tidak dikirim ke Flutter.
- Raw provider payload tidak dikirim ke Flutter.

## Limitations

- Adapter live saat ini generic JSON, belum provider-specific.
- OHLCV live belum di-sync pada endpoint ini.
- Technical indicator masih fallback sampai OHLCV dan compute pipeline aktif.
- Market context live bergantung pada payload provider yang sesuai kontrak.
- `evaluate-watchlist-v2` belum dihubungkan ke cache live.

## Next Step

1. Pasang env live provider di Supabase Dashboard.
2. Deploy ulang `sync-market-candidates` dan `get-market-context`.
3. Jalankan smoke test fallback sample.
4. Jalankan smoke test live provider.
5. Verifikasi row database dan pastikan tidak ada secret tersimpan.
6. Lanjut P2.1: OHLCV live sync dan technical indicator compute.
