# 41. P1 Release Freeze Notes

## Status P1

P1 Flutter Feature Adaptation dinyatakan stabil untuk freeze.

Status:

- UI berjalan di Flutter Web.
- Login Supabase Auth berhasil.
- Edge Functions P0 tetap stabil dan tidak diubah.
- Watchlist, Screener, Market Context, Chart Lab, dan Smart Alert sudah dapat digunakan sesuai scope P1.
- Wording UI tetap aman: `watchlist candidate`, `layak dianalisis`, `risk warning`, `invalidation level`, `sample data`, dan `provider belum aktif`.

## Fitur Yang Sudah Selesai

Fitur berikut boleh dianggap selesai untuk P1:

- Supabase Auth login/logout.
- Dashboard navigation:
  - Watchlist
  - Screener
  - Market
  - Chart Lab
  - Alerts
- Enhanced Watchlist Card:
  - `Final`
  - `Technical`
  - `Harmony`
  - `Fundamental`
  - `Risk`
  - `Liquidity`
  - `Invalidation`
  - `Rule Version`
- Add Watchlist Item flow.
- Evaluate Watchlist flow.
- Compact risk warning list.
- Stock Detail Analysis:
  - Price Snapshot
  - Insight Utama
  - Multi-Mode Analyzer
  - Technical Signals
  - Fundamental Snapshot
  - Risk Analysis
  - Strategy Explanation
  - Calculator Edukatif
  - News Placeholder
- Screener Categories.
- Daily Watchlist Candidates placeholder/result section.
- Market Context placeholder.
- Chart Lab preview.
- Smart Alert create flow.

## Fitur Yang Masih Placeholder

Fitur berikut sengaja masih placeholder pada P1:

- Market Context real provider.
- IHSG/index trend real provider.
- OHLCV candles.
- Chart Lab real chart.
- Chart overlays berbasis data:
  - EMA
  - support/resistance
  - candlestick pattern
  - harmonic watch
  - volume-price analysis
  - SMC confluence
- News/catalyst provider.
- AI/RAG explanation layer.

Placeholder wajib tetap diberi label jelas seperti:

- `sample data`
- `provider belum aktif`
- `Chart Lab preview`
- `needs_more_data`

## Alasan Belum Masuk Market Data Real-Time

Market data real-time belum dimasukkan pada P1 karena:

1. API key market data tidak boleh berada di Flutter.
2. Provider data IDX perlu dipilih dan divalidasi secara legal/teknis.
3. Data OHLCV butuh cache backend agar request tidak langsung dari client.
4. Rule Engine real membutuhkan input data yang konsisten, timestamped, dan bisa diaudit.
5. Chart Lab perlu kontrak data overlay dari backend agar Flutter hanya menjadi renderer.
6. P1 difokuskan untuk membekukan UX, response contract, dan integrasi Edge Functions P0.

## Known Limitations

- Scoring masih `p0_dummy_scoring_v1`.
- Market data provider belum aktif.
- OHLCV belum aktif.
- AI/RAG belum aktif.
- Chart Lab masih preview.
- News provider belum aktif.
- Tidak ada fitur transaksi saham.

## Rencana Masuk P2 Market Data Provider

Tahap P2 direkomendasikan:

1. Tentukan provider market data untuk IDX.
2. Simpan API key di Supabase Edge Functions environment.
3. Buat schema/cache untuk OHLCV.
4. Buat Edge Function `get-market-context`.
5. Buat Edge Function `get-stock-chart-data`.
6. Buat service backend untuk menghitung overlay teknikal.
7. Upgrade scoring dari `p0_dummy_scoring_v1` ke Rule Engine P2.
8. Simpan hasil scoring ke `watchlist_scores` agar UI P1 tetap membaca `latest_score`.
9. Tambahkan RAG buku hanya sebagai explanation layer setelah Rule Engine P2 stabil.

## Freeze Decision

P1 dinyatakan selesai untuk scope UI dan siap menjadi baseline sebelum P2 market data provider.
