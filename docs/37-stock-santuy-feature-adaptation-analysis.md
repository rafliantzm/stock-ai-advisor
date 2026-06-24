# 37. Stock Santuy Feature Adaptation Analysis

Dokumen ini mencatat adaptasi konsep fitur dari referensi Stock Santuy ke stock-ai-advisor. Adaptasi hanya mengambil pola manfaat umum untuk edukasi analisis saham. Aplikasi tidak menyalin brand, logo, asset visual, teks persis, nama fitur proprietary, klaim kepastian hasil, atau workflow transaksi.

## Guardrails

- Flutter hanya menjadi UI.
- Edge Functions P0 tetap menjadi backend API stabil.
- Rule Engine tetap menjadi pusat scoring.
- AI/RAG belum digunakan pada P1.
- Market data real-time dan OHLCV provider belum aktif.
- Semua label analisis memakai wording aman: `layak dianalisis`, `watchlist candidate`, `technical setup`, `risk warning`, `invalidation level`, `needs_more_data`, dan `wait confirmation`.
- Tidak ada fitur transaksi saham real.

## Fitur Referensi Yang Dianalisis

| Area referensi | Fungsi umum | Adaptasi aman di stock-ai-advisor |
| --- | --- | --- |
| Watchlist dengan ringkasan score | Membantu user memantau beberapa saham | `Enhanced Watchlist Card` menampilkan latest_score P0, risk warning, dan invalidation level. |
| Detail analisis saham | Mengumpulkan sinyal teknikal, fundamental, dan risiko | `StockDetailScreen` menampilkan Price Snapshot sample, Insight Utama, Multi-Mode Analyzer, Technical Signals, Fundamental Snapshot, Risk Analysis, Strategy Explanation, dan Calculator Edukatif. |
| Mode analisis berbeda | Membandingkan konteks observasi jangka pendek dan menengah | `Multi-Mode Analyzer` memakai mode Day Trade, Swing, Hold Dividend, dan Potential Bagger dengan label edukatif. |
| Screener kategori | Menyaring kandidat berdasarkan tema | `ScreenerScreen` memakai kategori P1 dan menampilkan empty state jika preset belum ada di backend. |
| Market context | Memberi konteks indeks dan kondisi pasar | `MarketContextScreen` berisi sample market context dengan label provider belum aktif. |
| Chart lab | Menyiapkan overlay teknikal | `ChartLabScreen` menampilkan preview overlay tanpa klaim real-time. |
| Risk calculator | Membantu simulasi risiko | `RiskCalculatorCard` menghitung estimasi ukuran posisi edukatif dengan disclaimer. |
| News/catalyst | Menampilkan berita dan corporate action | Placeholder dengan empty state `News provider belum aktif.` |

## Fitur Yang Tidak Boleh Disalin

- Nama brand, logo, icon, asset visual, dan gaya komunikasi khas referensi.
- Copy teks, klaim, atau alur proprietary.
- Klaim kepastian hasil atau instruksi eksekusi transaksi.
- Broker summary real jika data broker tidak tersedia.
- News/catalyst real tanpa provider resmi dan attribution yang jelas.

## Wording Yang Diganti Agar Aman

| Konteks sensitif | Wording aman |
| --- | --- |
| Instruksi eksekusi transaksi | `watchlist candidate`, `layak dianalisis`, `pantau`, `wait confirmation` |
| Klaim hasil pasti | `needs_more_data`, `sample`, `provider belum aktif` |
| Sinyal teknikal | `technical setup`, `strategy overlay preview` |
| Risiko | `risk warning`, `risk regime`, `invalidation level` |
| Kandidat harian | `Daily Watchlist Candidates`, `Kandidat Watchlist Harian` |

## Mapping Fitur Ke Screen Flutter

| Fitur P1 | Screen/komponen |
| --- | --- |
| Enhanced Watchlist Card | `lib/features/watchlist/watchlist_screen.dart` |
| Stock Detail Analysis | `lib/features/stock_detail/stock_detail_screen.dart` |
| Multi-Mode Analyzer | `StockDetailScreen` |
| Risk Calculator Edukatif | `lib/features/stock_detail/widgets/risk_calculator_card.dart` |
| Screener Categories Upgrade | `lib/features/screener/screener_screen.dart` |
| Daily Watchlist Candidates | `ScreenerScreen` |
| Market Context / IHSG Placeholder | `lib/features/market_context/market_context_screen.dart` |
| Chart Lab Placeholder | `lib/features/chart_lab/chart_lab_screen.dart` |
| News / Catalyst Placeholder | `StockDetailScreen` dan `MarketContextScreen` |

## Keputusan Desain

- P1 memakai adapter model `StockAnalysis` dari `latest_score`, bukan scoring baru di Flutter.
- Data sample selalu diberi label eksplisit agar tidak terlihat seperti data market real.
- Kategori screener yang belum didukung backend ditampilkan sebagai empty state, bukan fake result.
- Edge Functions P0 tidak diubah.
