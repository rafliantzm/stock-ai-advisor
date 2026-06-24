# 18. Feature Benchmark and Safe Adaptation

Dokumen ini memakai aplikasi saham modern sebagai referensi fungsi umum, bukan untuk menyalin brand, nama fitur, UI, copywriting, atau workflow. `stock-ai-advisor` tetap menjadi aplikasi analisis edukatif dengan Rule Engine sebagai pusat keputusan.

## Guardrails

- Tidak ada fitur transaksi saham real.
- Tidak ada klaim keputusan transaksi langsung atau jaminan hasil.
- Gunakan istilah: `layak dianalisis`, `watchlist candidate`, `technical setup`, `smart alert`, `risk warning`, `invalidation level`.
- Flutter hanya UI dan state presentasi.
- Supabase Edge Functions menangani scoring, alert evaluation, screener, event matching, dan API provider.
- AI hanya menjelaskan hasil Rule Engine, bukan membuat keputusan bebas.
- RAG buku hanya menjadi sumber teori untuk explanation, bukan sumber scoring utama.
- Jika data broker summary real tidak tersedia, fitur akumulasi/distribusi memakai proxy volume-price yang aman dan diberi label keterbatasan.

## Fitur Referensi dan Adaptasi

| Referensi fungsi umum | Fungsi | Adaptasi aman di stock-ai-advisor | Batasan |
| --- | --- | --- | --- |
| Watchlist | Menyimpan daftar saham yang dipantau user. | `AI Watchlist`: daftar simbol yang diperkaya score, alasan rule, risk warning, dan status `watchlist candidate`. | Tidak menjadi daftar rekomendasi transaksi. |
| Price alert | Memberi notifikasi saat kondisi tertentu tercapai. | `Smart Alert`: kondisi price, volume, technical setup, invalidation level, dan event warning. | Evaluasi kondisi di Edge Functions, bukan Flutter. |
| Screener | Menyaring saham berdasarkan kriteria teknikal/fundamental. | `AI Stock Screener`: filter rule-based dengan explanation dari AI. | AI tidak memilih saham bebas; hanya menjelaskan hasil filter. |
| Charting dan indikator | Membantu analisis grafik. | `AI Chart Lab`: chart, support/resistance, trend, volume-price, dan technical setup yang dihitung backend. | Tidak menggambar sinyal beli/jual eksplisit. |
| Fundamental data | Menampilkan rasio dan laporan keuangan. | `Fundamental Scorecard`: profitability, growth, leverage, valuation, cash flow, dan quality checks. | Data tergantung provider dan periode laporan. |
| News dan research feed | Menampilkan berita, laporan, atau ide pasar. | `AI Insight Feed`: feed insight berbasis event, score changes, screener result, dan RAG explanation. | Tidak membuat opini investasi bebas. |
| Corporate actions dan calendar | Mengingatkan jadwal dividen, stock split, right issue, IPO, laporan keuangan. | `Market Event Calendar`: event pasar, aksi korporasi, dan alert event. | Bergantung kelengkapan data market/corporate action. |
| Virtual trading atau portfolio tracking | Simulasi performa tanpa uang real. | `Portfolio Simulation`: simulasi posisi, risk exposure, drawdown, dan scenario analysis. | Bukan order real dan bukan jaminan performa. |
| Broker/flow insight | Membantu membaca aktivitas market participant. | `Accumulation/Distribution Insight`: versi aman berbasis volume-price, range close, OBV/ADL-like proxy. | Tidak mengklaim broker accumulation jika data broker tidak tersedia. |

## Feature Concepts

### 1. AI Watchlist

Membantu user memantau saham yang `layak dianalisis` berdasarkan scoring backend. Setiap item menampilkan latest score, label kandidat, alasan rule, risk warning, invalidation level, dan timestamp evaluasi.

### 2. Smart Alert

Alert berbasis kondisi yang dapat diuji ulang: price level, volume spike, breakout kandidat, support/resistance proximity, score change, event calendar, dan invalidation level. Alert memakai wording seperti "kondisi analisis terpenuhi".

### 3. AI Stock Screener

Screener menggabungkan kriteria teknikal dan fundamental. Preset awal sebaiknya edukatif: `Volume Price Setup`, `Fundamental Quality`, `Risk Controlled Setup`, dan `Event Watch`.

### 4. AI Chart Lab

Ruang analisis grafik yang menampilkan chart, level teknikal, setup summary, dan explanation. Output utama: `technical setup`, `risk warning`, dan `invalidation level`.

### 5. Fundamental Scorecard

Scorecard mengubah data laporan keuangan menjadi panel yang mudah dibaca: valuation, growth, profitability, leverage, liquidity, dividend, dan consistency.

### 6. Market Event Calendar

Calendar untuk corporate actions, earnings/report dates, macro events, market holidays, dan watchlist-linked alerts.

### 7. AI Insight Feed

Feed personal berisi perubahan penting: score watchlist berubah, alert terpicu, event dekat, screener menemukan kandidat, atau risk warning muncul.

### 8. Portfolio Simulation

Simulasi portofolio tanpa transaksi real. Fokus ke risk exposure, allocation, drawdown, scenario, dan backtest-linked assumptions.

### 9. Accumulation/Distribution Insight

Insight volume-price yang aman. Jika hanya OHLCV tersedia, pakai indikator seperti Accumulation/Distribution Line style, OBV style, volume spike, close location value, dan range expansion. Tampilkan sebagai proxy, bukan broker summary.

## Legal and Technical Boundaries

- Jangan memakai nama fitur dari aplikasi referensi sebagai nama fitur final.
- Jangan menyalin layout, ikon, copy, warna brand, atau flow persis.
- Jangan menyediakan order placement, order book trading action, atau broker execution.
- Jangan mengklaim akurasi prediksi atau hasil investasi.
- Semua score dan label harus versioned dan auditable.
- Explanation harus menyebut keterbatasan data.
- Untuk event/news, tampilkan sumber data dan timestamp.

## Public Reference Notes

Benchmark ini disusun dari fitur publik yang umum terlihat pada aplikasi saham modern, termasuk watchlist, screener, charting, alert, fundamental data, news, corporate actions, dan virtual trading. Adaptasi di dokumen ini sengaja dibuat berbeda secara nama, UI, dan workflow agar sesuai dengan tujuan edukatif `stock-ai-advisor`.
