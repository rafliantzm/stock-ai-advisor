# 28. Screener Preset Seed Notes

Seed file:

```text
supabase/seed/0001_screener_presets_seed.sql
```

Scope seed ini hanya menambahkan preset dan filter edukatif untuk `screener_presets` dan `screener_filters`. Tidak ada Flutter UI, tidak ada Edge Functions, tidak ada API provider, dan tidak ada fitur transaksi saham real.

## Preset yang Dibuat

1. Technical Breakout Candidate
2. Fibonacci Support Candidate
3. Candlestick Reversal Candidate
4. Volume Accumulation Candidate
5. Low Risk Watchlist Candidate
6. Fundamental Strong Candidate
7. Dividend Candidate
8. Trend Following Candidate
9. Support Resistance Rebound Candidate
10. Harmonic Pattern Candidate

## Wording dan Guardrails

Seed memakai wording aman:

- `candidate`
- `layak dianalisis`
- `watchlist`
- `risk warning`
- `invalidation level`

Seed tidak membuat instruksi transaksi saham real, tidak membuat klaim hasil pasti, dan tidak memakai wording eksekusi order.

## Struktur Data

Setiap preset masuk ke:

```text
public.screener_presets
```

Setiap preset punya filter edukatif di:

```text
public.screener_filters
```

Metric filter mencakup:

- `technical_score`
- `harmony_score`
- `fundamental_score`
- `risk_score`
- `liquidity_score`
- `volume_condition`
- `trend_condition`
- kondisi pendukung seperti Fibonacci, candlestick, support/resistance, dan dividend.

## Idempotency

Schema `screener_presets` saat ini belum punya unique constraint untuk `name`, sehingga seed memakai:

```sql
where not exists (...)
```

Untuk `screener_filters`, seed juga memakai `where not exists` berdasarkan kombinasi:

- `preset_id`
- `metric`
- `operator`
- `value_json`

Tidak ada `drop table`, `truncate`, atau `delete from`.

## Cara Menjalankan Lewat Supabase SQL Editor

1. Buka Supabase Dashboard.
2. Masuk ke project `stock-ai-advisor`.
3. Buka `SQL Editor`.
4. Klik `New Query`.
5. Copy seluruh isi:

```text
supabase/seed/0001_screener_presets_seed.sql
```

6. Paste ke SQL Editor.
7. Pastikan tidak ada SQL destructive.
8. Klik `Run`.
9. Jalankan query verifikasi.

## Query Verifikasi

Cek daftar preset:

```sql
select name, category, status
from public.screener_presets
where name in (
  'Technical Breakout Candidate',
  'Fibonacci Support Candidate',
  'Candlestick Reversal Candidate',
  'Volume Accumulation Candidate',
  'Low Risk Watchlist Candidate',
  'Fundamental Strong Candidate',
  'Dividend Candidate',
  'Trend Following Candidate',
  'Support Resistance Rebound Candidate',
  'Harmonic Pattern Candidate'
)
order by name;
```

Expected: 10 rows.

Cek jumlah filter per preset:

```sql
select p.name, count(f.id) as filter_count
from public.screener_presets p
left join public.screener_filters f on f.preset_id = p.id
where p.name in (
  'Technical Breakout Candidate',
  'Fibonacci Support Candidate',
  'Candlestick Reversal Candidate',
  'Volume Accumulation Candidate',
  'Low Risk Watchlist Candidate',
  'Fundamental Strong Candidate',
  'Dividend Candidate',
  'Trend Following Candidate',
  'Support Resistance Rebound Candidate',
  'Harmonic Pattern Candidate'
)
group by p.name
order by p.name;
```

Expected: setiap preset punya minimal 4 filter.

Cek metric yang dipakai:

```sql
select distinct f.metric
from public.screener_filters f
join public.screener_presets p on p.id = f.preset_id
where p.name in (
  'Technical Breakout Candidate',
  'Fibonacci Support Candidate',
  'Candlestick Reversal Candidate',
  'Volume Accumulation Candidate',
  'Low Risk Watchlist Candidate',
  'Fundamental Strong Candidate',
  'Dividend Candidate',
  'Trend Following Candidate',
  'Support Resistance Rebound Candidate',
  'Harmonic Pattern Candidate'
)
order by f.metric;
```

Expected: metric mencakup technical, harmony, fundamental, risk, liquidity, volume, dan trend condition.

## Next Step Setelah Seed Sukses

1. Review hasil preset di Supabase Table Editor.
2. Buat desain Rule Engine mapping dari `screener_filters.metric` ke kalkulasi backend.
3. Buat kontrak response `run-screener`.
4. Lanjut Supabase Edge Functions P0 untuk screener setelah watchlist endpoint siap.
