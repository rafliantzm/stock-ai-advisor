# Development Roadmap

Roadmap ini memecah pembangunan `stock-ai-advisor` menjadi tahap kecil agar mudah diuji dan tidak mencampur logic sensitif ke Flutter.

## Phase 0 - Repository Foundation

- Buat struktur folder awal.
- Tambahkan README, AGENTS, architecture, roadmap, dan `.gitignore`.
- Tetapkan istilah aman: saham layak dianalisis, watchlist candidate, entry candidate.
- Pastikan PDF buku, dataset lokal, secret, dan build output tidak masuk Git.

## Phase 1 - Flutter Skeleton

- Buat Flutter app di `apps/mobile`.
- Aktifkan Material 3.
- Siapkan routing dasar.
- Buat halaman:
  - splash/session gate
  - login
  - dashboard
  - symbol detail
  - watchlist candidate
  - settings
- Tambahkan state untuk loading, empty, dan error.

Acceptance criteria:

- App dapat berjalan minimal di Web dan Android emulator.
- Tidak ada secret backend di source Flutter.
- UI responsif untuk layar kecil dan desktop.

## Phase 2 - Supabase Schema

- Inisialisasi Supabase folder.
- Buat migration untuk tabel awal:
  - profiles
  - symbols
  - market_snapshots
  - analysis_rules
  - score_runs
  - watchlist_candidates
  - book_sources
  - book_chunks
  - backtest_runs
  - backtest_results
- Aktifkan extension pgvector.
- Tambahkan RLS policy awal.

Acceptance criteria:

- Migration dapat dijalankan ulang di environment baru.
- RLS tidak mengekspos data user lain.
- Service role hanya dipakai backend.

## Phase 3 - Python Preprocessing RAG

- Buat modul ekstraksi PDF lokal.
- Buat cleaning dan chunking.
- Buat embedding pipeline.
- Simpan metadata buku dan chunk ke Supabase.
- Tambahkan script validasi jumlah chunk dan metadata sumber.

Acceptance criteria:

- PDF tetap lokal dan tidak masuk Git.
- Setiap chunk punya sumber yang bisa ditelusuri.
- Pipeline bisa dijalankan ulang tanpa duplikasi liar.

## Phase 4 - Indicator dan Rule Engine

- Buat modul indikator teknikal dan fundamental dasar.
- Definisikan format input dan output rule engine.
- Versioning rule.
- Tambahkan label aman seperti `watchlist_candidate` dan `entry_candidate`.
- Tambahkan unit test untuk edge case.

Acceptance criteria:

- Tidak ada istilah rekomendasi transaksi langsung.
- Output rule engine deterministic.
- Hasil scoring menyimpan versi rule.

## Phase 5 - Supabase Edge Functions

- Buat endpoint `score-symbol`.
- Buat endpoint `explain-score`.
- Buat endpoint refresh data market.
- Simpan audit log setiap run.
- Tambahkan validasi input dan error response standar.

Acceptance criteria:

- API key hanya di environment backend.
- Flutter tidak dapat memanggil provider market data atau AI secara langsung.
- Explanation selalu berbasis hasil rule engine.

## Phase 6 - Backtesting

- Buat engine backtesting Python.
- Tambahkan asumsi biaya, periode, dan universe saham.
- Simpan hasil ringkas ke Supabase.
- Tampilkan chart dan summary di Flutter.

Acceptance criteria:

- Backtest mencantumkan asumsi dan keterbatasan.
- Chart tidak overflow di layar kecil.
- Hasil backtest tidak dipresentasikan sebagai jaminan performa masa depan.

## Phase 7 - Dashboard dan UX Polish

- Tambahkan dashboard kandidat.
- Tambahkan symbol detail dengan ringkasan indikator.
- Tambahkan explanation panel.
- Tambahkan chart dengan label dan legend.
- Tambahkan empty, loading, dan error state yang konsisten.

Acceptance criteria:

- UI modern, profesional, dan cocok untuk aplikasi akademik.
- Tidak ada wording "beli" atau "jual" sebagai rekomendasi.
- Semua data sensitif tetap berasal dari backend.

## Phase 8 - Hardening

- Tambahkan test untuk Edge Functions dan Python modules.
- Tambahkan linting.
- Tambahkan dokumentasi environment variable.
- Review RLS policy.
- Review dependency dan secret exposure.

Acceptance criteria:

- Build Flutter berjalan.
- Test utama berjalan.
- Tidak ada PDF, `.env`, API key, atau generated build output yang masuk Git.
