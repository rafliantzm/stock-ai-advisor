# 31. Edge Functions Dashboard Deploy Guide

Panduan ini untuk deploy Supabase Edge Functions P0 lewat Supabase Dashboard.

## Functions

Deploy function berikut:

1. `get-watchlist`
2. `add-watchlist-item`
3. `remove-watchlist-item`
4. `create-alert`
5. `run-screener`
6. `evaluate-watchlist`

Folder source:

```text
supabase/functions/
```

## Environment Variables

Pastikan secrets tersedia di Edge Functions environment:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` atau `SUPABASE_PUBLISHABLE_KEYS`
- `SUPABASE_SERVICE_ROLE_KEY` atau `SUPABASE_SECRET_KEYS`

Catatan keamanan:

- Service role/secret key hanya berada di Edge Functions.
- Jangan taruh service role/secret key di Flutter.
- Client hanya mengirim JWT user lewat Authorization header.

## Deploy via Supabase Dashboard

Langkah umum:

1. Buka Supabase Dashboard.
2. Pilih project `stock-ai-advisor`.
3. Masuk ke `Edge Functions`.
4. Buat function baru sesuai nama folder, misalnya `get-watchlist`.
5. Paste isi `index.ts` function terkait.
6. Pastikan shared files dari `supabase/functions/_shared/` tersedia untuk import relatif.
7. Deploy function.
8. Ulangi untuk semua function P0.
9. Buka settings/secrets untuk memastikan environment variables tersedia.

Jika Dashboard editor tidak nyaman untuk multi-file shared imports, deploy source folder dengan workflow Supabase yang mendukung struktur folder lengkap. Source code tetap berada di folder `supabase/functions`.

## JWT Requirement

Semua function butuh header:

```text
Authorization: Bearer <USER_JWT>
```

Tanpa JWT valid, response harus:

```json
{
  "ok": false,
  "error": {
    "code": "unauthorized"
  }
}
```

## Smoke Test Order

Setelah deploy:

1. Test `get-watchlist`.
2. Test `add-watchlist-item` dengan `BBCA`.
3. Test `evaluate-watchlist`.
4. Test `run-screener`.
5. Test `create-alert`.
6. Test `remove-watchlist-item` hanya pada item test.

## Example Request

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/get-watchlist" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>"}'
```

## Expected Response

```json
{
  "ok": true,
  "data": {
    "watchlists": [],
    "selected_watchlist": {},
    "items": []
  },
  "meta": {}
}
```

## Troubleshooting

### unauthorized

Check:

- JWT user masih valid.
- Header `Authorization` memakai format `Bearer <USER_JWT>`.
- Function JWT verification tidak dinonaktifkan tanpa alasan.

### database_error

Check:

- Environment `SUPABASE_URL` benar.
- Service role/secret key tersedia di Edge Function environment.
- Tabel dan migration sudah sukses.
- RLS tidak menghalangi query user-owned jika memakai user client.

### not_found

Check:

- Resource memang milik user tersebut.
- `watchlist_id` benar.
- `symbol_code` tersedia di `symbols`.

## Next Step

Setelah Edge Functions P0 sukses:

1. Tambahkan integration test manual untuk semua endpoint.
2. Stabilkan kontrak response sebelum Flutter UI.
3. Tambahkan Rule Engine backend sungguhan untuk mengganti dummy scoring.
4. Baru integrasikan Flutter screen P0.
5. Setelah itu pertimbangkan explanation layer AI berbasis hasil Rule Engine.
