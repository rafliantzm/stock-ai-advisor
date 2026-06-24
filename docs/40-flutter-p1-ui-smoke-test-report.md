# 40. Flutter P1 UI Smoke Test Report

## Environment Test

Project:

- `stock-ai-advisor`

Runtime:

- Flutter Web via local web-server.
- Browser test: Firefox.
- Local URL: `http://127.0.0.1:3000`.
- Auth: Supabase Auth user login berhasil.
- Backend: Supabase Edge Functions P0 stabil.
- API mode: Flutter memakai `SUPABASE_URL`, `SUPABASE_ANON_KEY`, dan JWT user.

Guardrails:

- Tidak ada market data real-time pada P1.
- Tidak ada AI/RAG pada P1.
- Tidak ada chart kompleks pada P1.
- Tidak ada fitur transaksi saham.
- Wording aman yang digunakan: `watchlist candidate`, `layak dianalisis`, `risk warning`, `invalidation level`, `sample data`, dan `provider belum aktif`.

## Daftar Screen Yang Dites

| Screen | Hasil aktual | Status |
| --- | --- | --- |
| Login | User berhasil login memakai Supabase Auth. | Pass |
| Watchlist | Watchlist tampil setelah login. | Pass |
| Watchlist Add Item | `ASII` berhasil ditambahkan dari UI. | Pass |
| Watchlist Evaluate | Evaluate berhasil dan muncul notifikasi `Evaluasi selesai`. | Pass |
| Enhanced Watchlist Card | Card tampil dengan `Final`, `Technical`, `Harmony`, `Fundamental`, `Risk`, `Liquidity`, `Invalidation`, dan `Rule Version`. | Pass |
| Risk Warning | Risk warning tampil compact dengan severity. | Pass |
| Stock Detail Analysis | Detail saham terbuka dari Watchlist Card. | Pass |
| Multi-Mode Analyzer | Mode analyzer tampil. | Pass |
| Technical Signals | Section tampil. | Pass |
| Fundamental Snapshot | Section tampil. | Pass |
| Risk Analysis | Section tampil. | Pass |
| Strategy Explanation | Section tampil dengan penjelasan deterministik P1. | Pass |
| Calculator Edukatif | Komponen simulasi risiko tampil dengan disclaimer edukatif. | Pass |
| News Placeholder | Placeholder tampil dengan status provider belum aktif. | Pass |
| Screener Categories | Dropdown kategori tampil dan bisa memilih preset. | Pass |
| Market Context | Placeholder tampil dengan label sample data/provider belum aktif. | Pass |
| Chart Lab | Preview placeholder tampil. | Pass |
| Smart Alert | Smart Alert berhasil dibuat dari UI. | Pass |

## Daftar Fitur Yang Berhasil

- Login Supabase Auth.
- Load Watchlist dari Edge Function P0.
- Add Watchlist Item dari UI.
- Evaluate Watchlist dari UI.
- Tampilkan latest score di Enhanced Watchlist Card.
- Compact risk warning list.
- Navigasi ke Stock Detail Analysis.
- Multi-Mode Analyzer berbasis adapter P1.
- Technical Signals, Fundamental Snapshot, Risk Analysis, Strategy Explanation.
- Calculator Edukatif.
- Screener Categories.
- Market Context placeholder.
- Chart Lab placeholder.
- Smart Alert create dari UI.

## Hasil Aktual

| Area | Expected | Actual | Status |
| --- | --- | --- | --- |
| Auth | User bisa login | Login berhasil | Pass |
| Watchlist | Watchlist menampilkan item user | Watchlist tampil | Pass |
| Add item | Symbol valid bisa ditambahkan | `ASII` berhasil ditambahkan | Pass |
| Evaluate | Score diperbarui dari backend P0 | Notifikasi `Evaluasi selesai` muncul | Pass |
| Score labels | Tidak memakai snake_case di UI | Label tampil human-friendly | Pass |
| Null score handling | Data kosong tidak tampil sebagai `-` mentah | UI memakai `Menunggu data` bila diperlukan | Pass |
| Risk warning | Tidak memenuhi card | Compact list tampil | Pass |
| Detail analysis | Section P1 tampil | Semua section utama tampil | Pass |
| Screener | Kategori bisa dipilih | Dropdown berjalan | Pass |
| Placeholder | Data sample diberi label jelas | Market/Chart/News menyebut provider belum aktif | Pass |
| Smart Alert | Form membuat alert via backend | Alert berhasil dibuat dari UI | Pass |

## Automated Check

Command yang sudah dijalankan:

```powershell
cd D:\WEB\stock-ai-advisor\apps\mobile
dart format lib test
flutter analyze
flutter test
```

Hasil:

- `flutter analyze`: no issues found.
- `flutter test`: all tests passed.
- Widget test Smart Alert default scenario: Pass.
- Widget test score kosong menjadi `Menunggu data`: Pass.

Catatan:

- `flutter clean` sempat memberi warning `.dart_tool` sedang dipakai proses aktif, tetapi `pub get`, analyze, test, dan UI web tetap berhasil.
- `http://127.0.0.1:3000` merespons `HTTP 200`.

## Error Yang Ditemukan

| Error | Penyebab | Perbaikan | Status |
| --- | --- | --- | --- |
| Label snake_case terlalu teknis | UI menampilkan key backend secara langsung | Label UI diganti menjadi human-friendly tanpa mengubah payload backend | Fixed |
| Risk warning terlalu besar di Watchlist | Card memakai warning box penuh | Dibuat compact warning list | Fixed |
| Widget test gagal mengenali Material widget | Import `flutter/material.dart` belum ada | Import ditambahkan | Fixed |

## Known Limitations

- Scoring masih `p0_dummy_scoring_v1`.
- Market data provider belum aktif.
- OHLCV belum aktif.
- AI/RAG belum aktif.
- Chart Lab masih preview.
- News provider belum aktif.
- Tidak ada fitur transaksi saham.

## Status Final

Flutter P1 Feature Adaptation: **Pass dan stabil untuk release freeze P1**.

## Next Step P2 Market Data Provider

1. Pilih provider data market yang legal untuk IDX.
2. Simpan API key hanya di Supabase Edge Functions environment.
3. Buat Edge Function `get-market-context`.
4. Buat schema/cache OHLCV.
5. Buat Edge Function `get-stock-chart-data`.
6. Hubungkan Chart Lab ke OHLCV dan overlay backend.
7. Upgrade Rule Engine dari `p0_dummy_scoring_v1` ke rule version P2.
