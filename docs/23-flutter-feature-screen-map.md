# 23. Flutter Feature Screen Map

Dokumen ini memetakan screen Flutter untuk fitur aplikasi. Flutter hanya UI, navigation, form input, dan state rendering. Logic scoring, screener, alert evaluation, chart analysis, dan explanation tetap di Supabase Edge Functions.

## Navigation Structure

Recommended bottom navigation:

- Watchlist
- Screener
- Insights
- Calendar
- Simulation

Stock detail, Chart Lab, Fundamental Scorecard, dan Smart Alert editor dibuka dari screen terkait.

## WatchlistScreen

Purpose:

- Menampilkan watchlist user.
- Menampilkan score terbaru, status `layak dianalisis`, risk warning, dan invalidation level.

UI sections:

- Watchlist selector
- Search/add symbol
- Candidate cards/list rows
- Score refresh state
- Empty state untuk watchlist kosong

Backend:

- `get-watchlist`
- `add-watchlist-item`
- `remove-watchlist-item`
- `evaluate-watchlist`

## SmartAlertScreen

Purpose:

- Membuat dan mengelola smart alert.

UI sections:

- Active alerts
- Trigger history
- Alert condition form
- Cooldown and active toggle
- Risk wording preview

Backend:

- `create-alert`
- Alert logs dari `get-ai-insight-feed` atau endpoint khusus nanti

## ScreenerScreen

Purpose:

- Memilih preset atau membuat filter screener.

UI sections:

- Preset chips
- Filter builder
- Risk and data availability notice
- Run button
- Saved screeners

Backend:

- `run-screener`

## ScreenerResultScreen

Purpose:

- Menampilkan hasil screener sebagai `watchlist candidate`.

UI sections:

- Result summary
- Sort/filter result
- Candidate rows
- Matched filter details
- Add to watchlist action

Backend:

- `run-screener`
- `add-watchlist-item`

## StockDetailScreen

Purpose:

- Hub utama untuk satu simbol saham.

UI sections:

- Symbol header
- Latest backend score
- Technical setup summary
- Fundamental summary
- Risk warning
- Invalidation level
- Related events
- Entry points ke Chart Lab, Fundamental Scorecard, Smart Alert

Backend:

- `get-stock-chart-analysis`
- `get-fundamental-scorecard`
- `get-accumulation-distribution-insight`

## ChartLabScreen

Purpose:

- Analisis chart berbasis backend.

UI sections:

- OHLCV chart
- Support/resistance levels
- Trendline/channel summary
- Volume-price insight
- Technical setup explanation
- Invalidation level panel

Backend:

- `get-stock-chart-analysis`

States:

- Loading chart data
- Data unavailable
- Partial analysis
- Risk warning present

## FundamentalScorecardScreen

Purpose:

- Menampilkan kesehatan fundamental.

UI sections:

- Overall fundamental score
- Valuation card
- Profitability card
- Growth card
- Leverage/liquidity card
- Cash flow card
- Risk flags
- Period selector

Backend:

- `get-fundamental-scorecard`

## MarketCalendarScreen

Purpose:

- Menampilkan event pasar dan aksi korporasi.

UI sections:

- Calendar/list toggle
- Watchlist-related events
- Corporate actions
- Macro/market events
- Event alert action

Backend:

- `get-market-calendar`
- Future: event alert create endpoint if separated from smart alert

## InsightFeedScreen

Purpose:

- Feed personal berisi insight aman dari watchlist, alert, screener, event, dan risk warning.

UI sections:

- Priority filter
- Insight cards
- Source badge
- Read/unread state
- Link to symbol detail

Backend:

- `get-ai-insight-feed`

## PortfolioSimulationScreen

Purpose:

- Simulasi portofolio virtual.

UI sections:

- Simulation selector
- Virtual position editor
- Allocation chart
- Risk concentration panel
- Scenario results
- Backtest assumption notice

Backend:

- `run-portfolio-simulation`

## Shared UI Components

- `CandidateStatusBadge`
- `RiskWarningBanner`
- `InvalidationLevelChip`
- `ScoreBreakdownCard`
- `BackendExplanationPanel`
- `DataFreshnessLabel`
- `EmptyStateView`
- `AsyncErrorView`

## Responsive Notes

- Mobile: prioritize list-first navigation and bottom sheets for filters.
- Tablet/desktop: use two-pane layout for screener results and stock detail.
- Charts must have stable height and avoid overflow.
- Long labels should wrap cleanly.
- Do not use transaction wording in buttons.

## Safe Button Labels

Use:

- Add to Watchlist
- Analyze Setup
- Create Smart Alert
- View Risk Warning
- Run Simulation
- Compare Score

Avoid:

- Label transaksi langsung
- Klaim hasil pasti
- Copywriting yang terdengar seperti instruksi eksekusi order
