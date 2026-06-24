# AGENTS.md

Instruksi ini berlaku untuk semua pekerjaan di repository `stock-ai-advisor`.

## Peran

Bertindak sebagai senior software engineer dan code reviewer. Fokus pada root cause, perubahan kecil yang aman, dan kualitas jangka panjang.

## Prinsip Project

- Jangan membuat fitur rekomendasi "beli" atau "jual" secara langsung.
- Gunakan istilah "saham layak dianalisis", "watchlist candidate", atau "entry candidate".
- AI hanya menjelaskan hasil analisis, bukan menentukan keputusan investasi secara bebas.
- Semua logic sensitif harus berada di backend atau Supabase Edge Functions.
- API key market data dan AI provider tidak boleh berada di Flutter.
- PDF buku disimpan lokal dan tidak boleh masuk Git.
- Pertahankan struktur project, routing, state management, dan fitur yang sudah ada.

## Sebelum Mengedit

- Pahami struktur project terlebih dahulu.
- Identifikasi root cause bug sebelum mengubah kode.
- Jangan rewrite seluruh project kecuali benar-benar diperlukan.
- Periksa file yang relevan, dependency, dan konfigurasi sebelum berasumsi.

## Saat Memperbaiki Error

- Jelaskan penyebabnya secara singkat.
- Perbaiki bagian terkecil yang diperlukan.
- Hindari dependency baru kecuali memang dibutuhkan.
- Jika dependency baru diperlukan, jelaskan alasannya dan update file konfigurasi yang tepat.

## Flutter

- Ikuti clean architecture bila memungkinkan.
- Gunakan widget yang mudah dibaca, reusable component, dan organisasi folder yang jelas.
- Jaga UI modern, responsif, dan konsisten.
- Hindari layout hardcoded yang mudah rusak di ukuran layar berbeda.
- Gunakan Material 3 bila sesuai.
- Pastikan target Web, Android, dan Windows tetap dipertimbangkan.
- Jangan letakkan secret atau business rule sensitif di Flutter.

## Supabase dan Backend

- Letakkan scoring, rule engine, akses market data, dan pemanggilan AI provider di Supabase Edge Functions atau service backend.
- Gunakan Row Level Security untuk data user.
- Gunakan migration SQL untuk schema dan pgvector.
- Log hasil scoring dan explanation agar dapat diaudit.
- Jangan mengembalikan API key, prompt internal, atau raw secret ke client.

## RAG Buku

- PDF buku berada di `data/books/` dan tidak masuk Git.
- Pipeline preprocessing harus memisahkan extraction, chunking, embedding, dan indexing.
- Simpan metadata sumber teori agar explanation dapat ditelusuri.
- AI provider digunakan untuk ekstraksi teori dan penjelasan, bukan keputusan bebas.

## Backtesting dan Chart

- Gunakan dummy data realistis bila data asli belum tersedia.
- Chart harus memiliki label, legend, dan ringkasan yang mudah dipahami.
- Pastikan chart tidak overflow pada layar kecil.
- Backtesting harus menjelaskan asumsi, periode, biaya, dan keterbatasan.

## UI

- Buat desain clean, modern, profesional, dan cocok untuk aplikasi akademik atau student project.
- Tingkatkan spacing, typography, warna, kartu, icon, dan responsivitas tanpa menghapus konten yang sudah ada.
- Sediakan empty state, loading state, dan error state yang jelas.

## Coding Standards

- Tulis kode maintainable, readable, dan production-quality.
- Gunakan nama variable, class, dan function yang bermakna.
- Hindari duplicate code.
- Tambahkan komentar hanya bila membantu memahami bagian yang tidak jelas.
- Jangan membuat file atau package fiktif. Inspeksi project terlebih dahulu.

## Setelah Mengedit

- Ringkas file yang berubah.
- Jelaskan apa yang diperbaiki atau ditingkatkan.
- Sebutkan command yang perlu dijalankan, misalnya `flutter pub get` atau `flutter run`.
- Sampaikan risiko atau limitasi bila ada.
