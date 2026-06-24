# 32. Edge Functions P0 Smoke Test Report

Tanggal status: 2026-06-24

Scope:

- Supabase Edge Functions P0.
- JWT user aktif.
- Schema, seed, RLS, foreign key, dan screener presets sudah diverifikasi.
- Tidak ada AI/RAG.
- Tidak ada market data real-time.
- Tidak ada fitur transaksi saham real.

## Summary

Semua Edge Functions P0 berhasil dites:

1. `get-watchlist`
2. `add-watchlist-item`
3. `remove-watchlist-item`
4. `create-alert`
5. `run-screener`
6. `evaluate-watchlist`

Status akhir:

- JWT user berhasil dipakai.
- Profile user berhasil.
- `Main Watchlist` berhasil.
- `BBCA` berhasil tampil di watchlist.
- `TLKM` berhasil ditambah lalu di-archive.
- Alert `BBCA` berhasil dibuat.
- Screener preset berhasil dijalankan.
- `evaluate-watchlist` berhasil membuat `latest_score` untuk `BBCA`.
- Scoring masih dummy dengan `rule_version = p0_dummy_scoring_v1`.

## Tested Functions

### 1. get-watchlist

Endpoint:

```text
POST /functions/v1/get-watchlist
```

Payload:

```json
{
  "watchlist_id": "<MAIN_WATCHLIST_ID>"
}
```

Success response:

```json
{
  "ok": true,
  "data": {
    "watchlists": [],
    "selected_watchlist": {
      "id": "<MAIN_WATCHLIST_ID>",
      "name": "Main Watchlist"
    },
    "items": [
      {
        "symbol_code": "BBCA",
        "latest_score": {}
      }
    ]
  },
  "meta": {}
}
```

Final status: passed.

### 2. add-watchlist-item

Endpoint:

```text
POST /functions/v1/add-watchlist-item
```

Payload:

```json
{
  "watchlist_id": "<MAIN_WATCHLIST_ID>",
  "symbol_code": "TLKM"
}
```

Success response:

```json
{
  "ok": true,
  "data": {
    "item": {
      "symbol_code": "TLKM",
      "status": "active"
    },
    "symbol": {
      "symbol_code": "TLKM"
    }
  },
  "meta": {}
}
```

Final status: passed.

### 3. remove-watchlist-item

Endpoint:

```text
POST /functions/v1/remove-watchlist-item
```

Payload:

```json
{
  "watchlist_item_id": "<TLKM_WATCHLIST_ITEM_ID>"
}
```

Success response:

```json
{
  "ok": true,
  "data": {
    "item": {
      "symbol_code": "TLKM",
      "status": "archived"
    }
  },
  "meta": {}
}
```

Final status: passed.

### 4. create-alert

Endpoint:

```text
POST /functions/v1/create-alert
```

Payload:

```json
{
  "symbol_code": "BBCA",
  "name": "BBCA risk warning watch",
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

Success response:

```json
{
  "ok": true,
  "data": {
    "alert": {
      "symbol_code": "BBCA",
      "alert_type": "risk_warning",
      "status": "active"
    },
    "conditions": []
  },
  "meta": {}
}
```

Final status: passed.

### 5. run-screener

Endpoint:

```text
POST /functions/v1/run-screener
```

Payload:

```json
{
  "preset_name": "Technical Breakout Candidate",
  "limit": 5
}
```

Success response:

```json
{
  "ok": true,
  "data": {
    "run_id": "<RUN_ID>",
    "preset": {
      "name": "Technical Breakout Candidate"
    },
    "filters": [],
    "results": []
  },
  "meta": {
    "scoring_mode": "dummy_p0_no_market_data"
  }
}
```

Final status: passed.

### 6. evaluate-watchlist

Endpoint:

```text
POST /functions/v1/evaluate-watchlist
```

Payload:

```json
{
  "watchlist_id": "<MAIN_WATCHLIST_ID>"
}
```

Success response:

```json
{
  "ok": true,
  "data": {
    "watchlist": {
      "name": "Main Watchlist"
    },
    "evaluated_count": 1,
    "rule_version": "p0_dummy_scoring_v1",
    "results": [
      {
        "symbol_code": "BBCA",
        "candidate_label": "watchlist_candidate",
        "technical_setup": "technical setup candidate",
        "risk_warning": [],
        "invalidation_level": 0,
        "scores": {}
      }
    ]
  },
  "meta": {
    "scoring_mode": "dummy_p0_no_ai_no_rag_no_market_data"
  }
}
```

Final status: passed.

## Error Notes and Fixes

Catatan error yang sempat muncul saat proses P0:

- Environment variable perlu disesuaikan dengan Supabase Dashboard secrets.
  Solusi: function shared client mendukung `SUPABASE_URL`, `SUPABASE_ANON_KEY` atau `SUPABASE_PUBLISHABLE_KEYS`, dan `SUPABASE_SERVICE_ROLE_KEY` atau `SUPABASE_SECRET_KEYS`.
- Tabel master `profiles` dan `symbols` perlu dibuat sebelum feature schema.
  Solusi: migration `0000_create_base_app_schema.sql` dibuat dan dijalankan sebelum `0003`.
- FK feature schema perlu dipastikan setelah base schema tersedia.
  Solusi: migration `0004_backfill_feature_foreign_keys.sql` dibuat untuk backfill dan memastikan FK.
- Screener membutuhkan preset.
  Solusi: seed `0001_screener_presets_seed.sql` dibuat dan diverifikasi.

## Dummy Scoring Note

Scoring P0 masih dummy dan deterministic:

```text
rule_version = p0_dummy_scoring_v1
```

Dummy scoring hanya untuk menguji flow:

- watchlist evaluation
- screener result
- latest score display
- safe wording

Belum ada AI/RAG, market data real-time, atau Rule Engine final.
