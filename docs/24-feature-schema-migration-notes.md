# 24. Feature Schema Migration Notes

Migration:

```text
supabase/migrations/0003_create_user_feature_schema.sql
```

Scope migration ini hanya schema database untuk fitur user aplikasi `stock-ai-advisor`. Belum ada Edge Functions, belum ada Flutter UI, belum ada API provider, dan belum ada fitur transaksi saham real.

## Tabel yang Dibuat

User-owned:

- `watchlists`
- `watchlist_items`
- `watchlist_scores`
- `user_alerts`
- `alert_conditions`
- `alert_logs`
- `user_saved_screeners`
- `screener_results`
- `event_alerts`
- `insight_feed_items`
- `portfolio_simulations`
- `portfolio_positions`

System/provider-backed:

- `screener_presets`
- `screener_filters`
- `stock_financials`
- `financial_growth_metrics`
- `fundamental_scorecards`
- `chart_analysis_runs`
- `market_events`
- `corporate_actions`
- `accumulation_distribution_insights`

## Ringkasan Fitur yang Didukung

- Watchlist dan watchlist scoring.
- Smart alert dan alert logs.
- Screener preset, filter, saved screener, dan screener results.
- Fundamental scorecard dan financial metrics.
- Chart Lab analysis run cache/audit.
- Market event calendar dan corporate actions.
- Insight feed personal.
- Portfolio simulation tanpa transaksi real.
- Accumulation/distribution insight berbasis proxy volume-price.

## Dependency Schema

Migration ini bergantung pada:

```text
supabase/migrations/0000_create_base_app_schema.sql
```

Relasi yang digunakan:

- `user_id -> profiles(user_id)`, agar tetap cocok dengan `auth.uid()` di RLS.
- `symbol_id -> symbols(id)`.
- `symbol_code` tetap disimpan untuk display, lookup, dan fallback saat integrasi data market.

Migration lanjutan:

```text
supabase/migrations/0004_backfill_feature_foreign_keys.sql
```

Migration `0004` memastikan FK tetap ada pada database yang mungkin pernah menjalankan versi lama `0003`, sekaligus melakukan backfill `symbol_id` dari `symbol_code`.

## RLS Draft

RLS diaktifkan untuk tabel milik user dan child table-nya:

- User hanya bisa mengakses watchlist miliknya.
- User hanya bisa mengakses item dan score lewat watchlist miliknya.
- User hanya bisa mengakses alert dan condition/log miliknya.
- User hanya bisa mengakses saved screener dan screener result miliknya.
- User hanya bisa mengakses event alert dan insight feed miliknya.
- User hanya bisa mengakses portfolio simulation dan positions miliknya.

Tabel system/provider-backed belum diberi public read policy di migration ini. Access final sebaiknya lewat Supabase Edge Functions sampai rule akses data selesai.

## Status Field

Tabel memakai status aman:

- `active`
- `inactive`
- `pending`
- `triggered`
- `archived`

Status ini tidak merepresentasikan instruksi transaksi.

## Cara Menjalankan Migration

Dari root project:

```bash
supabase db push
```

Untuk local development dengan Supabase CLI:

```bash
supabase start
supabase db reset
```

Gunakan `db reset` hanya untuk environment lokal karena akan membangun ulang database lokal.

## Next Step

Langkah berikutnya yang direkomendasikan:

1. Buat base schema untuk `profiles` dan master saham `symbols` atau `stocks`.
2. Tambahkan migration FK lanjutan setelah base schema stabil.
3. Seed `screener_presets` dan `screener_filters` dengan preset edukatif.
4. Rancang Edge Functions P0:
   - `get-watchlist`
   - `add-watchlist-item`
   - `remove-watchlist-item`
   - `evaluate-watchlist`
   - `create-alert`
   - `run-screener`

AI, RAG buku, dan Rule Engine tetap berada di backend layer. Flutter hanya menggunakan API hasil Edge Functions.
