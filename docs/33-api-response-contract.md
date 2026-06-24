# 33. API Response Contract

Dokumen ini menjadi kontrak response awal untuk Flutter integration ke Supabase Edge Functions P0.

Guardrails:

- Jangan gunakan wording transaksi saham.
- Gunakan wording aman seperti `layak dianalisis`, `watchlist_candidate`, `technical setup`, `risk warning`, dan `invalidation level`.
- AI/RAG belum digunakan di P0.
- Market data real-time belum digunakan di P0.

## Standard Success Response

Semua response sukses mengikuti format:

```json
{
  "ok": true,
  "data": {},
  "meta": {}
}
```

Flutter wajib membaca:

- `ok`
- `data`

Flutter boleh membaca:

- `meta`

## Standard Error Response

Semua response error mengikuti format:

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

Error code yang didukung:

- `unauthorized`
- `validation_error`
- `not_found`
- `database_error`
- `method_not_allowed`

Flutter wajib membaca:

- `ok`
- `error.code`
- `error.message`

Flutter boleh membaca:

- `error.details`

## get-watchlist

Endpoint:

```text
POST /functions/v1/get-watchlist
```

Request:

```json
{
  "watchlist_id": "uuid"
}
```

Response `data`:

```json
{
  "watchlists": [],
  "selected_watchlist": {},
  "items": [
    {
      "id": "uuid",
      "watchlist_id": "uuid",
      "symbol_id": "uuid",
      "symbol_code": "BBCA",
      "user_notes": null,
      "added_reason": "manual",
      "status": "active",
      "added_at": "timestamp",
      "symbols": {},
      "latest_score": {}
    }
  ]
}
```

Required for Flutter:

- `data.selected_watchlist`
- `data.items`
- `items[].id`
- `items[].symbol_code`
- `items[].status`
- `items[].latest_score`

Optional:

- `data.watchlists`
- `items[].symbols`
- `items[].user_notes`

## add-watchlist-item

Endpoint:

```text
POST /functions/v1/add-watchlist-item
```

Request:

```json
{
  "watchlist_id": "uuid",
  "symbol_code": "BBCA",
  "user_notes": "optional",
  "added_reason": "manual"
}
```

Response `data`:

```json
{
  "item": {},
  "symbol": {},
  "already_exists": false,
  "restored": false
}
```

Required for Flutter:

- `data.item.id`
- `data.item.symbol_code`
- `data.item.status`
- `data.symbol.symbol_code`

Optional:

- `data.already_exists`
- `data.restored`

## remove-watchlist-item

Endpoint:

```text
POST /functions/v1/remove-watchlist-item
```

Request:

```json
{
  "watchlist_item_id": "uuid"
}
```

Response `data`:

```json
{
  "item": {
    "id": "uuid",
    "watchlist_id": "uuid",
    "symbol_code": "TLKM",
    "status": "archived",
    "updated_at": "timestamp"
  }
}
```

Required for Flutter:

- `data.item.id`
- `data.item.status`

Optional:

- `data.item.symbol_code`
- `data.item.updated_at`

## create-alert

Endpoint:

```text
POST /functions/v1/create-alert
```

Request:

```json
{
  "symbol_code": "BBCA",
  "name": "BBCA risk warning watch",
  "alert_type": "risk_warning",
  "cooldown_minutes": 60,
  "conditions": [
    {
      "metric": "risk_score",
      "operator": "lt",
      "value_numeric": 55
    }
  ]
}
```

Response `data`:

```json
{
  "alert": {},
  "conditions": []
}
```

Required for Flutter:

- `data.alert.id`
- `data.alert.name`
- `data.alert.alert_type`
- `data.alert.status`
- `data.conditions`

Optional:

- `data.alert.symbol_code`
- `data.alert.cooldown_minutes`

## run-screener

Endpoint:

```text
POST /functions/v1/run-screener
```

Request:

```json
{
  "preset_id": "uuid",
  "preset_name": "Technical Breakout Candidate",
  "limit": 10
}
```

Response `data`:

```json
{
  "run_id": "uuid",
  "preset": {},
  "filters": [],
  "results": [
    {
      "symbol": {},
      "scores": {
        "technical_score": 0,
        "harmony_score": 0,
        "fundamental_score": 0,
        "risk_score": 0,
        "liquidity_score": 0,
        "final_score": 0
      },
      "candidate_label": "watchlist_candidate",
      "matched_filters": []
    }
  ]
}
```

Required for Flutter:

- `data.run_id`
- `data.preset`
- `data.results`
- `results[].symbol.symbol_code`
- `results[].scores.final_score`
- `results[].candidate_label`

Optional:

- `data.filters`
- `results[].matched_filters`
- `results[].scores.technical_score`
- `results[].scores.harmony_score`
- `results[].scores.fundamental_score`
- `results[].scores.risk_score`
- `results[].scores.liquidity_score`
- `meta.scoring_mode`

## evaluate-watchlist

Endpoint:

```text
POST /functions/v1/evaluate-watchlist
```

Request:

```json
{
  "watchlist_id": "uuid"
}
```

Response `data`:

```json
{
  "watchlist": {},
  "evaluated_count": 0,
  "rule_version": "p0_dummy_scoring_v1",
  "results": [
    {
      "watchlist_item_id": "uuid",
      "symbol_code": "BBCA",
      "candidate_label": "watchlist_candidate",
      "technical_setup": "technical setup candidate",
      "risk_warning": [],
      "invalidation_level": 0,
      "scores": {
        "technical_score": 0,
        "harmony_score": 0,
        "fundamental_score": 0,
        "risk_score": 0,
        "liquidity_score": 0,
        "final_score": 0
      }
    }
  ]
}
```

Required for Flutter:

- `data.evaluated_count`
- `data.rule_version`
- `data.results`
- `results[].watchlist_item_id`
- `results[].symbol_code`
- `results[].candidate_label`
- `results[].scores.final_score`

Optional:

- `results[].technical_setup`
- `results[].risk_warning`
- `results[].invalidation_level`
- individual score fields
- `meta.scoring_mode`

## Flutter Handling Rules

- If `ok = false`, show error state based on `error.code`.
- If list field is empty, show empty state.
- Never infer transaction action from `candidate_label`.
- Treat `watchlist_candidate` as "layak dianalisis", not as an execution instruction.
- Display `risk warning` and `invalidation level` when present.
