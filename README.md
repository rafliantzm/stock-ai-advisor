# stock-ai-advisor

`stock-ai-advisor` adalah fondasi sistem analisis saham berbasis Flutter, Supabase, RAG buku, rule engine, backtesting, dan realtime scoring API.

Project ini tidak dirancang untuk memberi rekomendasi langsung seperti "beli" atau "jual". Output sistem menggunakan istilah seperti:

- saham layak dianalisis
- watchlist candidate
- entry candidate

Keputusan investasi tetap berada di pengguna. AI hanya menjelaskan hasil analisis yang sudah dihitung oleh rule engine dan backend.

## Tujuan

- Menyediakan aplikasi Flutter untuk melihat hasil analisis saham secara modern dan responsif.
- Menyimpan auth, profil, data analisis, embedding, dan audit log di Supabase.
- Menggunakan pgvector untuk pencarian teori dari buku lokal yang sudah diproses.
- Menjalankan logic sensitif di Supabase Edge Functions, bukan di Flutter.
- Memisahkan preprocessing buku, indikator saham, dan backtesting ke tooling Python.
- Menyediakan API scoring realtime yang dapat diaudit dan diuji.

## Stack

- Flutter untuk mobile app, web, Android, dan Windows bila memungkinkan.
- Supabase untuk Auth, Postgres, pgvector, Storage kecil, dan Edge Functions.
- Python untuk preprocessing buku, indikator saham, backtesting, dan eksperimen offline.
- Supabase Edge Functions untuk API backend.
- AI provider hanya untuk ekstraksi teori dan explanation, bukan keputusan bebas.

## Struktur Folder

```text
stock-ai-advisor/
  apps/
    mobile/                  # Flutter app
  data/
    books/                   # PDF buku lokal, tidak masuk Git
    market/                  # Dataset lokal atau cache riset, tidak masuk Git
  docs/
    architecture.md
    development-roadmap.md
  python/
    backtesting/             # Engine dan eksperimen backtesting
    common/                  # Helper Python lintas modul
    indicators/              # Kalkulasi indikator teknikal/fundamental
    preprocessing/           # Ekstraksi PDF, chunking, embedding, indexing
  supabase/
    functions/               # Supabase Edge Functions
    migrations/              # Schema SQL dan pgvector
    seed/                    # Seed data non-secret
  tests/                     # Test integrasi/unit lintas modul
```

## Prinsip Keamanan

- Jangan menyimpan API key market data atau AI provider di Flutter.
- Simpan secret di environment Supabase atau environment lokal yang tidak masuk Git.
- PDF buku disimpan lokal di `data/books/` dan diabaikan oleh Git.
- Semua rule engine, scoring, dan logic sensitif dijalankan di backend.
- Flutter hanya menampilkan data, meminta analisis, dan merender explanation.

## Status Awal

Fondasi repository sudah disiapkan untuk pengembangan bertahap. Langkah berikutnya adalah membuat Flutter app di `apps/mobile`, menginisialisasi Supabase project, lalu menambahkan pipeline Python secara bertahap.

## Perintah Awal yang Umum

```bash
# Membuat Flutter app nanti di folder yang sudah disiapkan
cd apps
flutter create mobile

# Menjalankan Flutter app
cd mobile
flutter pub get
flutter run
```

Untuk Supabase dan Python, lihat [docs/architecture.md](docs/architecture.md) dan [docs/development-roadmap.md](docs/development-roadmap.md).
