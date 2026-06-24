# 39. P2 Market Data And Chart Lab Roadmap

## Tujuan P2

P2 menghubungkan UI P1 ke data pasar dan rule engine yang lebih nyata, tetap dengan guardrail bahwa aplikasi memberi analisis edukatif dan scoring berbasis data, bukan instruksi transaksi.

## Rencana Market Data Provider

1. Pilih provider yang mendukung data saham Indonesia secara legal.
2. Simpan API key hanya di Supabase Edge Functions environment.
3. Buat Edge Function `get-market-context` untuk:
   - market status
   - index trend
   - risk regime
   - last updated
4. Buat caching di database atau Edge Function agar Flutter tidak memanggil provider langsung.
5. Tambahkan audit field seperti `provider_name`, `data_timestamp`, dan `staleness_warning`.

## Rencana OHLCV Candles

1. Buat tabel atau materialized cache untuk OHLCV:
   - `symbol_id`
   - `timeframe`
   - `open`
   - `high`
   - `low`
   - `close`
   - `volume`
   - `provider_timestamp`
2. Buat Edge Function `get-stock-chart-data`.
3. Batasi request by symbol dan timeframe.
4. Tambahkan fallback jika data stale atau provider down.

## Rencana Chart Overlay

Overlay prioritas:

- EMA trend context.
- support/resistance zone.
- candlestick pattern.
- harmonic watch.
- volume-price analysis.
- SMC confluence.

Implementasi awal:

1. Backend menghitung overlay dan mengirim shape/annotation JSON.
2. Flutter hanya render chart dan annotation.
3. Semua label memakai `technical setup`, `risk warning`, dan `invalidation level`.

## Rencana Rule Engine Real

1. Pindahkan dummy scoring P0 ke rule engine versi P2.
2. Tambahkan rule version seperti `p2_rule_engine_v1`.
3. Input rule engine:
   - OHLCV candles.
   - score teknikal.
   - score harmony.
   - score fundamental.
   - score risiko.
   - score likuiditas.
4. Output rule engine:
   - `candidate_label`
   - `technical_setup`
   - `risk_warning`
   - `invalidation_level`
   - score breakdown.
5. Simpan hasil ke `watchlist_scores` agar UI tetap membaca contract yang sama.

## Rencana RAG Buku Sebagai Explanation Layer

1. Lanjutkan pipeline buku setelah text extraction:
   - chunking
   - theory cards
   - theory clusters
   - embedding pgvector
2. RAG hanya mengambil teori relevan untuk menjelaskan score.
3. AI tidak menentukan keputusan bebas.
4. Response explanation harus mencantumkan:
   - rule output yang dijelaskan
   - teori pendukung
   - batasan data
   - risk warning
5. Flutter menampilkan explanation sebagai panel edukatif, bukan instruksi eksekusi.

## Milestone P2

1. `get-market-context` Edge Function.
2. OHLCV cache schema dan seed sample terbatas.
3. `get-stock-chart-data` Edge Function.
4. Chart Lab real data baseline.
5. Rule Engine P2.
6. RAG explanation layer.
7. Regression test untuk P0 endpoints agar tidak pecah.
