# 34. Flutter API Integration Plan

Dokumen ini merencanakan integrasi Flutter ke Edge Functions P0. Belum ada implementasi Flutter UI pada tahap ini.

## Scope

Integrasi P0:

- Supabase Auth token handling.
- Edge Function client wrapper.
- Watchlist flow.
- Smart alert creation.
- Screener run.
- Watchlist evaluation.

Out of scope:

- AI/RAG explanation.
- Market data real-time.
- Production Rule Engine.
- Fitur transaksi saham real.

## Token Handling

Flutter menggunakan Supabase Auth session user.

Flow:

1. User login lewat Supabase Auth.
2. Flutter mengambil `session.accessToken`.
3. Flutter memanggil Edge Functions dengan header:

```text
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Larangan:

- Jangan simpan service role key di Flutter.
- Jangan expose `SUPABASE_SERVICE_ROLE_KEY` atau secret key ke client.
- Jangan panggil database sensitif langsung dari Flutter jika logic harus lewat Edge Functions.

## API Client Plan

Buat wrapper internal, misalnya:

```text
lib/core/api/edge_function_client.dart
```

Tanggung jawab:

- Menambahkan Authorization header.
- Encode request JSON.
- Decode response JSON.
- Memetakan `ok = false` menjadi app error.
- Menangani expired session dengan redirect login/session refresh.

Model response awal:

- `ApiSuccess<T>`
- `ApiFailure`
- `ApiErrorCode`

## Screen Priority

Prioritas screen P0:

1. `WatchlistScreen`
2. `StockDetailScreen`
3. `SmartAlertScreen`
4. `ScreenerScreen`
5. `ScreenerResultScreen`

Screen berikutnya setelah P0 stabil:

- `ChartLabScreen`
- `FundamentalScorecardScreen`
- `MarketCalendarScreen`
- `InsightFeedScreen`
- `PortfolioSimulationScreen`

## Screen to Endpoint Mapping

| Screen | Endpoint | Purpose |
| --- | --- | --- |
| `WatchlistScreen` | `get-watchlist` | Load watchlist, active items, latest score. |
| `WatchlistScreen` | `add-watchlist-item` | Add symbol to watchlist. |
| `WatchlistScreen` | `remove-watchlist-item` | Archive item from watchlist. |
| `WatchlistScreen` | `evaluate-watchlist` | Refresh dummy score/latest score. |
| `StockDetailScreen` | `get-watchlist` | Read item context and latest score if opened from watchlist. |
| `SmartAlertScreen` | `create-alert` | Create smart alert conditions. |
| `ScreenerScreen` | `run-screener` | Run selected preset. |
| `ScreenerResultScreen` | `run-screener` | Display result from run response. |
| `ScreenerResultScreen` | `add-watchlist-item` | Add candidate result to watchlist. |

## UI States

Every screen should support:

### Loading

Use when request is in progress.

Examples:

- loading watchlist
- evaluating watchlist
- running screener
- creating smart alert

### Empty

Use when request succeeds but list is empty.

Examples:

- no watchlist items
- no screener result
- no latest score yet

### Error

Map error codes:

- `unauthorized`: session expired or user must login.
- `validation_error`: show form validation message.
- `not_found`: show resource not found state.
- `database_error`: show generic backend error and allow retry.
- `method_not_allowed`: developer/config issue.

### Success

Render `data` and optional `meta`.

Do not treat `watchlist_candidate` as transaction instruction. Render it as "layak dianalisis" or candidate status.

## Data Models Needed

Initial model groups:

- `ApiResponse<T>`
- `ApiError`
- `Watchlist`
- `WatchlistItem`
- `WatchlistScore`
- `SymbolSummary`
- `SmartAlert`
- `AlertCondition`
- `ScreenerPreset`
- `ScreenerResult`
- `DummyScoreBreakdown`

## Safe UI Wording

Use:

- layak dianalisis
- watchlist candidate
- technical setup
- smart alert
- risk warning
- invalidation level

Avoid:

- transaction execution wording
- guaranteed outcome wording
- urgent execution wording

## Integration Order

1. Build API response models.
2. Build Edge Function client wrapper.
3. Integrate `get-watchlist`.
4. Integrate `evaluate-watchlist`.
5. Integrate `add-watchlist-item`.
6. Integrate `remove-watchlist-item`.
7. Integrate `create-alert`.
8. Integrate `run-screener`.
9. Add UI state handling.
10. Add manual QA checklist.

## Manual QA Checklist

- User without session cannot call endpoints.
- Logged-in user can load own watchlist.
- Watchlist empty state renders.
- `BBCA` appears with latest score after evaluation.
- Archived item disappears from active watchlist.
- Smart alert creation shows success state.
- Screener result renders candidates with score.
- Error messages do not expose service role key or backend secrets.

## Next Step

After this plan is accepted:

1. Create Flutter app skeleton if not already created.
2. Add Supabase Auth setup.
3. Implement API client wrapper.
4. Build `WatchlistScreen` first.
5. Keep scoring dummy until Rule Engine backend is ready.
