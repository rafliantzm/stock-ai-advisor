# Book Catalog Pipeline

Pipeline ini membuat katalog awal untuk PDF buku lokal di `data/books/`.

Tahap ini hanya membaca metadata filesystem seperti nama file, ukuran file, dan waktu modifikasi. Script tidak membaca isi PDF, tidak melakukan ekstraksi teks, tidak membuat chunk, tidak membuat RAG, tidak menjalankan rule engine, dan tidak mengirim PDF ke Supabase.

## Input

Letakkan semua PDF buku di:

```text
data/books/
```

Folder ini diabaikan oleh Git, sehingga PDF lokal tidak ikut commit.

## Output

Script menghasilkan:

```text
data/catalog/books_catalog.csv
data/catalog/books_catalog.json
data/catalog/catalog_summary.md
```

Jika katalog lama sudah ada, script membuat backup sebelum overwrite:

```text
data/catalog/books_catalog.backup.csv
data/catalog/books_catalog.backup.json
```

Field katalog:

- `book_id`
- `file_name`
- `title_guess`
- `category_guess`
- `source_type`
- `priority`
- `size_mb`
- `modified_at`
- `extract_status`
- `processing_status`
- `notes`

Nilai default:

- `extract_status = pending`
- `processing_status = not_processed`
- `notes` kosong

## Category Guess

Kategori ditebak dari keyword nama file:

- `harmonic`, `harmoni`, `gartley`, `bat`, `butterfly`, `crab`, `abcd`, `xabcd`, `prz`, `reversal zone` -> `harmonic_pattern`
- `fibonacci`, `fibo`, `retracement`, `extension`, `golden ratio` -> `fibonacci_analysis`
- `support`, `resistance`, `snr`, `supply`, `demand`, `zona`, `zone` -> `support_resistance`
- `candlestick`, `candle`, `bullish`, `bearish`, `doji`, `engulfing`, `hammer`, `pinbar` -> `candlestick_pattern`
- `chart pattern`, `pattern`, `triangle`, `wedge`, `head shoulder`, `double top`, `double bottom`, `flag`, `pennant` -> `chart_pattern`
- `trendline`, `trend line`, `trend`, `channel` -> `trendline_analysis`
- `volume`, `vpa`, `tape`, `tape reading`, `wyckoff`, `bandarmology`, `bandar` -> `volume_price_analysis`
- `fundamental`, `laporan keuangan`, `valuation`, `valuasi`, `finansial`, `financial`, `ratio`, `rasio` -> `fundamental_analysis`
- `risk`, `risiko`, `stop loss`, `money management`, `margin of safety`, `position sizing` -> `risk_management`
- `portfolio`, `portofolio`, `investment`, `investing`, `investasi` -> `investment_management`
- `psychology`, `psikologi`, `mindset`, `mental` -> `psychology`
- selain itu -> `supporting`

Setiap kategori juga menentukan `source_type` dan `priority`.

## Cara Menjalankan

Dari root project:

```bash
python python/book_pipeline/create_book_catalog.py
```

## Summary Report

`data/catalog/catalog_summary.md` berisi:

- total PDF terdeteksi
- jumlah per kategori
- jumlah high priority
- 20 buku prioritas tertinggi
- kemungkinan duplikat berdasarkan nama mirip
- rekomendasi buku yang diproses dulu

## Catatan Keamanan

- Script tidak membuka atau membaca isi PDF.
- Script tidak mengubah file buku asli.
- Script tidak upload file ke Supabase.
- Folder hasil ekstraksi masa depan seperti `data/extracted_text/`, `data/chunks/`, dan `data/theory_cards/` juga diabaikan Git untuk menghindari commit teks buku atau artefak besar.

## Next Step

Setelah katalog berhasil dibuat dan kategori terlihat masuk akal, tahap berikutnya adalah review manual `books_catalog.csv` dan `catalog_summary.md` untuk mengatur `priority`, memperbaiki `category_guess`, dan memilih batch buku pertama. Ekstraksi teks, chunking, RAG, theory cards, clustering, rules, dan backtesting dilakukan di tahap terpisah.
