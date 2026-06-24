# P2 Market Data Provider Production Plan

Dokumen ini menjelaskan fondasi production-ready untuk market data provider di `stock-ai-advisor`. Scope tahap ini adalah arsitektur provider, kontrak normalisasi, fallback aman, dan response Edge Functions yang konsisten. Tahap ini tidak mengaktifkan AI/RAG, tidak mengubah Flutter flow P1/P2, dan tidak menambahkan fitur transaksi saham.

## Tujuan

- Mengubah P2 market data dari sample-only menjadi provider architecture yang siap disambungkan ke provider production.
- Menjaga `sample_provider` sebagai fallback agar Flutter tetap stabil saat env provider belum lengkap atau provider gagal merespons.
- Menormalkan output provider sebelum disimpan atau dikirim ke Flutter.
- Menjaga provider secret hanya di Supabase Edge Function environment variables.
- Menampilkan `data_quality`, `provider_status`, dan `risk_warning` agar user paham apakah data production, stale, atau sample.

## Batasan

- Flutter hanya memakai `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan JWT user.
- Provider key, service role key, endpoint internal, dan raw sensitive payload tidak boleh dikirim ke Flutter.
- Edge Functions tetap memakai response envelope:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

- `data_quality` response Edge Function hanya:
  - `sample`
  - `stale`
  - `production`
- Nilai database tetap kompatibel dengan migration P2 awal. Data production disimpan sebagai nilai DB yang sudah tersedia, lalu dinormalisasi kembali menjadi `production` di response.

## Provider Runtime

Provider runtime dibaca di `supabase/functions/_shared/marketData.ts`.

Env yang digunakan:

| Env | Fungsi | Aman untuk Flutter |
| --- | --- | --- |
| `MARKET_DATA_PROVIDER_MODE` | `sample` atau `production` | Tidak |
| `MARKET_DATA_PROVIDER_NAME` | Nama provider aktif | Boleh tampil sebagai metadata non-secret |
| `MARKET_DATA_API_BASE_URL` | Base URL provider | Tidak |
| `MARKET_DATA_API_KEY` | Secret provider | Tidak |
| `MARKET_DATA_API_KEY_HEADER` | Nama header auth provider | Tidak |
| `MARKET_DATA_API_KEY_PREFIX` | Prefix header auth provider | Tidak |
| `MARKET_DATA_QUOTES_PATH` | Path quote provider | Tidak |
| `MARKET_DATA_CONTEXT_PATH` | Path market context provider | Tidak |
| `MARKET_DATA_CACHE_TTL_SECONDS` | TTL cache/stale check | Boleh tampil sebagai angka cache |
| `MARKET_DATA_SYNC_TOKEN` | Optional token untuk scheduled sync | Tidak |

Mode runtime:

| Mode | Kondisi | Active Provider | Response Quality |
| --- | --- | --- | --- |
| `sample` | Tidak ada mode production | `sample_provider` | `sample` |
| `fallback` | Mode production diminta tetapi env belum lengkap | `sample_provider` | `sample` |
| `production` | Env production lengkap | Provider dari env | `production` jika data valid, `stale` jika fallback diperlukan |

## Normalized Contracts

Shared layer mendefinisikan kontrak normalisasi untuk:

- `NormalizedPriceSnapshot`
- `NormalizedOhlcvBar`
- `NormalizedTechnicalIndicator`
- `NormalizedMarketContext`
- `NormalizedProviderSyncRun`

Kontrak ini memastikan Flutter dan Edge Functions tidak bergantung pada bentuk raw provider payload. Payload provider hanya dipakai di backend, lalu dipetakan ke field aman.

## Price Snapshot Contract

Field utama:

- `symbol_id`
- `symbol_code`
- `provider_name`
- `provider_symbol`
- `observed_at`
- `last_price`
- `previous_close`
- `open_price`
- `high_price`
- `low_price`
- `change_value`
- `change_percent`
- `volume`
- `value_traded`
- `market_cap`
- `currency`
- `data_quality`
- `is_stale`
- `staleness_warning`

Raw payload yang disimpan tidak boleh berisi API key, auth header, cookie, token, atau credential.

## OHLCV Contract

Field utama:

- `symbol_id`
- `symbol_code`
- `provider_name`
- `timeframe`
- `observed_at`
- `open_price`
- `high_price`
- `low_price`
- `close_price`
- `volume`
- `value_traded`
- `data_quality`

OHLCV belum diaktifkan sebagai endpoint production pada tahap ini. Kontrak disiapkan untuk tahap indikator teknikal berikutnya.

## Technical Indicator Contract

Field utama:

- `timeframe`
- `ema_20`
- `ema_50`
- `ema_200`
- `rsi_14`
- `atr_14`
- `average_volume_20`
- `volume_ratio`
- `support_level`
- `resistance_level`
- `trend_state`
- `candlestick_pattern`
- `technical_score`
- `trend_score`
- `volume_score`
- `risk_score`
- `invalidation_level`
- `rule_version`
- `data_quality`

Jika OHLCV belum tersedia, indikator tetap dapat memakai fallback edukatif dengan `data_quality = stale` atau `sample`.

## Market Context Contract

Field utama:

- `market_code`
- `index_symbol`
- `observed_at`
- `index_last`
- `index_change`
- `index_change_percent`
- `index_trend`
- `market_status`
- `risk_regime`
- `breadth_summary`
- `data_quality`
- `is_stale`
- `risk_warning`

Market context digunakan untuk konteks watchlist candidate dan risk warning, bukan instruksi transaksi.

## Edge Function Behavior

### `sync-market-candidates`

Alur:

1. Validasi auth melalui JWT user atau `MARKET_DATA_SYNC_TOKEN`.
2. Resolve provider runtime dari env.
3. Ensure row `provider_sources`.
4. Load symbols dari table `symbols`.
5. Jika production env lengkap, coba fetch provider melalui generic adapter.
6. Jika provider tidak valid atau gagal, fallback ke sample/stale.
7. Insert normalized rows ke:
   - `market_price_snapshots`
   - `technical_indicator_snapshots`
   - `market_context_snapshots`
8. Update `provider_sync_runs`.
9. Return response edukatif dengan `data_quality`, `provider_status`, dan `risk_warning`.

### `get-market-context`

Alur:

1. Validasi JWT user.
2. Resolve provider runtime.
3. Ambil latest `market_context_snapshots`.
4. Jika kosong dan fallback diizinkan, coba provider production bila env lengkap.
5. Jika provider tidak tersedia atau payload belum valid, buat row sample/stale.
6. Sanitize response.
7. Return context, provider metadata aman, cache metadata, disclaimer edukatif.

## Fallback Strategy

Fallback dipakai jika:

- mode production belum dipasang;
- env production belum lengkap;
- provider request timeout;
- provider response bukan JSON valid;
- provider response tidak punya quote/context yang bisa dinormalisasi;
- data provider stale berdasarkan TTL.

Saat fallback:

- `data_quality` menjadi `sample` atau `stale`;
- `provider_status` menjelaskan kondisi fallback;
- `risk_warning` wajib muncul;
- Flutter tetap bisa menampilkan state tanpa crash.

## Security Notes

- Provider secret hanya dibaca dari `Deno.env` di Edge Functions.
- Flutter tidak menerima API key, service role key, atau raw provider payload.
- Metadata response hanya berisi status aman seperti provider name, provider mode, data quality, cache TTL, dan missing env name.
- Missing env name boleh tampil untuk debugging karena tidak mengandung nilai secret.
- Error message tidak boleh mencetak secret.

## Database Compatibility

Migration P2 awal belum memakai literal `production` di check constraint table cache. Karena itu shared layer menyediakan adapter DB-row:

- response `production` disimpan sebagai `realtime` untuk quote/context;
- response `production` disimpan sebagai `computed` untuk technical indicator;
- saat dibaca, `realtime`, `delayed`, dan `computed` dinormalisasi kembali menjadi `production`.

Pendekatan ini menjaga migration lama tetap aman tanpa perubahan destructive.

## Next Step

1. Jalankan smoke test fallback tanpa env production.
2. Jalankan smoke test missing provider env.
3. Pasang provider sandbox resmi atau vendor legal.
4. Validasi mapping payload provider ke normalized contracts.
5. Tambahkan endpoint OHLCV dan compute indicator dari OHLCV.
6. Baru setelah data stabil, hubungkan `evaluate-watchlist-v2` ke cache production/stale.
