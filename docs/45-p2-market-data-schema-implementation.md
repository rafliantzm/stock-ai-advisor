# 45. P2 Market Data Schema Implementation

## Scope

Dokumen ini menjelaskan implementasi fondasi schema market data P2.

Migration:

- `supabase/migrations/0005_create_market_data_schema.sql`

Tujuan migration:

- menambah tabel cache market data;
- menambah audit provider sync;
- menyiapkan OHLCV dan technical indicator snapshots;
- menjaga P1 tetap berjalan;
- memastikan Flutter tetap membaca data melalui Edge Functions.

Belum dikerjakan pada tahap ini:

- Edge Functions P2;
- Flutter UI P2;
- provider market data real;
- AI/RAG;
- technical indicator computation real;
- data seed market real.

## Tabel Baru

| Table | Fungsi |
| --- | --- |
| `provider_sources` | Metadata provider tanpa API key/secret. |
| `provider_sync_runs` | Audit log sync provider. |
| `market_price_snapshots` | Cache quote/price snapshot saham. |
| `ohlcv_bars` | Cache OHLCV per symbol/timeframe. |
| `technical_indicator_snapshots` | Snapshot indikator teknikal hasil backend. |
| `market_context_snapshots` | Snapshot market context/IHSG/risk regime. |
| `news_items` | Cache news/catalyst summary backend. |

## Foreign Key

FK ke `symbols(id)` ditambahkan pada tabel yang relevan:

- `provider_sync_runs.symbol_id`
- `market_price_snapshots.symbol_id`
- `ohlcv_bars.symbol_id`
- `technical_indicator_snapshots.symbol_id`
- `news_items.symbol_id`

FK ke `provider_sources(id)` ditambahkan pada:

- `provider_sync_runs.provider_source_id`
- `market_price_snapshots.provider_source_id`
- `ohlcv_bars.provider_source_id`
- `technical_indicator_snapshots.provider_source_id`
- `market_context_snapshots.provider_source_id`
- `news_items.provider_source_id`

Catatan:

- `symbol_code` dan `provider_name` tetap disimpan sebagai denormalized field untuk debugging dan query praktis.
- FK memakai `on delete set null` agar cache historis tidak langsung hilang jika metadata berubah.

## Index

Migration menambahkan index untuk pola query P2:

- `symbol_id`
- `symbol_code`
- `timeframe`
- `provider_name`
- `observed_at`
- `created_at`

Composite index utama:

- `market_price_snapshots(symbol_id, observed_at desc)`
- `ohlcv_bars(symbol_id, timeframe, observed_at desc)`
- `technical_indicator_snapshots(symbol_id, timeframe, observed_at desc)`
- `market_context_snapshots(market_code, index_symbol, observed_at desc)`

## RLS

Semua tabel P2 diaktifkan RLS:

- `provider_sources`
- `provider_sync_runs`
- `market_price_snapshots`
- `ohlcv_bars`
- `technical_indicator_snapshots`
- `market_context_snapshots`
- `news_items`

Tidak ada public policy pada tahap ini.

Alasan:

- Market data adalah cache global, bukan user-owned.
- Flutter tidak boleh membaca tabel langsung.
- Edge Functions akan menjadi layer akses aman.
- API key dan provider access tetap backend-only.

## Data Quality

Field `data_quality` disiapkan untuk membedakan:

- `sample`
- `delayed`
- `realtime`
- `stale`
- `needs_more_data`

Untuk P2 awal, response yang belum memakai provider aktif harus tetap dilabeli:

- `sample data`
- `provider belum aktif`
- `needs_more_data`

## Keamanan Secret

Migration tidak membuat kolom untuk API key, token, credential, cookie, atau header rahasia.

API key provider nanti harus disimpan di:

- Supabase Edge Functions environment variables.

Flutter tetap hanya memakai:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- JWT user dari Supabase Auth.

## Hubungan Dengan P1

P1 tidak berubah.

Migration ini tidak:

- menghapus tabel lama;
- mengubah tabel watchlist;
- mengubah Edge Functions P0;
- mengubah Flutter UI;
- mengganti `p0_dummy_scoring_v1`.

P1 tetap memakai flow yang sudah stabil:

- Watchlist;
- Screener;
- Smart Alert;
- Stock Detail P1;
- Market placeholder;
- Chart Lab placeholder.

## Cara Menjalankan Di Supabase Web

1. Buka Supabase Dashboard.
2. Masuk ke SQL Editor.
3. New Query.
4. Paste isi file:

```text
supabase/migrations/0005_create_market_data_schema.sql
```

5. Pastikan tidak ada SQL destructive:
   - tidak ada `drop table`;
   - tidak ada `truncate`;
   - tidak ada `delete from`.
6. Klik Run.
7. Jalankan verification queries dari `docs/46-p2-market-data-smoke-test-plan.md`.

## Next Step

Setelah migration terverifikasi:

1. Seed `provider_sources` sample provider.
2. Seed sample market data untuk `BBCA`, `BBRI`, `TLKM`, `ASII`, `UNVR`.
3. Buat Edge Function read-only pertama: `get-market-context`.
4. Buat Edge Function read-only kedua: `get-stock-quote`.
5. Jangan ubah P1 sebelum endpoint P2 lolos smoke test.
