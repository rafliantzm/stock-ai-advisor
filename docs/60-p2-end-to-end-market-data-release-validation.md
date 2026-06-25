# P2 End-to-End Market Data Release Validation

Dokumen ini merangkum validasi rilis P2 market data untuk `stock-ai-advisor`. Fokus validasi adalah alur edukatif dan watchlist-oriented dari Supabase Edge Functions ke Flutter UI, tanpa instruksi transaksi dan tanpa mengekspos secret provider.

## Validation Scope

Area yang divalidasi:

- Supabase Edge Functions P2:
  - `sync-market-candidates`
  - `get-market-context`
- Provider chain:
  - `alpha_vantage -> twelve_data -> eodhd -> sample_provider`
- Flutter UI:
  - Main Watchlist
  - AI Stock Screener
  - P2 Market Data Sync
  - Market Context
  - Chart Lab
  - Stock Detail
  - Smart Alert
- Security review:
  - Flutter tetap memakai Supabase anon key dan JWT user.
  - Provider secret hanya berada di Supabase Edge Function environment.
  - Response tetap memakai wording edukatif, watchlist candidate, dan risk-aware.

## Commands Run

Flutter validation:

```bash
cd apps/mobile
dart format lib test
flutter analyze
flutter test
```

Supabase Edge Function deployment:

```bash
supabase functions deploy sync-market-candidates
supabase functions deploy get-market-context
```

Smoke test:

```text
sync-market-candidates smoke test
```

Expected status:

- `dart format lib test`: pass
- `flutter analyze`: pass
- `flutter test`: pass
- `sync-market-candidates` deploy: pass
- `get-market-context` deploy: pass
- `sync-market-candidates` smoke test: pass

## Expected Backend Result

Expected `sync-market-candidates` final release state:

```text
ok = true
provider_mode = live
data_quality = delayed
live_symbol_count = 5
fallback_symbol_count = 0
selected_provider = mixed_live_providers
fallback_provider_used = false
tertiary_provider_name = eodhd
sample_provider = skipped
```

Expected symbol coverage:

- `ASII`: provider-backed data available
- `BBCA`: provider-backed data available
- `BBRI`: provider-backed data available
- `TLKM`: provider-backed data available
- `UNVR`: provider-backed data available

Expected diagnostics:

- `provider_attempts` preserves order: `alpha_vantage -> twelve_data -> eodhd -> sample_provider`
- `symbol_diagnostics` shows selected provider symbols when available.
- `fallback_symbols` is empty.
- `risk_warning` may include delayed-data education.
- `disclaimer` remains educational and risk-aware.

## Expected UI Result

Main Watchlist:

- Watchlist remains stable with latest score display.
- Risk warning display remains compact and severity-aware.
- Internal labels are humanized, for example `Rule scoring awal` and `Data belum cukup`.

AI Stock Screener and P2 Market Data Sync:

- Shows `Delayed provider-backed data`.
- Shows `Multi-provider`.
- Shows `No symbol fallback`.
- Shows tertiary provider context such as `eodhd` only as safe diagnostics.

Market Context:

- Aligned with delayed provider-backed data.
- Does not show stale/sample fallback messaging when `fallback_symbol_count = 0`.
- UTC timestamps are displayed in readable WIB-friendly format, for example `25 Jun 2026, 19:58 WIB`.
- Disclaimer stays educational and watchlist/risk-aware.

Chart Lab:

- Shows provider-backed delayed preview.
- Clearly states interactive OHLCV chart is still being integrated.
- Does not contradict the active provider-backed delayed state.

Stock Detail:

- Shows provider-backed delayed context.
- Keeps analysis deterministic and score-based.
- Does not claim unrestricted real-time analysis.

Smart Alert:

- Form remains usable.
- Alert wording remains based on `risk warning`, `technical setup`, score, and `invalidation level`.

## Security Checks

The release must not expose:

- API key
- JWT token
- service role key
- Authorization header
- full provider URL with secret
- raw provider response

Expected safe behavior:

- Flutter never stores provider key or service role key.
- Provider credentials are read only by Supabase Edge Functions.
- API responses include only safe provider metadata such as provider name, provider mode, provider status, data quality, fallback count, and sanitized diagnostics.
- Documentation and screenshots must not include private tokens, raw headers, or raw provider responses.

## Release Decision

P2 end-to-end market data release is ready when:

- Backend smoke test returns `ok = true`.
- `provider_mode = live`.
- `data_quality = delayed`.
- `live_symbol_count = 5`.
- `fallback_symbol_count = 0`.
- Flutter validation commands pass.
- Visual QA confirms all listed screens show delayed provider-backed state consistently.
- Security checks confirm no secret exposure.

## Known Limitations

- Provider data may be delayed depending on provider plan and exchange support.
- Chart Lab interactive OHLCV chart is still being integrated.
- AI/RAG explanation layer is not active in P2.
- Output remains educational context for watchlist candidate analysis, not an instruction to transact.

## Next Step

- Capture final UI screenshots for release notes.
- Run one final `sync-market-candidates` smoke test after deploying both Edge Functions.
- Proceed to P2 release tagging after backend smoke test and visual QA are confirmed.
