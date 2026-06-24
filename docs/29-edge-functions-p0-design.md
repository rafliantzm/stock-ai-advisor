# 29. Edge Functions P0 Design

Dokumen ini menjelaskan desain Supabase Edge Functions P0 untuk backend API awal `stock-ai-advisor`.

Scope P0:

- Tidak ada Flutter UI.
- Tidak ada AI/RAG.
- Tidak ada market data real-time.
- Tidak ada fitur transaksi saham real.
- Scoring memakai dummy deterministic scoring sampai Rule Engine final tersedia.

## Edge Functions

| Function | Purpose |
| --- | --- |
| `get-watchlist` | Mengambil watchlist user, item aktif, symbol detail, dan latest score. |
| `add-watchlist-item` | Menambahkan symbol ke watchlist milik user. |
| `remove-watchlist-item` | Mengarsipkan item watchlist milik user. |
| `create-alert` | Membuat smart alert dan alert conditions. |
| `run-screener` | Menjalankan screener dari preset dan symbols yang tersedia. |
| `evaluate-watchlist` | Memberi dummy scoring untuk item watchlist dan menyimpan score. |

## Shared Modules

```text
supabase/functions/_shared/cors.ts
supabase/functions/_shared/errors.ts
supabase/functions/_shared/supabaseClient.ts
supabase/functions/_shared/auth.ts
supabase/functions/_shared/response.ts
```

Shared behavior:

- CORS handling.
- JSON response konsisten.
- Error shape konsisten.
- JWT user extraction.
- Supabase user client untuk validasi token.
- Supabase admin client hanya untuk Edge Functions.

## Auth and Security

Semua function membaca user dari JWT:

```text
Authorization: Bearer <USER_JWT>
```

Flow:

1. Function membaca bearer token.
2. Function memvalidasi token via Supabase Auth.
3. Function mengambil `user.id`.
4. Query user-owned selalu memfilter `user_id = user.id`.
5. Service role hanya dipakai di Edge Functions untuk membaca tabel sistem dengan RLS tertutup seperti `symbols`.

Service role key tidak boleh dikirim ke Flutter/client.

## Environment Variables

Required:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` atau `SUPABASE_PUBLISHABLE_KEYS`
- `SUPABASE_SERVICE_ROLE_KEY` atau `SUPABASE_SECRET_KEYS`

Notes:

- `SUPABASE_SERVICE_ROLE_KEY` / `SUPABASE_SECRET_KEYS` hanya untuk Edge Functions environment.
- Jangan simpan key sensitif di Flutter.

## Response Shape

Success:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Error:

```json
{
  "ok": false,
  "error": {
    "code": "validation_error",
    "message": "watchlist_id is required",
    "details": null
  }
}
```

Error codes:

- `unauthorized`
- `validation_error`
- `not_found`
- `database_error`
- `method_not_allowed`

## Dummy Scoring P0

`evaluate-watchlist` menghasilkan:

- `technical_score`
- `harmony_score`
- `fundamental_score`
- `risk_score`
- `liquidity_score`
- `final_score`
- `risk warning`
- `invalidation level`

Persisted ke `watchlist_scores`:

- `technical_score`
- `fundamental_score`
- `risk_score`
- `overall_score`
- `candidate_label`
- `risk_warnings`
- `invalidation_level`

`harmony_score` dan `liquidity_score` dikembalikan dalam response P0, tetapi belum dipersist karena kolom tersebut belum ada di `watchlist_scores`.

## Safe Wording

Response memakai wording aman:

- `layak dianalisis`
- `watchlist_candidate`
- `technical setup`
- `risk warning`
- `invalidation level`

Tidak ada wording eksekusi transaksi saham.

## Example Requests

### get-watchlist

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/get-watchlist" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>"}'
```

### add-watchlist-item

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/add-watchlist-item" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>","symbol_code":"BBCA"}'
```

### evaluate-watchlist

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/evaluate-watchlist" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>"}'
```

### create-alert

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/create-alert" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "symbol_code": "BBCA",
    "name": "BBCA technical setup watch",
    "alert_type": "technical_setup",
    "conditions": [
      {"metric":"technical_score","operator":"gte","value_numeric":70}
    ]
  }'
```

### run-screener

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/run-screener" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"preset_name":"Technical Breakout Candidate","limit":10}'
```

## References

- Supabase Edge Functions are TypeScript functions running on Deno.
- Supabase Functions can receive signed-in user JWTs through the `Authorization` header.
- Supabase Edge Functions environment supports project secrets such as URL, publishable/anon key, and secret/service-role key.
