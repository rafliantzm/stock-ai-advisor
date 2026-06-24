# 30. Edge Functions P0 Test Plan

Test plan ini untuk Supabase Edge Functions P0.

## Prerequisites

- Migration `0000`, `0003`, dan `0004` sudah sukses.
- Seed base symbols sudah sukses.
- Seed screener presets sudah sukses.
- Auth user sudah tersedia.
- User punya row `profiles`.
- User punya `Main Watchlist`.
- `BBCA` sudah berhasil masuk watchlist saat smoke test manual.

## Test JWT User

Gunakan JWT user dari session Supabase Auth.

Di aplikasi/frontend nanti, token berasal dari session user. Untuk test manual, ambil access token dari auth session atau dari tool API yang dipakai.

Header wajib:

```text
Authorization: Bearer <USER_JWT>
Content-Type: application/json
```

## Test Cases

### 1. Unauthorized

Request tanpa JWT:

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/get-watchlist" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected:

```json
{
  "ok": false,
  "error": {
    "code": "unauthorized"
  }
}
```

### 2. get-watchlist

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/get-watchlist" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>"}'
```

Expected:

- `ok = true`
- `data.selected_watchlist.id = <WATCHLIST_ID>`
- `data.items` berisi item milik user.
- Jika BBCA ada, symbol detail ikut muncul.

### 3. add-watchlist-item

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/add-watchlist-item" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>","symbol_code":"BBCA"}'
```

Expected:

- `ok = true`
- Jika item sudah ada, response mengandung `already_exists = true`.
- Tidak membuat duplicate active item.

### 4. remove-watchlist-item

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/remove-watchlist-item" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_item_id":"<WATCHLIST_ITEM_ID>"}'
```

Expected:

- `ok = true`
- `status = archived`
- `get-watchlist` tidak menampilkan item archived.

### 5. create-alert

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/create-alert" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{
    "symbol_code":"BBCA",
    "name":"BBCA risk warning watch",
    "alert_type":"risk_warning",
    "conditions":[
      {"metric":"risk_score","operator":"lt","value_numeric":55}
    ]
  }'
```

Expected:

- `ok = true`
- Row `user_alerts` dibuat untuk user.
- Row `alert_conditions` dibuat.

### 6. run-screener

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/run-screener" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"preset_name":"Technical Breakout Candidate","limit":5}'
```

Expected:

- `ok = true`
- `data.results` berisi symbols dummy.
- `candidate_label` memakai wording aman.
- Row `screener_results` tersimpan untuk user.

### 7. evaluate-watchlist

```bash
curl -X POST "https://<project-ref>.supabase.co/functions/v1/evaluate-watchlist" \
  -H "Authorization: Bearer <USER_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"watchlist_id":"<WATCHLIST_ID>"}'
```

Expected:

- `ok = true`
- `data.evaluated_count > 0` jika watchlist punya item aktif.
- Row `watchlist_scores` tersimpan.
- Response memuat `technical setup`, `risk warning`, dan `invalidation level`.

## Database Verification

### Watchlist Scores

```sql
select symbol_code, overall_score, candidate_label, technical_score, fundamental_score, risk_score, invalidation_level, evaluated_at
from public.watchlist_scores
order by evaluated_at desc
limit 10;
```

### Screener Results

```sql
select symbol_code, score, candidate_label, rule_version, created_at
from public.screener_results
order by created_at desc
limit 10;
```

### Alerts

```sql
select a.name, a.alert_type, a.symbol_code, a.status, count(c.id) as condition_count
from public.user_alerts a
left join public.alert_conditions c on c.alert_id = a.id
group by a.id
order by a.created_at desc
limit 10;
```

## Negative Tests

- Use JWT user A with watchlist_id owned by user B. Expected: `not_found`.
- Use invalid `symbol_code`. Expected: `not_found`.
- Omit required field. Expected: `validation_error`.
- Use unsupported method. Expected: `method_not_allowed`.

## Notes

- AI belum dipakai.
- RAG buku belum dipakai.
- Market data real-time belum dipakai.
- Scoring P0 bersifat dummy dan deterministic.
