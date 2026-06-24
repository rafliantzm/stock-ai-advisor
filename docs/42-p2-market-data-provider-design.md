# 42. P2 Market Data Provider Design

## Tujuan P2

P2 bertujuan menghubungkan stock-ai-advisor ke data pasar yang lebih nyata secara bertahap, aman, dan bisa diaudit. Data ini akan dipakai untuk memperkaya:

- quote saham;
- OHLCV candles;
- market context/IHSG;
- technical indicators;
- scoring Rule Engine versi P2;
- Chart Lab berbasis data.

P2 tetap bersifat edukatif. Output aplikasi adalah `watchlist candidate`, `layak dianalisis`, `risk warning`, dan `invalidation level`, bukan instruksi transaksi.

## Batasan P2

- Jangan menghapus atau mengganti langsung `p0_dummy_scoring_v1`.
- Jangan mengaktifkan AI/RAG pada tahap awal P2.
- Jangan menaruh API key provider di Flutter.
- Flutter hanya memakai `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan JWT user.
- Semua akses provider eksternal wajib lewat Supabase Edge Functions.
- Market data yang belum tersedia wajib diberi label `provider belum aktif` atau `sample data`.
- Data provider tidak boleh ditampilkan sebagai jaminan hasil.
- Tidak ada fitur transaksi saham.

## Provider Strategy

### Development

Development memakai pendekatan bertahap:

1. Gunakan `sample data` terbatas untuk validasi schema, Edge Functions, dan UI state.
2. Simpan sample hanya untuk symbol dummy/seed seperti `BBCA`, `BBRI`, `TLKM`, `ASII`, dan `UNVR`.
3. Tandai semua response sample dengan:
   - `data_quality = sample`
   - `provider_name = sample_provider`
   - `is_stale = true`
   - `provider_status = provider belum aktif`
4. Jangan membuat UI tampak seperti data real-time jika provider belum aktif.

### Production

Production harus memakai provider resmi atau legal untuk data IDX.

Kriteria provider:

- mendukung symbol IDX;
- memiliki legal terms yang mengizinkan penggunaan aplikasi;
- menyediakan quote dan OHLCV dengan timestamp;
- memiliki rate limit jelas;
- menyediakan dokumentasi API stabil;
- memiliki SLA atau status page jika memungkinkan;
- mendukung attribution jika diwajibkan.

Production flow:

1. Edge Function membaca secret provider dari environment Supabase.
2. Edge Function request ke provider.
3. Data divalidasi dan dinormalisasi.
4. Data disimpan ke tabel cache Supabase.
5. Flutter membaca data melalui Edge Function, bukan langsung ke provider.

## Data Quote Saham

Minimal data untuk quote:

- `symbol_id`
- `symbol_code`
- `last_price`
- `previous_close`
- `open_price`
- `high_price`
- `low_price`
- `change_value`
- `change_percent`
- `volume`
- `value_traded`
- `market_cap` jika tersedia
- `quote_timestamp`
- `provider_name`
- `provider_symbol`
- `data_quality`
- `is_stale`
- `created_at`
- `updated_at`

Quote digunakan untuk:

- Price Snapshot;
- risk warning berbasis stale data;
- kandidat watchlist berbasis likuiditas;
- input awal Rule Engine P2.

## Data OHLCV Candles

Minimal data untuk candles:

- `symbol_id`
- `symbol_code`
- `timeframe`
- `candle_time`
- `open`
- `high`
- `low`
- `close`
- `volume`
- `value_traded`
- `provider_name`
- `provider_timestamp`
- `data_quality`
- `created_at`

Timeframe awal:

- `1d` untuk P2 awal;
- `1h` dan intraday hanya setelah provider dan rate limit aman.

OHLCV digunakan untuk:

- Chart Lab;
- technical indicators;
- support/resistance;
- candlestick pattern;
- volume-price analysis;
- Rule Engine P2.

## Data Market Context/IHSG

Minimal data untuk market context:

- `market_code`, contoh `IDX`
- `index_symbol`, contoh `IHSG`
- `index_last`
- `index_change`
- `index_change_percent`
- `index_trend`
- `market_status`
- `risk_regime`
- `breadth_summary` jika tersedia
- `last_updated`
- `provider_name`
- `data_quality`
- `is_stale`

Market context digunakan untuk:

- panel Market Context;
- risk regime global;
- penyesuaian scoring watchlist candidate;
- peringatan jika data stale.

## Data Technical Indicators

Technical indicators dihitung di backend, bukan di Flutter.

Indikator awal:

- EMA 20/50/200;
- RSI 14;
- average volume;
- volume ratio;
- ATR;
- support/resistance level sederhana;
- candlestick pattern label sederhana;
- harmonic watch placeholder berbasis rule version;
- trend state.

Minimal field:

- `symbol_id`
- `timeframe`
- `indicator_date`
- `indicator_payload`
- `technical_score`
- `trend_score`
- `volume_score`
- `risk_score`
- `invalidation_level`
- `rule_version`
- `data_quality`
- `computed_at`

## Cara Data Masuk Ke Supabase

P2 memakai dua mode sync:

1. On-demand sync:
   - Flutter memanggil Edge Function seperti `get-stock-quote`.
   - Edge Function cek cache.
   - Jika cache valid, return cache.
   - Jika cache stale dan policy mengizinkan, Edge Function sync provider lalu update cache.

2. Scheduled sync:
   - Supabase scheduled job atau external scheduler memanggil `sync-stock-quote` dan `sync-ohlcv-candles`.
   - Data disimpan ke tabel cache.
   - `provider_sync_logs` mencatat status, error, dan jumlah row.

## Cara Flutter Membaca Data

Flutter hanya membaca melalui Edge Functions:

- `get-stock-quote`
- `get-market-context`
- nanti `get-stock-chart-data` jika ditambahkan setelah schema awal
- `evaluate-watchlist-v2`

Headers:

```text
Authorization: Bearer <user_jwt>
apikey: <supabase_anon_key>
Content-Type: application/json
```

Flutter tidak boleh:

- menyimpan service role key;
- menyimpan API key provider;
- memanggil provider eksternal langsung;
- menghitung logic sensitif Rule Engine.

## Risiko Provider Tidak Resmi

Risiko jika memakai provider tidak resmi:

- melanggar terms of service;
- data tidak akurat atau berubah format tanpa notice;
- akses bisa diblokir tiba-tiba;
- tidak ada audit timestamp yang dapat dipercaya;
- risiko legal untuk penggunaan production;
- rate limit tidak jelas;
- kualitas data dapat mengganggu scoring dan risk warning.

Keputusan:

- provider tidak resmi hanya boleh dipakai untuk eksperimen lokal yang tidak masuk production;
- production wajib memakai provider legal;
- semua data dari provider yang belum final wajib diberi label `sample data` atau `provider belum aktif`.

## Caching Strategy

Tujuan caching:

- menghemat request provider;
- menjaga UI cepat;
- mengurangi risiko rate limit;
- menyediakan audit trail.

TTL awal:

| Data | TTL development | TTL production awal |
| --- | --- | --- |
| Quote | 15-60 menit | 1-5 menit sesuai provider |
| OHLCV daily | 24 jam setelah market close | 1 hari perdagangan |
| Market context | 15-60 menit | 5-15 menit |
| Technical indicators | Setelah OHLCV berubah | Setelah candle baru |

Cache response wajib membawa:

- `data_quality`
- `provider_name`
- `last_updated`
- `is_stale`
- `staleness_warning`

## Disclaimer

Data market P2 hanya untuk edukasi dan analisis. Data, score, technical setup, watchlist candidate, risk warning, dan invalidation level bukan instruksi transaksi dan tidak menjamin hasil.
