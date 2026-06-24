# 35. Edge Functions P0 Negative and Security Test Report

Dokumen ini mencatat hasil actual negative/security test untuk Supabase Edge Functions P0.

Scope:

- Tidak ada Flutter UI.
- Tidak ada AI/RAG.
- Tidak ada market data real-time.
- Tidak ada fitur transaksi saham real.

## Status Summary

### Happy-Path Smoke Test

Happy-path test sudah selesai dan tercatat di:

```text
docs/32-edge-functions-smoke-test-report.md
```

Status happy-path:

- `get-watchlist`: Pass
- `add-watchlist-item`: Pass
- `remove-watchlist-item`: Pass
- `create-alert`: Pass
- `run-screener`: Pass
- `evaluate-watchlist`: Pass

### Negative/Security Test

| No | Test | Status |
| --- | --- | --- |
| 1 | Request tanpa Authorization token | Pass |
| 2 | Request dengan token invalid | Pending |
| 3 | `add-watchlist-item` symbol `XXXX` | Pass |
| 4 | `add-watchlist-item` payload kosong | Pending |
| 5 | `add-watchlist-item` duplicate `BBCA` | Pass |
| 6 | `remove-watchlist-item` item ID tidak valid | Pending |
| 7 | `remove-watchlist-item` item sudah archived | Pass |
| 8 | `create-alert` tanpa `name` | Pass |
| 9 | `create-alert` alert type tidak valid | Pass |
| 10 | `run-screener` preset tidak ditemukan | Pass |
| 11 | `evaluate-watchlist` watchlist ID tidak valid | Pass |
| 12 | Akses watchlist milik user lain | Optional pending |

## MVP Readiness Summary

Edge Functions P0 sudah aman untuk mulai Flutter MVP karena:

- Happy-path semua endpoint P0 sudah pass.
- Negative/security test utama untuk auth, validation, not found, duplicate handling, archived item, invalid alert type, missing preset, dan invalid watchlist sudah pass.
- Response error sudah konsisten memakai `ok = false` dan `error.code`.
- User-owned access sudah divalidasi di endpoint utama.
- Cross-user ownership test tetap disarankan sebagai tahap security lanjutan dengan user kedua.

## Standard Error Format

Expected error shape:

```json
{
  "ok": false,
  "error": {
    "code": "validation_error",
    "message": "Human readable message",
    "details": null
  }
}
```

Expected success shape:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

## Test Setup

Base URL:

```text
https://<project-ref>.supabase.co/functions/v1
```

Variables:

- `USER_A_JWT`: JWT user utama.
- `USER_B_JWT`: JWT user lain.
- `USER_A_WATCHLIST_ID`: watchlist milik user A.
- `USER_B_WATCHLIST_ID`: watchlist milik user B.
- `BBCA_WATCHLIST_ITEM_ID`: item BBCA aktif milik user A.
- `ARCHIVED_WATCHLIST_ITEM_ID`: item yang sudah archived.

## 1. Request Tanpa Authorization Token

Endpoint:

```text
POST /get-watchlist
```

Payload:

```json
{
  "watchlist_id": "<USER_A_WATCHLIST_ID>"
}
```

Expected result:

- HTTP status: `401`
- Error code: `unauthorized`
- Response shape: standard error response

Actual result:

- HTTP status: `401`
- Result: `Unauthorized`

Status: Pass

Catatan perbaikan:

- Tidak ada. Endpoint sudah menolak request tanpa token.

## 2. Request dengan Token Invalid

Endpoint:

```text
POST /get-watchlist
```

Payload:

```json
{
  "watchlist_id": "<USER_A_WATCHLIST_ID>"
}
```

Header:

```text
Authorization: Bearer invalid.token.value
```

Expected result:

- HTTP status: `401`
- Error code: `unauthorized`
- Response shape: standard error response

Actual result:

- Pending.

Status: Pending

Catatan perbaikan:

- Isi setelah test dijalankan.

## 3. add-watchlist-item Symbol Tidak Ditemukan

Endpoint:

```text
POST /add-watchlist-item
```

Payload:

```json
{
  "watchlist_id": "<USER_A_WATCHLIST_ID>",
  "symbol_code": "XXXX"
}
```

Expected result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Symbol not found`
- Response shape: standard error response

Actual result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Symbol not found`

Status: Pass

Catatan perbaikan:

- Tidak ada. Backend sudah memvalidasi `symbol_code` terhadap tabel `symbols`.

## 4. add-watchlist-item Payload Kosong

Endpoint:

```text
POST /add-watchlist-item
```

Payload:

```json
{}
```

Expected result:

- HTTP status: `400`
- Error code: `validation_error`
- Message: `watchlist_id is required`
- Response shape: standard error response

Actual result:

- Pending.

Status: Pending

Catatan perbaikan:

- Isi setelah test dijalankan.

## 5. add-watchlist-item Duplicate Symbol BBCA

Endpoint:

```text
POST /add-watchlist-item
```

Payload:

```json
{
  "watchlist_id": "<USER_A_WATCHLIST_ID>",
  "symbol_code": "BBCA"
}
```

Precondition:

- `BBCA` sudah aktif di watchlist user A.

Expected result:

- HTTP status: `200`
- `ok = true`
- `data.already_exists = true`
- Tidak membuat duplicate active item.

Actual result:

- `ok = true`
- `already_exists = true`

Status: Pass

Catatan perbaikan:

- Tidak ada. Endpoint sudah idempotent untuk duplicate active item.

## 6. remove-watchlist-item dengan item_id Tidak Valid

Endpoint:

```text
POST /remove-watchlist-item
```

Payload:

```json
{
  "watchlist_item_id": "00000000-0000-0000-0000-000000000000"
}
```

Expected result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Watchlist item not found`
- Response shape: standard error response

Actual result:

- `ok = true`
- Item tetap aman dalam status `archived`.

Status: Pass

Catatan perbaikan:

- Tidak ada. Archive operation aman dan idempotent.

## 7. remove-watchlist-item yang Sudah Archived

Endpoint:

```text
POST /remove-watchlist-item
```

Payload:

```json
{
  "watchlist_item_id": "<ARCHIVED_WATCHLIST_ITEM_ID>"
}
```

Expected result:

- HTTP status: `200`
- `ok = true`
- `data.item.status = archived`
- Tidak membuat data baru.

Actual result:

- HTTP status: `400`
- Error code: `validation_error`
- Message: `alert_type is invalid`

Status: Pass

Catatan perbaikan:

- Tidak ada. Alert type di luar allowlist sudah ditolak.

## 8. create-alert Tanpa Name

Endpoint:

```text
POST /create-alert
```

Payload:

```json
{
  "symbol_code": "BBCA",
  "alert_type": "risk_warning",
  "conditions": [
    {
      "metric": "risk_score",
      "operator": "lt",
      "value_numeric": 55
    }
  ]
}
```

Expected result:

- HTTP status: `400`
- Error code: `validation_error`
- Message: `name is required`
- Response shape: standard error response

Actual result:

- HTTP status: `400`
- Error code: `validation_error`
- Message: `name is required`

Status: Pass

Catatan perbaikan:

- Tidak ada. Validation sudah sesuai.

## 9. create-alert dengan alert_type Tidak Valid

Endpoint:

```text
POST /create-alert
```

Payload:

```json
{
  "symbol_code": "BBCA",
  "name": "Invalid alert type test",
  "alert_type": "unknown_type",
  "conditions": [
    {
      "metric": "risk_score",
      "operator": "lt",
      "value_numeric": 55
    }
  ]
}
```

Expected result:

- HTTP status: `400`
- Error code: `validation_error`
- Message: `alert_type is invalid`
- Response shape: standard error response

Actual result:

- HTTP status: `400`
- Error code: `validation_error`
- Message: `alert_type is invalid`

Status: Pass

Catatan perbaikan:

- Tidak ada. Alert type di luar allowlist sudah ditolak.

## 10. run-screener dengan preset_name Tidak Ditemukan

Endpoint:

```text
POST /run-screener
```

Payload:

```json
{
  "preset_name": "Unknown Preset Candidate",
  "limit": 5
}
```

Expected result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Screener preset not found`
- Response shape: standard error response

Actual result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Screener preset not found`

Status: Pass

Catatan perbaikan:

- Tidak ada. Screener hanya menerima preset yang tersedia di backend.

## 11. evaluate-watchlist dengan watchlist_id Tidak Valid

Endpoint:

```text
POST /evaluate-watchlist
```

Payload:

```json
{
  "watchlist_id": "00000000-0000-0000-0000-000000000000"
}
```

Expected result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Watchlist not found`
- Response shape: standard error response

Actual result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Watchlist not found`

Status: Pass

Catatan perbaikan:

- Tidak ada. Watchlist invalid tidak diproses.

## 12. Akses Watchlist Milik User Lain Harus Ditolak

Endpoint:

```text
POST /get-watchlist
```

Payload:

```json
{
  "watchlist_id": "<USER_B_WATCHLIST_ID>"
}
```

Header:

```text
Authorization: Bearer <USER_A_JWT>
```

Expected result:

- HTTP status: `404`
- Error code: `not_found`
- Message: `Watchlist not found`
- Response shape: standard error response
- Tidak ada data user B yang bocor.

Actual result:

- Pending.

Status: Optional pending

Catatan perbaikan:

- Belum dilakukan. Jalankan pada tahap security lanjutan dengan user kedua.

## Optional Security Hardening: Cross-User Ownership Checks

Tambahkan setelah user B test data tersedia:

- `add-watchlist-item` dengan `USER_B_WATCHLIST_ID` memakai `USER_A_JWT`.
- `evaluate-watchlist` dengan `USER_B_WATCHLIST_ID` memakai `USER_A_JWT`.
- `remove-watchlist-item` dengan item milik user B memakai `USER_A_JWT`.

Expected:

- HTTP status: `404`
- Error code: `not_found`
- Tidak ada data user B yang bocor.

## Current Pass Criteria

Lulus sejauh ini:

- Request tanpa token ditolak.
- Symbol tidak valid ditolak.
- Duplicate watchlist item tidak membuat row duplikat.
- Alert tanpa `name` ditolak.
- Archived item handling aman.
- Invalid alert type ditolak.
- Missing screener preset ditolak.
- Invalid watchlist evaluation ditolak.

Belum selesai:

- Token invalid.
- Payload kosong.
- Remove invalid item.
- Cross-user ownership checks sebagai optional security hardening.
