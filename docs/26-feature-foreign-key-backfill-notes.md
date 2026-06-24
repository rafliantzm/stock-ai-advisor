# 26. Feature Foreign Key Backfill Notes

Migration:

```text
supabase/migrations/0004_backfill_feature_foreign_keys.sql
```

Tujuan migration ini:

- Backfill `symbol_id` dari `symbol_code` untuk tabel fitur.
- Membersihkan `symbol_id` orphan dengan mengubahnya menjadi `null`.
- Memastikan FK `user_id -> profiles(user_id)` tersedia untuk tabel milik user.
- Memastikan FK `symbol_id -> symbols(id)` tersedia untuk tabel yang menyimpan saham.

## Kenapa Ada Migration 0004

Migration `0003_create_user_feature_schema.sql` sudah memakai FK inline ke `profiles(user_id)` dan `symbols(id)`. `0004` tetap dibuat agar aman untuk database yang mungkin pernah menjalankan versi lama `0003` sebelum FK ditambahkan.

Migration ini idempotent: jika FK ekuivalen sudah ada, migration tidak menambahkan duplikat.

## Backfill Symbol

Backfill dilakukan dengan mencocokkan:

```text
upper(feature_table.symbol_code) = upper(symbols.symbol_code)
```

Jika ada lebih dari satu symbol dengan kode sama, migration memprioritaskan exchange `IDX`, lalu symbol paling awal dibuat.

Tabel yang dibackfill:

- `watchlist_items`
- `watchlist_scores`
- `user_alerts`
- `alert_logs`
- `screener_results`
- `stock_financials`
- `financial_growth_metrics`
- `fundamental_scorecards`
- `chart_analysis_runs`
- `corporate_actions`
- `insight_feed_items`
- `portfolio_positions`
- `accumulation_distribution_insights`

## FK User

FK user memakai:

```text
profiles(user_id)
```

Ini dipilih karena `profiles.user_id` adalah mapping langsung ke `auth.users(id)`, sehingga tetap cocok dengan policy RLS berbasis `auth.uid()`.

Sebelum FK ditambahkan, migration membuat profile minimal untuk data fitur lama jika `user_id` tersebut ada di `auth.users` tetapi belum ada di `profiles`.

## FK Symbol

FK symbol memakai:

```text
symbols(id)
```

`symbol_code` tetap disimpan untuk display, lookup, import data market, dan fallback integrasi provider.

## Cara Menjalankan

Local:

```bash
supabase start
supabase db reset
```

Remote:

```bash
supabase db push
```

## Catatan

Migration ini tidak membuat Edge Functions, Flutter UI, API provider, atau fitur transaksi saham real.
