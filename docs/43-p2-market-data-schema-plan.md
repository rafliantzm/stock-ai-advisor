# 43. P2 Market Data Schema Plan

Dokumen ini merancang schema P2 sebelum migration dibuat. Belum ada SQL migration pada tahap ini.

## Tujuan Schema

Schema P2 menyimpan data pasar yang sudah dinormalisasi dan dapat diaudit:

- quote saham;
- OHLCV candles;
- technical indicators;
- market context/IHSG;
- provider sync logs.

Schema ini menjadi cache backend agar Flutter tidak membaca provider eksternal langsung.

## Prinsip Desain

- Gunakan `symbols(id)` dari base schema sebagai referensi utama.
- Jangan simpan API key provider di database.
- Simpan metadata provider dan timestamp untuk audit.
- Gunakan `data_quality` untuk membedakan `sample`, `delayed`, `realtime`, dan `stale`.
- Jangan menghapus `p0_dummy_scoring_v1`; P2 menambah jalur baru.
- Semua scoring sensitif tetap di backend.

## Tabel: market_quotes

Fungsi:

- Menyimpan quote terbaru per symbol/provider.
- Dipakai oleh Price Snapshot dan Rule Engine P2.

Rencana kolom:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid pk | primary key |
| `symbol_id` | uuid | FK ke `symbols(id)` |
| `symbol_code` | text | denormalized untuk debugging |
| `provider_name` | text | contoh `sample_provider` |
| `provider_symbol` | text | symbol format provider |
| `last_price` | numeric | nullable jika sample belum lengkap |
| `previous_close` | numeric | optional |
| `open_price` | numeric | optional |
| `high_price` | numeric | optional |
| `low_price` | numeric | optional |
| `change_value` | numeric | optional |
| `change_percent` | numeric | optional |
| `volume` | numeric | optional |
| `value_traded` | numeric | optional |
| `market_cap` | numeric | optional |
| `quote_timestamp` | timestamptz | timestamp dari provider |
| `data_quality` | text | `sample`, `delayed`, `realtime`, `stale` |
| `is_stale` | boolean | default true |
| `staleness_warning` | text | nullable |
| `raw_payload` | jsonb | optional, jangan simpan secrets |
| `created_at` | timestamptz | default now |
| `updated_at` | timestamptz | default now |

Index/constraint:

- unique candidate: `(symbol_id, provider_name)`
- index: `(symbol_code)`
- index: `(quote_timestamp desc)`

## Tabel: ohlcv_candles

Fungsi:

- Menyimpan candle historis.
- Dipakai Chart Lab, indicator computation, dan Rule Engine P2.

Rencana kolom:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid pk | primary key |
| `symbol_id` | uuid | FK ke `symbols(id)` |
| `symbol_code` | text | denormalized |
| `timeframe` | text | contoh `1d`, `1h` |
| `candle_time` | timestamptz | waktu candle |
| `open_price` | numeric | required jika candle valid |
| `high_price` | numeric | required jika candle valid |
| `low_price` | numeric | required jika candle valid |
| `close_price` | numeric | required jika candle valid |
| `volume` | numeric | optional |
| `value_traded` | numeric | optional |
| `provider_name` | text | provider |
| `provider_timestamp` | timestamptz | timestamp provider |
| `data_quality` | text | `sample`, `delayed`, `realtime`, `stale` |
| `raw_payload` | jsonb | optional |
| `created_at` | timestamptz | default now |

Index/constraint:

- unique candidate: `(symbol_id, timeframe, candle_time, provider_name)`
- index: `(symbol_id, timeframe, candle_time desc)`
- index: `(symbol_code, timeframe)`

## Tabel: technical_indicators

Fungsi:

- Menyimpan hasil komputasi indikator teknikal.
- Flutter membaca ringkasan melalui Edge Function, bukan menghitung langsung.

Rencana kolom:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid pk | primary key |
| `symbol_id` | uuid | FK ke `symbols(id)` |
| `symbol_code` | text | denormalized |
| `timeframe` | text | contoh `1d` |
| `indicator_date` | date | tanggal indikator |
| `ema_20` | numeric | optional |
| `ema_50` | numeric | optional |
| `ema_200` | numeric | optional |
| `rsi_14` | numeric | optional |
| `atr_14` | numeric | optional |
| `average_volume_20` | numeric | optional |
| `volume_ratio` | numeric | optional |
| `support_level` | numeric | optional |
| `resistance_level` | numeric | optional |
| `trend_state` | text | contoh `needs_more_data`, `uptrend`, `sideways` |
| `candlestick_pattern` | text | optional |
| `indicator_payload` | jsonb | extensible payload |
| `technical_score` | numeric | score teknikal |
| `trend_score` | numeric | score trend |
| `volume_score` | numeric | score volume |
| `risk_score` | numeric | score risiko |
| `invalidation_level` | numeric | optional |
| `rule_version` | text | contoh `p2_indicator_v1` |
| `data_quality` | text | `sample`, `computed`, `stale` |
| `computed_at` | timestamptz | waktu komputasi |
| `created_at` | timestamptz | default now |
| `updated_at` | timestamptz | default now |

Index/constraint:

- unique candidate: `(symbol_id, timeframe, indicator_date, rule_version)`
- index: `(symbol_code, timeframe, indicator_date desc)`

## Tabel: market_context_snapshots

Fungsi:

- Menyimpan snapshot IHSG/market context.
- Dipakai Market Context panel dan Rule Engine P2.

Rencana kolom:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid pk | primary key |
| `market_code` | text | contoh `IDX` |
| `index_symbol` | text | contoh `IHSG` |
| `provider_name` | text | provider |
| `index_last` | numeric | optional |
| `index_change` | numeric | optional |
| `index_change_percent` | numeric | optional |
| `index_trend` | text | contoh `needs_more_data`, `uptrend`, `sideways` |
| `market_status` | text | contoh `open`, `closed`, `provider belum aktif` |
| `risk_regime` | text | contoh `neutral`, `elevated`, `needs_more_data` |
| `breadth_summary` | jsonb | optional |
| `context_payload` | jsonb | optional |
| `snapshot_at` | timestamptz | timestamp snapshot |
| `data_quality` | text | `sample`, `delayed`, `realtime`, `stale` |
| `is_stale` | boolean | default true |
| `staleness_warning` | text | nullable |
| `created_at` | timestamptz | default now |

Index/constraint:

- index: `(market_code, index_symbol, snapshot_at desc)`
- optional unique for latest cache handled by query/order.

## Tabel: provider_sync_logs

Fungsi:

- Audit sync provider, error, dan rate limit.
- Membantu debugging tanpa membuka secret provider.

Rencana kolom:

| Column | Type | Notes |
| --- | --- | --- |
| `id` | uuid pk | primary key |
| `provider_name` | text | provider |
| `sync_type` | text | `quote`, `ohlcv`, `market_context`, `indicator_compute` |
| `status` | text | `success`, `partial`, `failed`, `skipped` |
| `symbol_id` | uuid | nullable FK ke `symbols(id)` |
| `symbol_code` | text | nullable |
| `timeframe` | text | nullable |
| `started_at` | timestamptz | required |
| `finished_at` | timestamptz | nullable |
| `rows_requested` | integer | optional |
| `rows_inserted` | integer | optional |
| `rows_updated` | integer | optional |
| `rate_limit_remaining` | integer | optional |
| `error_code` | text | nullable |
| `error_message` | text | nullable, jangan simpan secrets |
| `metadata` | jsonb | optional |
| `created_at` | timestamptz | default now |

Index:

- `(provider_name, sync_type, started_at desc)`
- `(status, started_at desc)`
- `(symbol_code, started_at desc)`

## RLS Dan Access Pattern

Market data cache tidak dimiliki user tertentu.

Rekomendasi awal:

- Flutter tidak membaca tabel langsung.
- Tidak perlu public select policy pada P2 awal.
- Edge Functions memakai service role di environment backend jika perlu.
- Response tetap difilter dan distandarkan oleh Edge Functions.

User-owned data seperti watchlist tetap memakai RLS existing.

## Data Quality Dan Staleness

Field `data_quality` dan `is_stale` wajib dikembalikan oleh Edge Functions.

Contoh response state:

- `sample`: data dummy development.
- `delayed`: data provider legal tetapi tidak real-time.
- `realtime`: data provider mendukung real-time.
- `stale`: cache melewati TTL.

Jika stale:

- Flutter tampilkan `risk warning`;
- scoring boleh turun confidence;
- UI wajib menyebut `provider belum aktif` atau data stale sesuai konteks.

## Integrasi Dengan watchlist_scores

P2 tidak menghapus P0.

Rencana:

1. `evaluate-watchlist-v2` membaca quotes, OHLCV, indicators, dan market context.
2. Function menghasilkan score breakdown.
3. Function menyimpan hasil ke `watchlist_scores`.
4. `rule_version` menjadi contoh `p2_market_scoring_v1`.
5. UI tetap membaca `latest_score`.

## Migration Plan Nanti

Migration baru disarankan setelah desain disetujui:

- `supabase/migrations/0005_create_market_data_schema.sql`

Seed sample opsional:

- `supabase/seed/0002_market_data_sample_seed.sql`

Belum dibuat pada tahap dokumen desain ini.
