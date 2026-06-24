# 27. Supabase Web Migration Runbook

Runbook ini dipakai jika migration dijalankan lewat Supabase Dashboard atau SQL Editor, bukan lewat Supabase CLI remote.

## Scope

Dokumen ini hanya membahas cara menjalankan SQL schema dan seed lewat Supabase Web. Tidak ada Flutter UI, tidak ada Edge Functions, dan tidak ada fitur transaksi saham real.

## Urutan Migration

Jalankan SQL dalam urutan berikut:

1. `supabase/migrations/0000_create_base_app_schema.sql`
2. `supabase/migrations/0003_create_user_feature_schema.sql`
3. `supabase/migrations/0004_backfill_feature_foreign_keys.sql`
4. `supabase/seed/0000_base_seed.sql`

Catatan:

- `0000` harus berjalan sebelum `0003` karena `0003` memakai FK ke `profiles(user_id)` dan `symbols(id)`.
- `0004` harus berjalan setelah `0003` karena melakukan backfill dan memastikan FK fitur.
- Seed base data dijalankan setelah tabel base tersedia.

## Jangan Gunakan db reset di Remote

Command berikut hanya untuk local development:

```bash
supabase db reset
```

Jangan gunakan konsep reset database untuk Supabase Web/remote production atau project utama. Di Supabase Web, migration dijalankan manual lewat SQL Editor dan tidak otomatis memiliki rollback.

## Cara Menjalankan di Supabase Dashboard

Untuk setiap file SQL:

1. Buka Supabase Dashboard.
2. Pilih project `stock-ai-advisor`.
3. Masuk ke menu `SQL Editor`.
4. Klik `New Query`.
5. Buka file SQL di workspace lokal.
6. Copy seluruh isi file.
7. Paste ke SQL Editor.
8. Review checklist sebelum run.
9. Klik `Run`.
10. Tunggu sampai query selesai tanpa error.
11. Simpan/catat hasil run.
12. Lanjut ke file berikutnya hanya jika file sebelumnya sukses.

## Checklist Sebelum Run

Pastikan untuk setiap file:

- Tidak ada `drop table`.
- Tidak ada `truncate`.
- Tidak ada `delete from`.
- Migration dijalankan sesuai urutan.
- Backup/copy SQL disimpan.
- File yang dipaste sama dengan file lokal yang ingin dijalankan.
- Jika ada error, jangan lanjut ke file berikutnya.

## Verification Queries

Jalankan query berikut setelah semua migration dan seed selesai.

### 1. Cek Daftar Tabel

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'profiles',
    'exchanges',
    'sectors',
    'symbols',
    'watchlists',
    'watchlist_items',
    'watchlist_scores',
    'user_alerts',
    'alert_conditions',
    'alert_logs',
    'screener_presets',
    'screener_filters',
    'user_saved_screeners',
    'screener_results',
    'stock_financials',
    'financial_growth_metrics',
    'fundamental_scorecards',
    'chart_analysis_runs',
    'market_events',
    'corporate_actions',
    'event_alerts',
    'insight_feed_items',
    'portfolio_simulations',
    'portfolio_positions',
    'accumulation_distribution_insights'
  )
order by table_name;
```

Expected: semua tabel di atas muncul.

### 2. Cek RLS Aktif

```sql
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles',
    'exchanges',
    'sectors',
    'symbols',
    'watchlists',
    'watchlist_items',
    'watchlist_scores',
    'user_alerts',
    'alert_conditions',
    'alert_logs',
    'user_saved_screeners',
    'screener_results',
    'event_alerts',
    'insight_feed_items',
    'portfolio_simulations',
    'portfolio_positions'
  )
order by tablename;
```

Expected: `rowsecurity = true` untuk tabel yang ditampilkan.

### 3. Cek Policies

```sql
select schemaname, tablename, policyname, cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
    'profiles',
    'watchlists',
    'watchlist_items',
    'watchlist_scores',
    'user_alerts',
    'alert_conditions',
    'alert_logs',
    'user_saved_screeners',
    'screener_results',
    'event_alerts',
    'insight_feed_items',
    'portfolio_simulations',
    'portfolio_positions'
  )
order by tablename, policyname;
```

Expected: policy profile dan policy user-owned feature tables muncul.

### 4. Cek Foreign Key

```sql
select
  conrelid::regclass as table_name,
  conname as constraint_name,
  confrelid::regclass as references_table
from pg_constraint
where contype = 'f'
  and connamespace = 'public'::regnamespace
  and (
    confrelid = 'public.profiles'::regclass
    or confrelid = 'public.symbols'::regclass
    or confrelid = 'public.exchanges'::regclass
    or confrelid = 'public.sectors'::regclass
  )
order by table_name::text, constraint_name;
```

Expected: FK ke `profiles`, `symbols`, `exchanges`, dan `sectors` terlihat.

### 5. Cek Seed Exchange dan Symbols

```sql
select exchange_code, exchange_name, country, currency, timezone
from public.exchanges
order by exchange_code;
```

Expected: ada `IDX`.

```sql
select
  s.symbol_code,
  s.company_name,
  e.exchange_code,
  sec.sector_name,
  s.instrument_type,
  s.currency,
  s.is_active
from public.symbols s
left join public.exchanges e on e.id = s.exchange_id
left join public.sectors sec on sec.id = s.sector_id
where s.symbol_code in ('BBCA', 'BBRI', 'TLKM', 'ASII', 'UNVR')
order by s.symbol_code;
```

Expected: `BBCA`, `BBRI`, `TLKM`, `ASII`, dan `UNVR` muncul.

### 6. Cek Backfill Symbol ID

Jika sudah ada data fitur dengan `symbol_code`, jalankan:

```sql
select 'watchlist_items' as table_name, count(*) as missing_symbol_id
from public.watchlist_items
where symbol_code is not null and symbol_id is null
union all
select 'user_alerts', count(*)
from public.user_alerts
where symbol_code is not null and symbol_id is null
union all
select 'screener_results', count(*)
from public.screener_results
where symbol_code is not null and symbol_id is null
union all
select 'stock_financials', count(*)
from public.stock_financials
where symbol_code is not null and symbol_id is null;
```

Expected: untuk symbol yang tersedia di `symbols`, nilai missing berkurang atau `0`.

## Rollback Note

Migration web manual tidak otomatis rollback.

Karena itu:

- Jangan jalankan SQL destructive.
- Jangan jalankan query yang menghapus tabel/data.
- Jika terjadi error, catat pesan error lengkap.
- Jangan lanjut ke file berikutnya sebelum error dipahami.
- Simpan copy SQL yang sudah dijalankan.
- Jika database sudah berisi data penting, lakukan backup dari Supabase Dashboard sebelum menjalankan migration.

## Next Step Setelah Migration Sukses

Setelah verification queries aman:

1. Seed screener presets edukatif.
2. Test insert profile dengan user login.
3. Test insert watchlist dan watchlist item.
4. Verifikasi RLS dengan user berbeda.
5. Lanjut desain Supabase Edge Functions P0:
   - `get-watchlist`
   - `add-watchlist-item`
   - `remove-watchlist-item`
   - `evaluate-watchlist`
   - `create-alert`
   - `run-screener`
