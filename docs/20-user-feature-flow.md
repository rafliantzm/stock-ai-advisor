# 20. User Feature Flow

Dokumen ini menjelaskan alur user untuk setiap fitur tanpa menyalin workflow produk lain.

## 1. AI Watchlist

Flow:

1. User membuka `WatchlistScreen`.
2. User menambahkan simbol saham.
3. Flutter memanggil `add-watchlist-item`.
4. Backend menyimpan item dan menjalankan scoring awal.
5. User melihat label seperti `layak dianalisis`, `watchlist candidate`, `risk warning`, dan timestamp.

Skenario:

User menambahkan `BBCA`. Sistem menampilkan score fundamental dan technical setup. AI explanation menjelaskan alasan score berdasarkan rule, bukan memberi instruksi transaksi.

## 2. Smart Alert

Flow:

1. User membuka `SmartAlertScreen`.
2. User memilih simbol dan tipe kondisi.
3. User mengisi threshold, misalnya price near support atau score change.
4. Flutter memanggil `create-alert`.
5. Backend mengevaluasi alert berkala lewat `evaluate-alerts`.
6. Alert yang aktif masuk ke `alert_logs` dan muncul sebagai notifikasi/in-app feed.

Skenario:

User membuat alert jika harga mendekati support dan volume naik. Sistem menampilkan "technical setup perlu dicek" dengan invalidation level.

## 3. AI Stock Screener

Flow:

1. User membuka `ScreenerScreen`.
2. User memilih preset atau membuat filter.
3. Flutter memanggil `run-screener`.
4. Backend menjalankan filter dan scoring.
5. User melihat `ScreenerResultScreen`.
6. User dapat menyimpan hasil ke watchlist.

Skenario:

User memilih preset `Volume Price Setup`. Sistem menampilkan daftar saham `watchlist candidate` dengan alasan volume-price dan risk warning.

## 4. AI Chart Lab

Flow:

1. User membuka `StockDetailScreen`.
2. User masuk ke `ChartLabScreen`.
3. Flutter memanggil `get-stock-chart-analysis`.
4. Backend menghitung support/resistance, trendline, volume-price, dan invalidation level.
5. UI menampilkan chart dan panel explanation.

Skenario:

Saham mendekati resistance. Sistem menandai setup belum valid dan menampilkan invalidation level jika harga gagal bertahan.

## 5. Fundamental Scorecard

Flow:

1. User membuka `FundamentalScorecardScreen`.
2. Flutter memanggil `get-fundamental-scorecard`.
3. Backend membaca financial metrics dan scorecard.
4. UI menampilkan kategori valuation, profitability, growth, leverage, dan quality.

Skenario:

Saham punya ROE stabil namun DER tinggi. Sistem memberi `risk warning` dan AI menjelaskan trade-off berdasarkan score.

## 6. Market Event Calendar

Flow:

1. User membuka `MarketCalendarScreen`.
2. Flutter memanggil `get-market-calendar`.
3. Backend mengembalikan market events dan corporate actions.
4. User dapat membuat `event_alerts` untuk simbol tertentu.

Skenario:

Ada jadwal dividen di watchlist. Sistem menampilkan event dan potensi dampak yang perlu dianalisis.

## 7. AI Insight Feed

Flow:

1. User membuka `InsightFeedScreen`.
2. Flutter memanggil `get-ai-insight-feed`.
3. Backend menggabungkan watchlist score changes, alert logs, screener results, dan events.
4. AI merapikan explanation berdasarkan rule output dan teori dari RAG buku bila tersedia.

Skenario:

Feed menampilkan "3 watchlist candidate mengalami perubahan score" dan "1 risk warning muncul karena volatilitas naik".

## 8. Portfolio Simulation

Flow:

1. User membuka `PortfolioSimulationScreen`.
2. User membuat simulasi dan memasukkan posisi virtual.
3. Flutter memanggil `run-portfolio-simulation`.
4. Backend menghitung allocation, risk exposure, scenario, dan backtest summary.
5. UI menampilkan hasil simulasi dan limitation.

Skenario:

User mencoba alokasi 40 persen di satu sektor. Sistem memberi risk concentration warning, bukan instruksi transaksi.

## 9. Accumulation/Distribution Insight

Flow:

1. User membuka section volume-price di `StockDetailScreen`.
2. Flutter memanggil `get-accumulation-distribution-insight`.
3. Backend menghitung proxy berbasis OHLCV.
4. UI menampilkan label seperti accumulation pressure, distribution pressure, neutral, atau inconclusive.

Skenario:

Harga sideways dengan volume meningkat dan close di dekat high range. Sistem memberi insight "accumulation pressure proxy" dengan catatan bahwa ini bukan broker summary.
