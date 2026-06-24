# 22. Feature API Design

Semua endpoint dirancang sebagai Supabase Edge Functions. Flutter hanya memanggil endpoint, menampilkan hasil, dan menangani state UI.

## API Principles

- Auth wajib untuk endpoint user-specific.
- Service role key hanya berada di Edge Functions.
- Request harus divalidasi.
- Response harus memakai wording aman.
- Setiap scoring menyimpan `rule_version`.
- AI explanation harus menerima hasil Rule Engine sebagai input, bukan menentukan label bebas.
- RAG buku hanya boleh dipakai sebagai konteks teori untuk explanation.

## get-watchlist

Purpose: mengambil watchlist, item, score terbaru, risk warning, dan invalidation level.

Request:

```json
{ "watchlist_id": "uuid" }
```

Response:

```json
{
  "watchlist": {},
  "items": [
    {
      "symbol": "BBCA",
      "candidate_label": "watchlist_candidate",
      "overall_score": 78,
      "risk_warning": [],
      "invalidation_level": 9000
    }
  ]
}
```

## add-watchlist-item

Purpose: menambahkan simbol ke watchlist dan optional menjalankan scoring awal.

Request:

```json
{ "watchlist_id": "uuid", "symbol": "BBCA", "added_reason": "manual" }
```

Backend:

- Validasi ownership watchlist.
- Validasi symbol.
- Insert item.
- Trigger score initial jika data tersedia.

## remove-watchlist-item

Purpose: menghapus item dari watchlist user.

Request:

```json
{ "watchlist_item_id": "uuid" }
```

Backend:

- Validasi ownership.
- Soft delete lebih aman untuk audit, atau hard delete jika belum perlu audit.

## evaluate-watchlist

Purpose: mengevaluasi ulang semua item watchlist.

Request:

```json
{ "watchlist_id": "uuid", "force_refresh": false }
```

Response:

```json
{
  "evaluated_count": 12,
  "rule_version": "2026.06.mvp",
  "changed_items": 3
}
```

## create-alert

Purpose: membuat smart alert.

Request:

```json
{
  "symbol": "BBCA",
  "name": "Near support with volume",
  "alert_type": "technical_setup",
  "conditions": [
    { "metric": "distance_to_support_pct", "operator": "lte", "value_numeric": 2 },
    { "metric": "volume_ratio", "operator": "gte", "value_numeric": 1.5 }
  ]
}
```

## evaluate-alerts

Purpose: mengevaluasi alert aktif. Dipanggil scheduled function, bukan langsung dari Flutter untuk semua user.

Request:

```json
{ "scope": "scheduled", "limit": 500 }
```

Response:

```json
{ "evaluated": 500, "triggered": 18, "failed": 0 }
```

## run-screener

Purpose: menjalankan screener preset atau filter custom.

Request:

```json
{
  "preset_id": "uuid",
  "filters": [],
  "limit": 50
}
```

Response:

```json
{
  "run_id": "uuid",
  "results": [
    {
      "symbol": "BBCA",
      "score": 81,
      "candidate_label": "watchlist_candidate",
      "matched_filters": []
    }
  ]
}
```

## get-stock-chart-analysis

Purpose: mengembalikan chart analysis backend.

Request:

```json
{ "symbol": "BBCA", "timeframe": "1D", "window": 120 }
```

Response:

```json
{
  "symbol": "BBCA",
  "analysis_id": "uuid",
  "rule_version": "2026.06.mvp",
  "technical_setup": "range_breakout_watch",
  "support_levels": [],
  "resistance_levels": [],
  "volume_price_summary": {},
  "risk_warning": [],
  "invalidation_level": 9000,
  "explanation": "Ringkasan berbasis rule engine."
}
```

Persistence:

- Menulis hasil ke `chart_analysis_runs`.
- Tidak menyimpan API key atau raw provider secret.

## get-fundamental-scorecard

Purpose: menampilkan score fundamental.

Request:

```json
{ "symbol": "BBCA", "period": "latest" }
```

Response:

```json
{
  "symbol": "BBCA",
  "overall_score": 84,
  "scorecard": {
    "valuation": 70,
    "profitability": 90,
    "growth": 78,
    "leverage": 88
  },
  "risk_flags": [],
  "explanation": "Penjelasan score, bukan rekomendasi transaksi."
}
```

## get-market-calendar

Purpose: mengambil market events dan corporate actions.

Request:

```json
{ "from": "2026-06-01", "to": "2026-06-30", "symbols": ["BBCA"] }
```

Response:

```json
{
  "events": [],
  "corporate_actions": [],
  "event_alerts": []
}
```

## get-ai-insight-feed

Purpose: mengambil feed personal dari event internal dan explanation aman.

Request:

```json
{ "limit": 30, "cursor": null }
```

Response:

```json
{
  "items": [
    {
      "type": "score_change",
      "title": "Watchlist score berubah",
      "summary": "Satu saham menjadi watchlist candidate.",
      "priority": "medium"
    }
  ],
  "next_cursor": null
}
```

Persistence:

- Membaca/menulis `accumulation_distribution_insights` sebagai cache audit.
- Menandai hasil sebagai proxy bila hanya OHLCV tersedia.

## run-portfolio-simulation

Purpose: menjalankan simulasi portofolio virtual.

Request:

```json
{
  "simulation_id": "uuid",
  "assumptions": { "fee_pct": 0.15, "slippage_pct": 0.1 }
}
```

Response:

```json
{
  "risk_summary": {},
  "allocation": [],
  "scenario_results": [],
  "warnings": ["Simulasi bukan jaminan hasil masa depan."]
}
```

## get-accumulation-distribution-insight

Purpose: menghitung proxy volume-price yang aman.

Request:

```json
{ "symbol": "BBCA", "timeframe": "1D", "window": 60 }
```

Response:

```json
{
  "signal_label": "accumulation_pressure",
  "confidence_score": 68,
  "metrics": {
    "obv_trend": "up",
    "close_location_score": 0.72,
    "volume_ratio": 1.8
  },
  "limitations": "Proxy berbasis OHLCV, bukan broker summary."
}
```

## Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Input tidak valid.",
    "details": {}
  }
}
```
