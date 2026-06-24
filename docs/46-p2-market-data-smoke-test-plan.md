# 46. P2 Market Data Smoke Test Plan

## Scope

Smoke test ini dipakai setelah menjalankan:

```text
supabase/migrations/0005_create_market_data_schema.sql
```

Tujuan:

- memastikan tabel P2 terbentuk;
- memastikan FK ke `symbols` tersedia;
- memastikan index tersedia;
- memastikan RLS aktif;
- memastikan tidak ada API key/secret disimpan;
- memastikan P1 tidak terganggu.

## Checklist Sebelum Run Migration

- Migration dijalankan setelah:
  - `0000_create_base_app_schema.sql`
  - `0003_create_user_feature_schema.sql`
  - `0004_backfill_feature_foreign_keys.sql`
- SQL tidak mengandung:
  - `drop table`
  - `truncate`
  - `delete from`
- Backup/copy SQL disimpan.
- Edge Functions P0 tidak diubah.
- Flutter P1 tidak diubah.

## Verification: Tabel P2

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
    'provider_sources',
    'provider_sync_runs',
    'market_price_snapshots',
    'ohlcv_bars',
    'technical_indicator_snapshots',
    'market_context_snapshots',
    'news_items'
  )
order by table_name;
```

Expected:

- 7 rows.

Status:

- Pending manual run.

## Verification: RLS Aktif

```sql
select
  schemaname,
  tablename,
  rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'provider_sources',
    'provider_sync_runs',
    'market_price_snapshots',
    'ohlcv_bars',
    'technical_indicator_snapshots',
    'market_context_snapshots',
    'news_items'
  )
order by tablename;
```

Expected:

- Semua `rowsecurity = true`.

Status:

- Pending manual run.

## Verification: Tidak Ada Public Policy

```sql
select
  schemaname,
  tablename,
  policyname,
  cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
    'provider_sources',
    'provider_sync_runs',
    'market_price_snapshots',
    'ohlcv_bars',
    'technical_indicator_snapshots',
    'market_context_snapshots',
    'news_items'
  )
order by tablename, policyname;
```

Expected:

- 0 rows untuk P2 awal.
- Akses Flutter nanti melalui Edge Functions, bukan direct table read.

Status:

- Pending manual run.

## Verification: Foreign Key Ke symbols

```sql
select
  tc.table_name,
  kcu.column_name,
  ccu.table_name as foreign_table_name,
  ccu.column_name as foreign_column_name
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on tc.constraint_name = kcu.constraint_name
 and tc.table_schema = kcu.table_schema
join information_schema.constraint_column_usage ccu
  on ccu.constraint_name = tc.constraint_name
 and ccu.table_schema = tc.table_schema
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'public'
  and tc.table_name in (
    'provider_sync_runs',
    'market_price_snapshots',
    'ohlcv_bars',
    'technical_indicator_snapshots',
    'news_items'
  )
  and ccu.table_name = 'symbols'
order by tc.table_name, kcu.column_name;
```

Expected:

- FK `symbol_id` tersedia pada tabel relevan.

Status:

- Pending manual run.

## Verification: Index Penting

```sql
select
  tablename,
  indexname,
  indexdef
from pg_indexes
where schemaname = 'public'
  and tablename in (
    'provider_sources',
    'provider_sync_runs',
    'market_price_snapshots',
    'ohlcv_bars',
    'technical_indicator_snapshots',
    'market_context_snapshots',
    'news_items'
  )
order by tablename, indexname;
```

Expected:

- Index untuk `symbol_id`, `symbol_code`, `timeframe`, `provider_name`, `observed_at`, dan `created_at` tersedia sesuai tabel.

Status:

- Pending manual run.

## Verification: Tidak Ada Kolom Secret

```sql
select
  table_name,
  column_name
from information_schema.columns
where table_schema = 'public'
  and table_name in (
    'provider_sources',
    'provider_sync_runs',
    'market_price_snapshots',
    'ohlcv_bars',
    'technical_indicator_snapshots',
    'market_context_snapshots',
    'news_items'
  )
  and (
    column_name ilike '%api_key%'
    or column_name ilike '%secret%'
    or column_name ilike '%token%'
    or column_name ilike '%password%'
    or column_name ilike '%credential%'
  )
order by table_name, column_name;
```

Expected:

- 0 rows.

Status:

- Pending manual run.

## Verification: Insert Sample Provider Metadata

Opsional untuk development setelah schema lolos:

```sql
insert into public.provider_sources (
  provider_name,
  provider_type,
  supports_quotes,
  supports_ohlcv,
  supports_market_context,
  supports_news,
  status,
  notes
)
values (
  'sample_provider',
  'sample',
  true,
  true,
  true,
  true,
  'active',
  'Development-only sample provider. provider belum aktif untuk production.'
)
on conflict (provider_name) do nothing;
```

Expected:

- 1 provider source tersedia.
- Tidak ada API key disimpan.

Status:

- Optional pending.

## P1 Regression Checklist

Setelah migration:

- Login Flutter masih berhasil.
- Watchlist masih tampil.
- Add Watchlist Item masih berhasil.
- Evaluate P0 masih menghasilkan `p0_dummy_scoring_v1`.
- Enhanced Watchlist Card masih tampil.
- Screener P1 masih berjalan.
- Smart Alert masih bisa dibuat.
- Market Context dan Chart Lab tetap placeholder sampai Edge Functions P2 siap.

## Pass Criteria

P2 schema foundation dianggap lolos smoke test jika:

- 7 tabel baru muncul.
- RLS aktif pada semua tabel P2.
- Tidak ada public policy P2 awal.
- FK ke `symbols` tersedia.
- Index penting tersedia.
- Tidak ada kolom secret.
- P1 regression checklist tetap pass.

## Known Limitations

- Market data provider belum aktif.
- OHLCV belum berisi data real.
- Technical indicators belum dihitung.
- News provider belum aktif.
- AI/RAG belum aktif.
- Chart Lab masih preview.
- Scoring P1 masih `p0_dummy_scoring_v1`.
- Tidak ada fitur transaksi saham.

## Next Step Setelah Smoke Test Pass

1. Seed `sample_provider`.
2. Seed sample data terbatas dengan label `sample data`.
3. Buat Edge Function `get-market-context`.
4. Buat Edge Function `get-stock-quote`.
5. Tambahkan Flutter adapter read-only setelah endpoint P2 stabil.

## P2 Market Data Smoke Test Result

Status: PASS

Actual Result:
- provider_sources: 1 row
- provider_sync_runs: 1 row, status success
- market_price_snapshots: 5 rows
- technical_indicator_snapshots: 5 rows
- market_context_snapshots: 1 row
- news_items: 0 rows, expected because news provider is not active
- sync-market-candidates returned ok true
- get-market-context returned ok true
- data_quality is sample
- provider production is not active yet

Conclusion:
P2 market data sample sync is working correctly. The provider is still sample-based, but the schema, Edge Functions, database writes, and market context response are valid for P2 foundation.
