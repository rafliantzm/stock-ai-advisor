# 25. Base Schema Notes

Migration:

```text
supabase/migrations/0000_create_base_app_schema.sql
```

Seed:

```text
supabase/seed/0000_base_seed.sql
```

Scope migration ini hanya base schema aplikasi: profile user, exchange, sector, dan master symbol saham. Belum ada Flutter UI, belum ada Edge Functions, belum ada API provider, dan tidak ada fitur transaksi saham real.

## Tabel

### profiles

Menyimpan profil aplikasi untuk user Supabase Auth.

Kolom utama:

- `id`
- `user_id`
- `full_name`
- `email`
- `risk_profile`
- `investment_goal`
- `investment_horizon`
- `monthly_budget`
- `preferred_strategy`
- `created_at`
- `updated_at`

RLS:

- User hanya bisa `select` profile miliknya.
- User hanya bisa `insert` profile dengan `user_id = auth.uid()`.
- User hanya bisa `update` profile miliknya.

### exchanges

Master data bursa. Seed awal menyediakan `IDX`.

### sectors

Master data sektor. Seed awal menyediakan beberapa sektor umum seperti Financials, Telecommunication, Consumer Goods, Industrial, Infrastructure, Energy, dan Technology.

### symbols

Master data saham. Seed awal menyediakan dummy symbols:

- `BBCA`
- `BBRI`
- `TLKM`
- `ASII`
- `UNVR`

## RLS dan Akses Data

`profiles` memiliki policy user-owned.

`exchanges`, `sectors`, dan `symbols` juga dibuat dengan RLS aktif tetapi tanpa public policy. Akses final disarankan lewat Supabase Edge Functions atau service role sampai aturan read access final ditentukan.

## Hubungan dengan Migration 0003

Base schema ini berjalan sebelum:

```text
supabase/migrations/0003_create_user_feature_schema.sql
```

Setelah base schema tersedia, tabel fitur user dapat memakai:

- `profiles(user_id)` untuk relasi user-owned.
- `symbols(id)` untuk relasi saham.

Jika `0003` sudah pernah dijalankan di database lain sebelum `0000` dibuat, buat environment baru atau jalankan migration penyesuaian FK secara terpisah.

## Cara Menjalankan Local

Dari root project:

```bash
supabase start
supabase db reset
```

Untuk push ke project Supabase remote:

```bash
supabase db push
```

Seed dapat dijalankan saat local reset jika path seed sudah dikonfigurasi di Supabase CLI. Karena file seed project ini berada di `supabase/seed/0000_base_seed.sql`, jalankan manual lewat SQL editor/psql atau tambahkan path tersebut ke konfigurasi seed Supabase bila ingin otomatis.

## Next Step

Langkah berikutnya:

1. Pastikan migration `0000` dan `0003` berjalan berurutan di local.
2. Verifikasi RLS `profiles` dengan user login.
3. Tambahkan seed screener preset edukatif.
4. Baru lanjut desain Supabase Edge Functions P0 untuk watchlist, alert, dan screener.
