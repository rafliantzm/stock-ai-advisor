# Text Extraction Pipeline

Pipeline ini mengekstrak teks PDF digital hanya untuk buku terpilih dari catalog. Tahap ini belum membuat RAG, belum membuat Theory Cards, belum melakukan OCR, dan belum mengirim data ke Supabase.

## Input

```text
data/catalog/books_catalog.csv
data/books/
```

Catalog digunakan untuk memilih buku berdasarkan `priority` dan `category_guess`. PDF asli tetap berada di `data/books/`.

## Selection Rules

Default command memilih:

- `priority = high`
- kategori termasuk:
  - `harmonic_pattern`
  - `fibonacci_analysis`
  - `support_resistance`
  - `candlestick_pattern`
  - `chart_pattern`
  - `trendline_analysis`
  - `volume_price_analysis`
  - `risk_management`

Jika buku yang cocok terlalu banyak, jumlahnya dibatasi oleh `--max-books`.

## Cara Menjalankan

Install dependency Python bila belum tersedia:

```bash
python -m pip install -r python/requirements.txt
```

Jalankan ekstraksi batch kecil:

```bash
python python/book_pipeline/extract_selected_books.py --max-books 10 --priority high
```

## Output

Setiap buku menghasilkan file:

```text
data/extracted_text/{book_id}.json
```

Report run:

```text
data/extracted_text/extraction_report.json
data/extracted_text/extraction_summary.md
```

Format JSON per buku:

```json
{
  "book_id": "",
  "file_name": "",
  "category_guess": "",
  "source_type": "",
  "priority": "",
  "pages": [
    {
      "page_number": 1,
      "text": "",
      "char_count": 0,
      "extraction_status": "success"
    }
  ],
  "summary": {
    "total_pages": 0,
    "pages_with_text": 0,
    "empty_pages": 0,
    "total_chars": 0,
    "overall_status": "success"
  }
}
```

Page dengan hasil teks kosong ditandai `needs_ocr`. OCR belum dijalankan otomatis.

## Catalog Update

Setelah ekstraksi, script memperbarui:

- `extract_status = success | partial | needs_ocr`
- `processing_status = extracted | partial | needs_ocr`

Catalog CSV dan JSON sama-sama diperbarui.

## Safeguards

- Script tidak mengubah file PDF asli.
- Script menolak path yang keluar dari `data/books/`.
- Script tidak memproses semua 124 buku kecuali `--max-books` sengaja dinaikkan.
- Script tidak menjalankan OCR otomatis.
- Script tidak mengirim PDF atau teks ke Supabase.
- `data/extracted_text/` diabaikan Git agar hasil ekstraksi tidak ikut commit.
- Jika file tidak ditemukan, detailnya dicatat di `extraction_report.json`.

## Next Step

Setelah extraction berhasil, review `extraction_summary.md` untuk melihat buku yang `success`, `partial`, atau `needs_ocr`. Buku dengan `success` dan jumlah karakter memadai bisa masuk tahap chunking terkontrol. Buku `needs_ocr` sebaiknya ditunda sampai pipeline OCR manual dibuat.
