# 19. Feature Adaptation Roadmap

Roadmap ini mengurutkan fitur berdasarkan nilai MVP, risiko teknis, ketersediaan data, dan kepatuhan terhadap batasan project.

## Prinsip Implementasi

- Rule Engine menjadi pusat keputusan.
- AI hanya explanation layer.
- RAG buku hanya menjadi sumber teori untuk explanation.
- Edge Functions menangani logic sensitif.
- Flutter hanya menampilkan UI, input user, dan state.
- Hindari fitur yang membutuhkan broker execution atau data proprietary bila belum tersedia.

## MVP Priority

| Priority | Feature | Alasan |
| --- | --- | --- |
| P0 | AI Watchlist | Fondasi pengalaman user dan tempat menampilkan score. |
| P0 | Smart Alert | Nilai praktis tinggi, bisa berbasis rule sederhana. |
| P0 | AI Stock Screener | Menghubungkan rule engine dengan discovery saham. |
| P0 | Fundamental Scorecard | Aman, edukatif, dan berbasis data terstruktur. |
| P1 | AI Chart Lab | Berguna, tetapi butuh kualitas data OHLCV dan indikator yang konsisten. |
| P1 | Market Event Calendar | Berguna untuk risk awareness, bergantung data event. |
| P1 | AI Insight Feed | Perlu banyak sumber event internal agar feed tidak kosong. |
| P2 | Portfolio Simulation | Perlu model asumsi, price history, dan UX risiko. |
| P2 | Accumulation/Distribution Insight | Berguna, tetapi perlu disclaimer kuat bila hanya proxy OHLCV. |

## Phase 1 - Core Data and Watchlist

Build:

- `watchlists`
- `watchlist_items`
- `watchlist_scores`
- Edge Functions: `get-watchlist`, `add-watchlist-item`, `remove-watchlist-item`, `evaluate-watchlist`
- Flutter: `WatchlistScreen`, watchlist section di `StockDetailScreen`

Deliverable:

- User dapat membuat watchlist dan melihat status `layak dianalisis`.
- Score tersimpan dengan rule version.

## Phase 2 - Alerts and Screener

Build:

- `user_alerts`
- `alert_conditions`
- `alert_logs`
- `screener_presets`
- `screener_filters`
- `user_saved_screeners`
- `screener_results`
- Edge Functions: `create-alert`, `evaluate-alerts`, `run-screener`
- Flutter: `SmartAlertScreen`, `ScreenerScreen`, `ScreenerResultScreen`

Deliverable:

- Alert dapat dibuat, dievaluasi backend, dan dicatat.
- Screener menghasilkan `watchlist candidate`, bukan rekomendasi transaksi.

## Phase 3 - Fundamental and Chart Lab

Build:

- `stock_financials`
- `financial_growth_metrics`
- `fundamental_scorecards`
- `chart_analysis_runs`
- Edge Functions: `get-fundamental-scorecard`, `get-stock-chart-analysis`
- Flutter: `FundamentalScorecardScreen`, `ChartLabScreen`

Deliverable:

- User melihat kualitas fundamental dan technical setup dari backend.
- Explanation hanya menjelaskan score.

## Phase 4 - Event Calendar and Insight Feed

Build:

- `market_events`
- `corporate_actions`
- `event_alerts`
- `insight_feed_items`
- Edge Functions: `get-market-calendar`, `get-ai-insight-feed`
- Flutter: `MarketCalendarScreen`, `InsightFeedScreen`

Deliverable:

- Event penting muncul di calendar dan feed.
- Feed bersifat personal berdasarkan watchlist, alert, dan screener.

## Phase 5 - Simulation and Volume-Price Insight

Build:

- `portfolio_simulations`
- `portfolio_positions`
- `accumulation_distribution_insights`
- Edge Functions: `run-portfolio-simulation`, `get-accumulation-distribution-insight`
- Flutter: `PortfolioSimulationScreen`, section insight di `StockDetailScreen`

Deliverable:

- User dapat menjalankan simulasi portofolio.
- Volume-price insight tampil dengan label proxy dan keterbatasan.

## Fitur yang Ditunda

- Real order placement: di luar scope dan berisiko legal.
- Broker summary real: ditunda sampai ada sumber data resmi/licensed.
- OCR massal buku: ditunda sampai batch digital text selesai dan pipeline OCR manual disiapkan.
- Social/community feed: kompleks moderation tinggi dan tidak diperlukan untuk MVP.
- Push notification realtime: mulai dari alert logs dulu, push dapat menyusul.

## Technical Reasons

- Screener dan watchlist membutuhkan scoring yang auditable lebih dulu.
- Alert harus punya logs agar tidak ambigu saat kondisi terpicu.
- Chart Lab membutuhkan data OHLCV bersih agar level teknikal tidak misleading.
- Fundamental Scorecard membutuhkan mapping laporan keuangan yang stabil.
- Insight Feed bergantung event internal; dibangun setelah watchlist, alert, screener, dan calendar tersedia.
